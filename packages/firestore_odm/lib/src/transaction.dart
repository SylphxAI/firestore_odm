/// Typed transactions (ADR-0002): all reads execute as they are awaited; all
/// writes are deferred and flushed at the end of the callback so Firestore's
/// read-before-write rule always holds. Reads are cached per transaction
/// attempt.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'exceptions.dart';
import 'patch.dart';
import 'schema.dart';
import 'types.dart';
import 'utils.dart';

/// A transaction context. Constructed by [FirestoreODM.runTransaction]; typed
/// handles come from `collection.inTransaction(context)`.
class TransactionContext<S extends FirestoreSchema> {
  TransactionContext(this.transaction);

  final firestore.Transaction transaction;

  final Map<String, firestore.DocumentSnapshot<Map<String, dynamic>>>
  _documentCache = {};
  final List<void Function()> _deferredWrites = [];

  firestore.DocumentSnapshot<Map<String, dynamic>>? _cached(
    firestore.DocumentReference<Map<String, dynamic>> ref,
  ) => _documentCache[ref.path];

  void _cache(firestore.DocumentSnapshot<Map<String, dynamic>> snapshot) {
    _documentCache[snapshot.reference.path] = snapshot;
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
    final docRef = ref.doc();
    _context._defer(
      () => _context.transaction.set(
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
        () => _context.transaction.set(
          ref.doc(id),
          toFirestoreData(_toJson, value, documentIdField: documentIdField),
        ),
      );
    } else {
      final result = _serializeWithId(value);
      _context._defer(
        () =>
            _context.transaction.set(ref.doc(result.documentId!), result.data),
      );
    }
  }

  /// Defers typed patch operations on the document at [id].
  void patch(String id, List<UpdateOperation> Function(P builder) patches) {
    validateDocumentId(id);
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) return;
    _context._defer(() => _context.transaction.update(ref.doc(id), updateMap));
  }

  /// Defers a delete of the document at [id].
  void delete(String id) {
    validateDocumentId(id);
    _context._defer(() => _context.transaction.delete(ref.doc(id)));
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
  final JsonSerializer<T> _toJson;
  final JsonDeserializer<T> _fromJson;
  final String? documentIdField;
  final P Function() _patchBuilderFactory;

  /// Reads the document (cached for the rest of this transaction attempt).
  Future<T?> get() async {
    final cached = _context._cached(ref);
    final snapshot = cached ?? await _context.transaction.get(ref);
    if (cached == null) _context._cache(snapshot);
    if (!snapshot.exists) return null;
    return processDocumentSnapshot(snapshot, _fromJson, documentIdField);
  }

  /// Defers a full replace.
  void set(T value) {
    _context._defer(
      () => _context.transaction.set(
        ref,
        toFirestoreData(_toJson, value, documentIdField: documentIdField),
      ),
    );
  }

  /// Defers typed patch operations.
  void patch(List<UpdateOperation> Function(P builder) patches) {
    final operations = patches(_patchBuilderFactory());
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) return;
    _context._defer(() => _context.transaction.update(ref, updateMap));
  }

  /// Defers a delete.
  void delete() => _context._defer(() => _context.transaction.delete(ref));
}
