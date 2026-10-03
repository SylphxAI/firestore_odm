/// Typed transactions: all reads execute as they are awaited; all
/// writes are deferred and flushed at the end of the callback so Firestore's
/// read-before-write rule always holds. Reads are cached per transaction
/// attempt.
library;

import 'package:cloud_firestore/cloud_firestore.dart'
    as firestore
    show CollectionReference, DocumentReference, Transaction;

import 'backend/cloud_firestore_backend.dart';
import 'backend/odm_backend.dart';
import 'exceptions.dart';
import 'patch.dart';
import 'schema.dart';
import 'types.dart';
import 'utils.dart';

/// A transaction context. Constructed by [FirestoreODM.runTransaction]; typed
/// handles come from `collection.inTransaction(context)`.
class TransactionContext<S extends FirestoreSchema> {
  TransactionContext(this.odmTransaction, this.backend);

  /// The backend transaction.
  final OdmTransaction odmTransaction;

  /// The backend this transaction runs on.
  final OdmBackend backend;

  /// The underlying `cloud_firestore` transaction (escape hatch).
  firestore.Transaction get transaction =>
      odmTransaction.native as firestore.Transaction;

  final Map<String, OdmDocumentSnapshot> _documentCache = {};
  final List<void Function()> _deferredWrites = [];

  OdmDocumentSnapshot? _cached(OdmDocument ref) => _documentCache[ref.path];

  void _cache(OdmDocumentSnapshot snapshot) {
    _documentCache[snapshot.path] = snapshot;
  }

  void _defer(void Function() write) => _deferredWrites.add(write);

  /// Executes all deferred writes (called once, at the end of the callback).
  void flush() {
    for (final write in _deferredWrites) {
      write();
    }
    _deferredWrites.clear();
  }
}

/// Typed transactional writes for one collection.
class TransactionCollection<
  S extends FirestoreSchema,
  T,
  P extends PatchBuilder<T>
> {
  TransactionCollection({
    required TransactionContext<S> context,
    required this.ref,
    required JsonSerializer<T> toJson,
    required JsonDeserializer<T> fromJson,
    required this.documentIdField,
    required P Function() patchBuilderFactory,
  }) : _context = context,
       _toJson = toJson,
       _fromJson = fromJson,
       _patchBuilderFactory = patchBuilderFactory;

  final TransactionContext<S> _context;
  final firestore.CollectionReference<Map<String, dynamic>> ref;
  late final OdmCollection _col = CloudFirestoreBackend(
    ref.firestore,
  ).wrapCollection(ref);
  final JsonSerializer<T> _toJson;
  final JsonDeserializer<T> _fromJson;
  final String? documentIdField;
  final P Function() _patchBuilderFactory;

  TransactionDocument<S, T, P> call(String id) => doc(id);

  TransactionDocument<S, T, P> doc(String id) => TransactionDocument<S, T, P>(
    context: _context,
    ref: ref.doc(id),
    toJson: _toJson,
    fromJson: _fromJson,
    documentIdField: documentIdField,
    patchBuilderFactory: _patchBuilderFactory,
  );

  /// Defers a create with a generated ID and returns that ID.
  String create(T value) {
    final docRef = _col.doc();
    _context._defer(
      () => _context.odmTransaction.set(
        docRef,
        toFirestoreData(_toJson, value, documentIdField: documentIdField),
      ),
    );
    return docRef.id;
  }

  /// Defers a full replace. When [id] is null the document ID is read from
  /// the model's document ID field.
  void set(T value, {String? id}) {
    if (id != null) {
      validateDocumentId(id);
      _context._defer(
        () => _context.odmTransaction.set(
          _col.doc(id),
          toFirestoreData(_toJson, value, documentIdField: documentIdField),
        ),
      );
    } else {
      final result = _serializeWithId(value);
      _context._defer(
        () => _context.odmTransaction.set(
          _col.doc(result.documentId!),
          result.data,
        ),
      );
    }
  }

  /// Defers typed patch operations on the document at [id].
  void patch(String id, List<UpdateOperation> Function(P builder) patches) {
    validateDocumentId(id);
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations, _context.backend.fieldValues);
    if (updateMap.isEmpty) return;
    _context._defer(
      () => _context.odmTransaction.update(_col.doc(id), updateMap),
    );
  }

  /// Defers a delete of the document at [id].
  void delete(String id) {
    validateDocumentId(id);
    _context._defer(() => _context.odmTransaction.delete(_col.doc(id)));
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

/// Typed transactional access to one document.
class TransactionDocument<
  S extends FirestoreSchema,
  T,
  P extends PatchBuilder<T>
> {
  TransactionDocument({
    required TransactionContext<S> context,
    required this.ref,
    required JsonSerializer<T> toJson,
    required JsonDeserializer<T> fromJson,
    required this.documentIdField,
    required P Function() patchBuilderFactory,
  }) : _context = context,
       _toJson = toJson,
       _fromJson = fromJson,
       _patchBuilderFactory = patchBuilderFactory;

  final TransactionContext<S> _context;
  final firestore.DocumentReference<Map<String, dynamic>> ref;
  late final OdmDocument _doc = CloudFirestoreBackend(
    ref.firestore,
  ).wrapDocument(ref);
  final JsonSerializer<T> _toJson;
  final JsonDeserializer<T> _fromJson;
  final String? documentIdField;
  final P Function() _patchBuilderFactory;

  /// Reads the document (cached for the rest of this transaction attempt).
  Future<T?> get() async {
    final cached = _context._cached(_doc);
    final snapshot = cached ?? await _context.odmTransaction.get(_doc);
    if (cached == null) _context._cache(snapshot);
    if (!snapshot.exists) return null;
    return processDocumentSnapshot(snapshot, _fromJson, documentIdField);
  }

  /// Defers a full replace.
  void set(T value) {
    _context._defer(
      () => _context.odmTransaction.set(
        _doc,
        toFirestoreData(_toJson, value, documentIdField: documentIdField),
      ),
    );
  }

  /// Defers typed patch operations.
  void patch(List<UpdateOperation> Function(P builder) patches) {
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations, _context.backend.fieldValues);
    if (updateMap.isEmpty) return;
    _context._defer(() => _context.odmTransaction.update(_doc, updateMap));
  }

  /// Defers a delete.
  void delete() => _context._defer(() => _context.odmTransaction.delete(_doc));
}
