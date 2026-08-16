/// Typed batch writes (WriteBatch): create/set/patch/delete. Batches cannot
/// read; all queued operations commit atomically with [BatchContext.commit].
library;

import 'package:cloud_firestore/cloud_firestore.dart'
    show CollectionReference, DocumentReference, FirebaseFirestore, WriteBatch;

import 'exceptions.dart';
import 'patch.dart';
import 'schema.dart';
import 'types.dart';
import 'utils.dart';

/// A batch write context. Writes are queued and committed together.
class BatchContext<S extends FirestoreSchema> {
  /// The Firestore instance this batch writes to.
  final FirebaseFirestore firestore;

  final WriteBatch _batch;

  BatchContext(this.firestore) : _batch = firestore.batch();

  /// Commits all queued operations atomically.
  Future<void> commit() => _batch.commit();
}

/// Typed batch writes for one collection.
class BatchCollection<S extends FirestoreSchema, T, P extends PatchBuilder<T>> {
  BatchCollection({
    required BatchContext<S> context,
    required this.ref,
    required JsonSerializer<T> toJson,
    required this.documentIdField,
    required P Function() patchBuilderFactory,
  }) : _context = context,
       _toJson = toJson,
       _patchBuilderFactory = patchBuilderFactory;

  final BatchContext<S> _context;
  final CollectionReference<Map<String, dynamic>> ref;
  final JsonSerializer<T> _toJson;
  final String? documentIdField;
  final P Function() _patchBuilderFactory;

  BatchDocument<S, T, P> doc(String id) => BatchDocument<S, T, P>(
    context: _context,
    ref: ref.doc(id),
    toJson: _toJson,
    documentIdField: documentIdField,
    patchBuilderFactory: _patchBuilderFactory,
  );

  /// Queues a create with a generated ID and returns that ID.
  String create(T value) {
    final docRef = ref.doc();
    _context._batch.set(
      docRef,
      toFirestoreData(_toJson, value, documentIdField: documentIdField),
    );
    return docRef.id;
  }

  /// Queues a full replace. When [id] is null the document ID is read from
  /// the model's document ID field.
  void set(T value, {String? id}) {
    if (id != null) {
      validateDocumentId(id);
      _context._batch.set(
        ref.doc(id),
        toFirestoreData(_toJson, value, documentIdField: documentIdField),
      );
    } else {
      final result = _serializeWithId(value);
      _context._batch.set(ref.doc(result.documentId!), result.data);
    }
  }

  /// Queues typed patch operations on the document at [id].
  void patch(String id, List<UpdateOperation> Function(P builder) patches) {
    validateDocumentId(id);
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) return;
    _context._batch.update(ref.doc(id), updateMap);
  }

  /// Queues a delete of the document at [id].
  void delete(String id) {
    validateDocumentId(id);
    _context._batch.delete(ref.doc(id));
  }

  ({Map<String, dynamic> data, String? documentId}) _serializeWithId(T value) {
    final result = processObject(
      _toJson,
      value,
      documentIdField: documentIdField,
    );
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
}

/// Typed batch writes for one document.
class BatchDocument<S extends FirestoreSchema, T, P extends PatchBuilder<T>> {
  BatchDocument({
    required BatchContext<S> context,
    required this.ref,
    required JsonSerializer<T> toJson,
    required this.documentIdField,
    required P Function() patchBuilderFactory,
  }) : _context = context,
       _toJson = toJson,
       _patchBuilderFactory = patchBuilderFactory;

  final BatchContext<S> _context;
  final DocumentReference<Map<String, dynamic>> ref;
  final JsonSerializer<T> _toJson;
  final String? documentIdField;
  final P Function() _patchBuilderFactory;

  /// Queues a full replace.
  void set(T value) {
    _context._batch.set(
      ref,
      toFirestoreData(_toJson, value, documentIdField: documentIdField),
    );
  }

  /// Queues typed patch operations.
  void patch(List<UpdateOperation> Function(P builder) patches) {
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) return;
    _context._batch.update(ref, updateMap);
  }

  /// Queues a delete.
  void delete() => _context._batch.delete(ref);
}
