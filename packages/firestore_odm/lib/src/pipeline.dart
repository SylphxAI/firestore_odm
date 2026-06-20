import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'field_selector.dart';
import 'utils.dart' show defaultValue;

// Re-export only the stage/result *types*. Note we do NOT re-export `Field` —
// the whole point is that callers use the generated `$.field` selector, never
// string field paths.
export 'package:cloud_firestore/cloud_firestore.dart'
    show
        Pipeline,
        PipelineSnapshot,
        PipelineResult,
        BooleanExpression,
        Ordering,
        ExecuteOptions;

// ---------------------------------------------------------------------------
// Dual-phase context for shape-changing stages (select / aggregate).
//
// Mirrors the classic aggregate subsystem: a *capture* pass records the
// native expressions (under deterministic aliases) to build the stage, and a
// *result* pass replays the same record-builder against each result row to
// reassemble a typed Dart record. Each projected/aggregated leaf is keyed by a
// deterministic alias derived from its field path + operation.
// ---------------------------------------------------------------------------

/// Context handed to a pipeline selector when building a `select` / `aggregate`
/// stage. Implementations either capture the native pieces or resolve values
/// from a result row.
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
    return defaultValue<R>();
  }

  @override
  R project<R>(String alias, firestore.Field Function() field) {
    projections.add(field().alias(alias));
    return defaultValue<R>();
  }
}

class _RowContext implements PipelineContext {
  final Map<String, dynamic> row;
  _RowContext(this.row);

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

/// Base class for generated per-model pipeline selectors. Mirrors
/// `FilterBuilderNode` / `OrderByFieldNode`: each node carries its [FieldPath];
/// nested objects are nested selectors. The optional [$ctx] is present only when
/// the selector is used inside a `select` / `aggregate` builder.
class PipelineFieldNode extends Node {
  final PipelineContext? $ctx;
  const PipelineFieldNode({super.field, PipelineContext? context})
    : $ctx = context;

  /// Count of all rows, for `aggregate(($) => (n: $.count()))`.
  int count() => $ctx!.aggregate<int>('count_all', () => firestore.CountAll());
}

/// A type-safe leaf for a scalar field. Produces native pipeline
/// expressions/orderings/aggregates **from the field's path** — never a string.
///
/// Ergonomics mirror the classic ODM API:
/// ```dart
/// $.age(isGreaterThanOrEqualTo: 18)   // where   -> BooleanExpression
/// $.age.descending()                  // sort    -> Ordering
/// $.age.sum()                         // aggregate (inside aggregate(...))
/// $.name.value                        // project  (inside select(...))
/// ```
class PipelineField<T> extends PipelineFieldNode {
  const PipelineField({super.field, super.context, Object? Function(T)? toJson})
    : _toJson = toJson;

  final Object? Function(T)? _toJson;

  firestore.Field get expression => firestore.Field(path.path);

  String get _alias => path.path;

  Object? _json(T value) => _toJson != null ? _toJson(value) : value;

  /// `where` predicate (exactly one comparison), mirroring the classic filter.
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

  /// Ascending / descending sort on this field.
  firestore.Ordering ascending() => expression.ascending();
  firestore.Ordering descending() => expression.descending();

  /// Project this field's value, for use inside `select(...)`.
  T get value => $ctx!.project<T>(_alias, () => expression);

  /// Aggregates, for use inside `aggregate(...)`.
  T sum() => $ctx!.aggregate<T>('sum_$_alias', () => expression.sum());
  double average() =>
      $ctx!.aggregate<double>('avg_$_alias', () => expression.average());
  T minimum() => $ctx!.aggregate<T>('min_$_alias', () => expression.minimum());
  T maximum() => $ctx!.aggregate<T>('max_$_alias', () => expression.maximum());
  int countField() =>
      $ctx!.aggregate<int>('count_$_alias', () => expression.count());
}

const Object _sentinel = Object();

/// A type-safe wrapper over a Firestore [firestore.Pipeline] that keeps the
/// model element type `T` and exposes the generated selector `S` so stages are
/// built with `$.field`, never string paths.
///
/// **Experimental** — Pipelines are a Firestore **Enterprise edition** feature:
/// one-shot `execute()` (no realtime/offline), unsupported by the emulator or
/// `fake_cloud_firestore`. The `select` / `aggregate` projections are
/// **compile-time type-checked but their runtime behaviour is unverified**
/// pending an Enterprise test database. See
/// `docs/adr/0001-firestore-pipelines.md`.
class TypedPipeline<T, S extends PipelineFieldNode> {
  final firestore.Pipeline _pipeline;
  final T Function(Map<String, dynamic>) _fromJson;
  final String _documentIdField;

  /// Builds the generated selector, optionally bound to a [PipelineContext]
  /// (used by `select`/`aggregate`).
  final S Function(PipelineContext? context) _selector;

  const TypedPipeline(
    this._pipeline,
    this._fromJson,
    this._documentIdField,
    this._selector,
  );

  TypedPipeline<T, S> _next(firestore.Pipeline p) =>
      TypedPipeline(p, _fromJson, _documentIdField, _selector);

  // --- row-type-preserving stages -----------------------------------------

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

  /// Executes the pipeline (Enterprise edition; one-shot) and maps each result
  /// row through the model's `fromJson`, injecting the document id when present.
  Future<List<T>> execute({firestore.ExecuteOptions? options}) async {
    final snapshot = await _pipeline.execute(options: options);
    return [for (final row in snapshot.result) _fromJson(_withId(row))];
  }

  Map<String, dynamic> _withId(firestore.PipelineResult row) {
    final data = Map<String, dynamic>.from(row.data() ?? const {});
    final id = row.document?.id;
    if (id != null && !data.containsKey(_documentIdField)) {
      data[_documentIdField] = id;
    }
    return data;
  }

  // --- shape-changing stages (typed records) ------------------------------

  /// Project each row into a typed record, e.g.
  /// `select(($) => (name: $.name.value, years: $.age.value))`.
  ProjectedPipeline<R> select<R>(R Function(S selector) build) {
    final capture = _CaptureContext();
    build(_selector(capture)); // capture phase
    final p = _applySelect(_pipeline, capture.projections);
    return ProjectedPipeline<R>._(
      p,
      (row) => build(_selector(_RowContext(row))),
    );
  }

  /// Aggregate the (filtered) pipeline into a single typed record, e.g.
  /// `aggregate(($) => (count: $.count(), avgAge: $.age.average()))`.
  Future<R> aggregate<R>(R Function(S selector) build) async {
    final capture = _CaptureContext();
    build(_selector(capture)); // capture phase
    final p = _applyAggregate(_pipeline, capture.aggregates);
    final snapshot = await p.execute();
    final row = snapshot.result.isNotEmpty
        ? (snapshot.result.first.data() ?? const {})
        : const <String, dynamic>{};
    return build(_selector(_RowContext(Map<String, dynamic>.from(row))));
  }
}

/// The result of a `select` projection: execute it to get typed records.
class ProjectedPipeline<R> {
  final firestore.Pipeline _pipeline;
  final R Function(Map<String, dynamic> row) _build;
  const ProjectedPipeline._(this._pipeline, this._build);

  Future<List<R>> execute({firestore.ExecuteOptions? options}) async {
    final snapshot = await _pipeline.execute(options: options);
    return [
      for (final row in snapshot.result)
        _build(Map<String, dynamic>.from(row.data() ?? const {})),
    ];
  }
}

// cloud_firestore's `aggregate`/`select` take positional (not list) arguments;
// fan a captured list out to the positional API (supports up to 10 — extend if
// needed).
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
