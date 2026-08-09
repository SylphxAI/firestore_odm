/// **Experimental** — typed Firestore Pipelines (Enterprise edition, GA 2026).
///
/// One-shot `execute()` (no realtime/offline); unsupported by the emulator and
/// `fake_cloud_firestore`. The `select`/`aggregate` projections are
/// compile-time type-checked but their runtime behaviour is unverified pending
/// an Enterprise test database (ADR-0001). Stage building uses the generated
/// `$.field` selectors — never string paths.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'field_selector.dart';

// Re-export only the stage/result *types*; `Field` is intentionally NOT
// re-exported — callers use the generated selectors.
export 'package:cloud_firestore/cloud_firestore.dart'
    show
        Pipeline,
        PipelineSnapshot,
        PipelineResult,
        BooleanExpression,
        Ordering,
        ExecuteOptions;

/// Dual-phase context for shape-changing stages (select/aggregate): a capture
/// pass records the native expressions under deterministic aliases, a result
/// pass replays the same record builder against each result row.
abstract class PipelineContext {
  R aggregate<R>(
    String alias,
    firestore.PipelineAggregateFunction Function() fn,
  );
  R project<R>(String alias, firestore.Field Function() field);
}

class _CaptureContext implements PipelineContext {
  final List<firestore.AliasedAggregateFunction> aggregates = [];
  final List<firestore.Selectable> projections = [];

  @override
  R aggregate<R>(
    String alias,
    firestore.PipelineAggregateFunction Function() fn,
  ) {
    aggregates.add(fn().as(alias));
    return _defaultValue<R>();
  }

  @override
  R project<R>(String alias, firestore.Field Function() field) {
    projections.add(field().alias(alias));
    return _defaultValue<R>();
  }
}

class _RowContext implements PipelineContext {
  _RowContext(this.row);

  final Map<String, dynamic> row;

  R _coerce<R>(Object? value) {
    if (value is R) return value;
    if (value is num) {
      if (R == int) return value.toInt() as R;
      if (R == double) return value.toDouble() as R;
    }
    return value as R;
  }

  @override
  R aggregate<R>(
    String alias,
    firestore.PipelineAggregateFunction Function() _,
  ) => _coerce<R>(row[alias]);

  @override
  R project<R>(String alias, firestore.Field Function() _) =>
      _coerce<R>(row[alias]);
}

/// Base class for generated pipeline selectors; carries the path prefix and an
/// optional capture context (present inside `select`/`aggregate`).
class PipelineFieldNode extends FieldNode {
  const PipelineFieldNode({super.components, PipelineContext? context})
    : $ctx = context;

  final PipelineContext? $ctx;

  /// Count of all rows, for `aggregate(($) => (n: $.count()))`.
  int count() => $ctx!.aggregate<int>('count_all', () => firestore.CountAll());
}

/// A type-safe leaf for a scalar field; produces native pipeline
/// expressions/orderings/aggregates from the field path — never a string.
class PipelineField<T> extends PipelineFieldNode {
  const PipelineField({
    super.components,
    super.context,
    Object? Function(T)? toJson,
  }) : _toJson = toJson;

  final Object? Function(T)? _toJson;

  String get _path => components.join('.');

  firestore.Field get expression => firestore.Field(_path);

  String get _alias => _path;

  Object? _json(T value) => _toJson != null ? _toJson(value) : value;

  /// `where` predicate (exactly one comparison).
  firestore.BooleanExpression call({
    Object? isEqualTo = _sentinel,
    Object? isNotEqualTo = _sentinel,
    Object? isLessThan = _sentinel,
    Object? isLessThanOrEqualTo = _sentinel,
    Object? isGreaterThan = _sentinel,
    Object? isGreaterThanOrEqualTo = _sentinel,
  }) {
    if (!identical(isEqualTo, _sentinel)) {
      return expression.equalValue(_json(isEqualTo as T));
    }
    if (!identical(isNotEqualTo, _sentinel)) {
      return expression.notEqualValue(_json(isNotEqualTo as T));
    }
    if (!identical(isLessThan, _sentinel)) {
      return expression.lessThanValue(_json(isLessThan as T));
    }
    if (!identical(isLessThanOrEqualTo, _sentinel)) {
      return expression.lessThanOrEqualValue(_json(isLessThanOrEqualTo as T));
    }
    if (!identical(isGreaterThan, _sentinel)) {
      return expression.greaterThanValue(_json(isGreaterThan as T));
    }
    if (!identical(isGreaterThanOrEqualTo, _sentinel)) {
      return expression.greaterThanOrEqualValue(
        _json(isGreaterThanOrEqualTo as T),
      );
    }
    throw ArgumentError('Provide exactly one comparison to a pipeline where()');
  }

  /// Ascending/descending sort on this field.
  firestore.Ordering ascending() => expression.ascending();
  firestore.Ordering descending() => expression.descending();

  /// Project this field's value, inside `select(...)`.
  T get value => $ctx!.project<T>(_alias, () => expression);

  /// Aggregates, inside `aggregate(...)`.
  T sum() => $ctx!.aggregate<T>('sum_$_alias', () => expression.sum());
  double average() =>
      $ctx!.aggregate<double>('avg_$_alias', () => expression.average());
  T minimum() => $ctx!.aggregate<T>('min_$_alias', () => expression.minimum());
  T maximum() => $ctx!.aggregate<T>('max_$_alias', () => expression.maximum());
  int countField() =>
      $ctx!.aggregate<int>('count_$_alias', () => expression.count());
}

const Object _sentinel = Object();

/// Type-safe wrapper over a Firestore [firestore.Pipeline] preserving the
/// model element type.
class TypedPipeline<T, S extends PipelineFieldNode> {
  const TypedPipeline(
    this._pipeline,
    this._fromJson,
    this._documentIdField,
    this._selector,
  );

  final firestore.Pipeline _pipeline;
  final T Function(Map<String, dynamic>) _fromJson;
  final String? _documentIdField;
  final S Function(PipelineContext? context) _selector;

  TypedPipeline<T, S> _next(firestore.Pipeline p) =>
      TypedPipeline(p, _fromJson, _documentIdField, _selector);

  TypedPipeline<T, S> where(
    firestore.BooleanExpression Function(S selector) build,
  ) => _next(_pipeline.where(build(_selector(null))));

  TypedPipeline<T, S> sort(
    firestore.Ordering Function(S selector) build, [
    firestore.Ordering Function(S selector)? build2,
    firestore.Ordering Function(S selector)? build3,
  ]) {
    final s = _selector(null);
    final o1 = build(s);
    if (build3 != null) return _next(_pipeline.sort(o1, build2!(s), build3(s)));
    if (build2 != null) return _next(_pipeline.sort(o1, build2(s)));
    return _next(_pipeline.sort(o1));
  }

  TypedPipeline<T, S> limit(int limit) => _next(_pipeline.limit(limit));

  TypedPipeline<T, S> offset(int offset) => _next(_pipeline.offset(offset));

  /// Executes the pipeline (Enterprise, one-shot) and maps rows through the
  /// model's `fromJson`, injecting the document ID when present.
  Future<List<T>> execute({firestore.ExecuteOptions? options}) async {
    final snapshot = await _pipeline.execute(options: options);
    return [for (final row in snapshot.result) _fromJson(_withId(row))];
  }

  Map<String, dynamic> _withId(firestore.PipelineResult row) {
    final data = Map<String, dynamic>.from(row.data() ?? const {});
    final id = row.document?.id;
    if (id != null &&
        _documentIdField != null &&
        !data.containsKey(_documentIdField)) {
      data[_documentIdField] = id;
    }
    return data;
  }

  /// Projects each row into a typed record.
  ProjectedPipeline<R> select<R>(R Function(S selector) build) {
    final capture = _CaptureContext();
    build(_selector(capture));
    return ProjectedPipeline<R>._(
      _applySelect(_pipeline, capture.projections),
      (row) => build(_selector(_RowContext(row))),
    );
  }

  /// Aggregates the pipeline into a single typed record.
  Future<R> aggregate<R>(R Function(S selector) build) async {
    final capture = _CaptureContext();
    build(_selector(capture));
    final p = _applyAggregate(_pipeline, capture.aggregates);
    final snapshot = await p.execute();
    final row = snapshot.result.isNotEmpty
        ? (snapshot.result.first.data() ?? const {})
        : const <String, dynamic>{};
    return build(_selector(_RowContext(Map<String, dynamic>.from(row))));
  }
}

/// The result of a `select` projection.
class ProjectedPipeline<R> {
  const ProjectedPipeline._(this._pipeline, this._build);

  final firestore.Pipeline _pipeline;
  final R Function(Map<String, dynamic> row) _build;

  Future<List<R>> execute({firestore.ExecuteOptions? options}) async {
    final snapshot = await _pipeline.execute(options: options);
    return [
      for (final row in snapshot.result)
        _build(Map<String, dynamic>.from(row.data() ?? const {})),
    ];
  }
}

firestore.Pipeline _applyAggregate(
  firestore.Pipeline p,
  List<firestore.AliasedAggregateFunction> a,
) {
  switch (a.length) {
    case 0:
      throw ArgumentError('aggregate() needs at least one aggregate function');
    case 1:
      return p.aggregate(a[0]);
    case 2:
      return p.aggregate(a[0], a[1]);
    case 3:
      return p.aggregate(a[0], a[1], a[2]);
    case 4:
      return p.aggregate(a[0], a[1], a[2], a[3]);
    case 5:
      return p.aggregate(a[0], a[1], a[2], a[3], a[4]);
    case 6:
      return p.aggregate(a[0], a[1], a[2], a[3], a[4], a[5]);
    case 7:
      return p.aggregate(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
    case 8:
      return p.aggregate(a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]);
    default:
      throw ArgumentError('aggregate() supports up to 8 functions for now');
  }
}

firestore.Pipeline _applySelect(
  firestore.Pipeline p,
  List<firestore.Selectable> s,
) {
  switch (s.length) {
    case 0:
      throw ArgumentError('select() needs at least one field');
    case 1:
      return p.select(s[0]);
    case 2:
      return p.select(s[0], s[1]);
    case 3:
      return p.select(s[0], s[1], s[2]);
    case 4:
      return p.select(s[0], s[1], s[2], s[3]);
    case 5:
      return p.select(s[0], s[1], s[2], s[3], s[4]);
    case 6:
      return p.select(s[0], s[1], s[2], s[3], s[4], s[5]);
    case 7:
      return p.select(s[0], s[1], s[2], s[3], s[4], s[5], s[6]);
    case 8:
      return p.select(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7]);
    default:
      throw ArgumentError('select() supports up to 8 fields for now');
  }
}

T _defaultValue<T>() {
  if (null is T) return null as T;
  if (T == int) return 0 as T;
  if (T == double) return 0.0 as T;
  if (T == num) return 0 as T;
  if (T == bool) return false as T;
  if (T == String) return '' as T;
  if (T == DateTime) return DateTime.fromMillisecondsSinceEpoch(0) as T;
  if (T == Duration) return Duration.zero as T;
  final typeName = T.toString();
  if (typeName.startsWith('List<')) return <dynamic>[] as T;
  if (typeName.startsWith('Set<')) return <dynamic>{} as T;
  if (typeName.startsWith('Map<')) return <String, dynamic>{} as T;
  throw UnsupportedError('Cannot create default value for type $T');
}
