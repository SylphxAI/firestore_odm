/// The typed collection surface: create/set/patch/delete writes plus the typed
/// query surface, transactions and batches.
///
/// Write verbs map 1:1 to Firestore primitives (ADR-0002):
/// - [create]: `collection.add()` — returns the generated document ID.
/// - [set]: full document replace (`doc.set`).
/// - [patch]: partial update with typed ops (`doc.update`).
/// - [delete]: `doc.delete()`.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'aggregate.dart';
import 'batch.dart';
import 'exceptions.dart';
import 'filter_builder.dart';
import 'firestore_document.dart';
import 'orderby.dart';
import 'patch.dart';
import 'query.dart';
import 'schema.dart';
import 'transaction.dart';
import 'types.dart';
import 'utils.dart';

/// A type-safe wrapper around a Firestore collection reference.
class FirestoreCollection<
  S extends FirestoreSchema,
  T,
  P extends PatchBuilder<T>,
  F extends FilterBuilderRoot,
  OB extends OrderByBuilderRoot,
  AB extends AggregateBuilderRoot
> {
  FirestoreCollection({
    required this.ref,
    required JsonSerializer<T> toJson,
    required JsonDeserializer<T> fromJson,
    required this.documentIdField,
    required P Function() patchBuilderFactory,
    required F filterBuilder,
    required OB Function(OrderByContext context) orderByBuilderFunc,
    required AB Function(AggregateContext context) aggregateBuilderFunc,
  }) : _toJson = toJson,
       _fromJson = fromJson,
       _patchBuilderFactory = patchBuilderFactory,
       _filterBuilder = filterBuilder,
       _orderByBuilderFunc = orderByBuilderFunc,
       _aggregateBuilderFunc = aggregateBuilderFunc;

  /// The underlying Firestore collection reference (escape hatch).
  final firestore.CollectionReference<Map<String, dynamic>> ref;

  final JsonSerializer<T> _toJson;
  final JsonDeserializer<T> _fromJson;

  /// The model field that holds the document ID, or null when the model does
  /// not store its ID.
  final String? documentIdField;

  final P Function() _patchBuilderFactory;
  final F _filterBuilder;
  final OB Function(OrderByContext context) _orderByBuilderFunc;
  final AB Function(AggregateContext context) _aggregateBuilderFunc;

  /// The model deserializer (exposed for generated pipeline extensions).
  JsonDeserializer<T> get fromJson => _fromJson;

  /// A typed document handle for [id].
  FirestoreDocument<S, T, P> doc(String id) => FirestoreDocument<S, T, P>(
    ref: ref.doc(id),
    toJson: _toJson,
    fromJson: _fromJson,
    documentIdField: documentIdField,
    patchBuilderFactory: _patchBuilderFactory,
  );

  /// Creates a document with a server-generated ID and returns that ID.
  ///
  /// The document ID field of [value] is not stored.
  Future<String> create(T value) async {
    final data = toFirestoreData(_toJson, value, documentIdField: documentIdField);
    final docRef = await ref.add(data);
    return docRef.id;
  }

  /// Replaces a document. When [id] is null the document ID is read from the
  /// model's document ID field.
  Future<void> set(T value, {String? id}) async {
    if (id != null) {
      validateDocumentId(id);
      await ref.doc(id).set(
        toFirestoreData(_toJson, value, documentIdField: documentIdField),
      );
    } else {
      final result = _serializeWithId(value);
      await ref.doc(result.documentId!).set(result.data);
    }
  }

  /// Applies typed patch operations to the document at [id].
  Future<void> patch(
    String id,
    List<UpdateOperation> Function(P builder) patches,
  ) async {
    validateDocumentId(id);
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) return;
    await ref.doc(id).update(updateMap);
  }

  /// Deletes the document at [id].
  Future<void> delete(String id) async {
    validateDocumentId(id);
    await ref.doc(id).delete();
  }

  ({Map<String, dynamic> data, String? documentId}) _serializeWithId(T value) {
    final result = processObject(_toJson, value, documentIdField: documentIdField);
    final id = result.documentId;
    if (id == null || id.isEmpty) {
      throw FirestoreODMValidationException(
        'Model document ID field "${documentIdField ?? '(none)'}" must be set for set() without an explicit ID',
        code: 'invalid_document_id',
        field: documentIdField,
      );
    }
    validateDocumentId(id);
    return result;
  }

  /// All documents in this collection.
  Future<List<T>> get() => _query().get();

  /// Live stream of all documents in this collection.
  Stream<List<T>> get stream => _query().stream;

  /// Typed query with filters.
  Query<S, T, P, F, OB, AB> where(FilterOperation Function(F builder) filterFunc) =>
      _query().where(filterFunc);

  /// Typed ordered query.
  OrderedQuery<S, T, O, P, F, OB, AB> orderBy<O extends Record>(
    O Function(OB selector) orderByFunc,
  ) => _query().orderBy(orderByFunc);

  /// Limits the number of documents returned.
  Query<S, T, P, F, OB, AB> limit(int limit) => _query().limit(limit);

  /// Limits to the last [limit] documents (requires an orderBy).
  Query<S, T, P, F, OB, AB> limitToLast(int limit) => _query().limitToLast(limit);

  /// Server-side document count (one-shot).
  Future<int> count() => _query().count();

  /// Typed server-side aggregate (one-shot).
  AggregateQuery<R, AB> aggregate<R extends Record>(
    R Function(AB selector) aggregateFunc,
  ) => _query().aggregate(aggregateFunc);

  /// Bulk patch on all matching documents (chunked, ≤500 writes per batch).
  Future<void> patchAll(List<UpdateOperation> operations) =>
      _query().patchAll(operations);

  /// Bulk delete on all matching documents (chunked, ≤500 writes per batch).
  Future<void> deleteAll() => _query().deleteAll();

  Query<S, T, P, F, OB, AB> _query() => Query<S, T, P, F, OB, AB>(
    query: ref,
    toJson: _toJson,
    fromJson: _fromJson,
    documentIdField: documentIdField,
    patchBuilderFactory: _patchBuilderFactory,
    filterBuilder: _filterBuilder,
    orderByBuilderFunc: _orderByBuilderFunc,
    aggregateBuilderFunc: _aggregateBuilderFunc,
  );

  /// A typed transaction handle for this collection.
  TransactionCollection<S, T, P> inTransaction(TransactionContext<S> context) =>
      TransactionCollection<S, T, P>(
        context: context,
        ref: ref,
        toJson: _toJson,
        fromJson: _fromJson,
        documentIdField: documentIdField,
        patchBuilderFactory: _patchBuilderFactory,
      );

  /// A typed batch handle for this collection.
  BatchCollection<S, T, P> inBatch(BatchContext<S> context) =>
      BatchCollection<S, T, P>(
        context: context,
        ref: ref,
        toJson: _toJson,
        documentIdField: documentIdField,
        patchBuilderFactory: _patchBuilderFactory,
      );
}
