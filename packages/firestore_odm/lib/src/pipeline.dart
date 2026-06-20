import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

// Re-export the pipeline expression/stage building blocks so callers can write
// `Field('age').greaterThanValue(18)` / `Field('age').descending()` without
// importing cloud_firestore directly.
export 'package:cloud_firestore/cloud_firestore.dart'
    show
        Pipeline,
        PipelineSource,
        PipelineSnapshot,
        PipelineResult,
        Expression,
        BooleanExpression,
        Field,
        Constant,
        Ordering,
        ExecuteOptions;

/// **Experimental** — a thin, type-safe wrapper over a Firestore
/// [firestore.Pipeline] that maps result rows back to the ODM model `T`.
///
/// Firestore Pipelines are an **Enterprise edition** feature. They are
/// **one-shot only** (`execute()`, no realtime listeners or offline cache) and
/// are **not supported by the emulator or `fake_cloud_firestore`** — so this
/// surface cannot be exercised by the fake-firestore test suite and must be
/// validated against a real Enterprise database.
///
/// This is the minimal slice (`where` / `sort` / `limit` / `execute`); the full
/// type-safe, per-model stage/expression builders are designed in
/// `docs/adr/0001-firestore-pipelines.md` and tracked in
/// https://github.com/SylphxAI/firestore_odm/issues/6.
class TypedPipeline<T> {
  final firestore.Pipeline _pipeline;
  final T Function(Map<String, dynamic>) _fromJson;
  final String _documentIdField;

  const TypedPipeline(this._pipeline, this._fromJson, this._documentIdField);

  /// Adds a `where` stage. Build [expression] with `Field('path')` comparisons,
  /// e.g. `Field('age').greaterThanValue(18)`.
  TypedPipeline<T> where(firestore.BooleanExpression expression) =>
      TypedPipeline(_pipeline.where(expression), _fromJson, _documentIdField);

  /// Adds a `sort` stage. Build orderings with `Field('path').ascending()` /
  /// `.descending()`.
  TypedPipeline<T> sort(
    firestore.Ordering order, [
    firestore.Ordering? order2,
    firestore.Ordering? order3,
  ]) {
    final firestore.Pipeline next;
    if (order3 != null) {
      next = _pipeline.sort(order, order2!, order3);
    } else if (order2 != null) {
      next = _pipeline.sort(order, order2);
    } else {
      next = _pipeline.sort(order);
    }
    return TypedPipeline(next, _fromJson, _documentIdField);
  }

  /// Adds a `limit` stage.
  TypedPipeline<T> limit(int limit) =>
      TypedPipeline(_pipeline.limit(limit), _fromJson, _documentIdField);

  /// Executes the pipeline (Enterprise edition; one-shot) and maps each result
  /// row through the model's `fromJson`.
  ///
  /// Pipeline rows are not [firestore.DocumentSnapshot]s, so when a row carries
  /// a document reference its id is injected into the model's document-id field
  /// (mirroring the classic read path).
  Future<List<T>> execute({firestore.ExecuteOptions? options}) async {
    final snapshot = await _pipeline.execute(options: options);
    return [for (final row in snapshot.result) _fromJson(_withDocumentId(row))];
  }

  Map<String, dynamic> _withDocumentId(firestore.PipelineResult row) {
    final data = Map<String, dynamic>.from(row.data() ?? const {});
    final id = row.document?.id;
    if (id != null && !data.containsKey(_documentIdField)) {
      data[_documentIdField] = id;
    }
    return data;
  }
}
