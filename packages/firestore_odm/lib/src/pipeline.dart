import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'field_selector.dart';

// Re-export only what callers legitimately need at the type level. Note we do
// NOT re-export `Field` — the whole point is that callers never write string
// field paths; they use the generated `$.field` selector instead.
export 'package:cloud_firestore/cloud_firestore.dart'
    show
        Pipeline,
        PipelineSnapshot,
        PipelineResult,
        BooleanExpression,
        Ordering,
        ExecuteOptions;

/// Base class for generated per-model pipeline selectors (e.g.
/// `UserPipelineSelector`). Mirrors `FilterBuilderNode` / `OrderByFieldNode`:
/// each node carries its [FieldPath], and nested objects are nested selectors.
class PipelineFieldNode extends Node {
  const PipelineFieldNode({super.field});
}

/// A type-safe leaf for a scalar field in a pipeline selector.
///
/// It produces native pipeline expressions/orderings/aggregates **from the
/// field's path** — callers never spell the path as a string. The ergonomics
/// mirror the classic ODM query API:
///
/// ```dart
/// $.age(isGreaterThanOrEqualTo: 18)   // where  -> BooleanExpression
/// $.age.descending()                  // sort   -> Ordering
/// $.age.sum().as('total')             // select/aggregate
/// ```
class PipelineField<T> extends PipelineFieldNode {
  const PipelineField({super.field, Object? Function(T)? toJson})
    : _toJson = toJson;

  /// Converts a typed value to its Firestore JSON form (e.g. enum → its
  /// `@JsonValue`, DateTime → ISO string), matching how the field is stored.
  final Object? Function(T)? _toJson;

  /// The underlying native field expression for this leaf's path.
  firestore.Field get expression => firestore.Field(path.path);

  Object? _json(T value) => _toJson != null ? _toJson(value) : value;

  /// Build a `where` predicate, mirroring the classic filter API. Exactly one
  /// argument should be supplied.
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

  /// Ascending sort on this field.
  firestore.Ordering ascending() => expression.ascending();

  /// Descending sort on this field.
  firestore.Ordering descending() => expression.descending();
}

const Object _sentinel = Object();

/// A type-safe wrapper over a Firestore [firestore.Pipeline] that keeps the
/// model element type `T` and exposes the generated selector `S` for building
/// stages without string field paths.
///
/// **Experimental** — Pipelines are a Firestore **Enterprise edition** feature:
/// one-shot `execute()` (no realtime/offline), and unsupported by the emulator
/// or `fake_cloud_firestore`. Execution must be validated against a real
/// Enterprise database; see `docs/adr/0001-firestore-pipelines.md`.
class TypedPipeline<T, S extends PipelineFieldNode> {
  final firestore.Pipeline _pipeline;
  final T Function(Map<String, dynamic>) _fromJson;
  final String _documentIdField;
  final S _selector;

  const TypedPipeline(
    this._pipeline,
    this._fromJson,
    this._documentIdField,
    this._selector,
  );

  TypedPipeline<T, S> _next(firestore.Pipeline p) =>
      TypedPipeline(p, _fromJson, _documentIdField, _selector);

  /// `where` stage built from the typed selector, e.g.
  /// `pipeline.where(($) => $.age(isGreaterThanOrEqualTo: 18))`.
  TypedPipeline<T, S> where(
    firestore.BooleanExpression Function(S selector) build,
  ) => _next(_pipeline.where(build(_selector)));

  /// `sort` stage, e.g. `pipeline.sort(($) => $.age.descending())`. Up to three
  /// orderings; extend as needed.
  TypedPipeline<T, S> sort(
    firestore.Ordering Function(S selector) build, [
    firestore.Ordering Function(S selector)? build2,
    firestore.Ordering Function(S selector)? build3,
  ]) {
    final o1 = build(_selector);
    if (build3 != null) {
      return _next(_pipeline.sort(o1, build2!(_selector), build3(_selector)));
    }
    if (build2 != null) {
      return _next(_pipeline.sort(o1, build2(_selector)));
    }
    return _next(_pipeline.sort(o1));
  }

  /// `limit` stage.
  TypedPipeline<T, S> limit(int limit) => _next(_pipeline.limit(limit));

  /// `offset` stage.
  TypedPipeline<T, S> offset(int offset) => _next(_pipeline.offset(offset));

  /// Executes the pipeline (Enterprise edition; one-shot) and maps each result
  /// row through the model's `fromJson`. The document id is injected into the
  /// model's document-id field when a row carries a document reference.
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
}
