import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/firestore_odm.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/insertable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/interfaces/updatable.dart';
import 'package:firestore_odm/src/interfaces/upsertable.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'package:firestore_odm/src/services/update_helpers.dart';
import 'package:firestore_odm/src/utils.dart';

/// Base class for batch operations
abstract class BatchOperation {
  final dynamic fieldPath;

  const BatchOperation({required this.fieldPath});
}

/// Insert operation
class BatchInsertOperation extends BatchOperation {
  final dynamic value;

  const BatchInsertOperation({required super.fieldPath, required this.value});
}

/// Update operation
class BatchUpdateOperation extends BatchOperation {
  final dynamic value;

  const BatchUpdateOperation({required super.fieldPath, required this.value});
}

/// Delete operation
class BatchDeleteOperation extends BatchOperation {
  const BatchDeleteOperation({required super.fieldPath});
}

/// Context for managing batch operations
class BatchContext<S extends FirestoreSchema> {
  final firestore.FirebaseFirestore _firestore;
  final firestore.WriteBatch _batch;

  BatchContext(this._firestore) : _batch = _firestore.batch();

  /// Access to the Firestore instance
  firestore.FirebaseFirestore get firestoreInstance => _firestore;

  /// Commits the batch
  Future<void> commit() async {
    await _batch.commit();
  }
}

/// it is a convenience function to create a batch document
BatchCollection<S, C, Path, P>
getBatchCollection<S extends FirestoreSchema, C, Path extends Record, P extends PatchBuilder<C, Map<String, dynamic>?>>({
  required BatchDocument<S, dynamic, Record, dynamic> parent,
  required String name,
  required Map<String, dynamic> Function(C) toJson,
  required C Function(Map<String, dynamic>) fromJson,
  required String documentIdField,
  required P patchBuilder,
}) => BatchCollection(
  collection: parent._ref.collection(name),
  toJson: toJson,
  fromJson: fromJson,
  context: parent._context,
  documentIdField: documentIdField,
  patchBuilder: patchBuilder,
);

/// Batch document for handling document-level batch operations
class BatchDocument<S extends FirestoreSchema, T, Path extends Record, P extends PatchBuilder<T, Map<String, dynamic>?>>
    implements Deletable, Patchable<T> {
  final BatchContext<S> _context;
  final firestore.DocumentReference<Map<String, dynamic>?> _ref;
  final P _patchBuilder;

  const BatchDocument({
    required BatchContext<S> context,
    required firestore.DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required P patchBuilder,
  }) : _context = context,
       _ref = ref,
       _patchBuilder = patchBuilder;

  @override
  void delete() {
    _context._batch.delete(_ref);
  }

  @override
  void patch(
    List<UpdateOperation> Function(P patchBuilder) patchBuilder,
  ) {
    final operations = patchBuilder(_patchBuilder);
    final updateMap = operationsToMap(operations);

    if (updateMap.isEmpty) {
      return; // No updates to apply
    }

    _context._batch.update(_ref, processKeysTo(updateMap));
  }
}

/// Batch collection for handling collection-level batch operations
class BatchCollection<S extends FirestoreSchema, T, Path extends Record, P extends PatchBuilder<T, Map<String, dynamic>?>>
    implements
        Insertable<T>,
        Updatable<T>,
        Upsertable<T> {
  final BatchContext<S> _context;
  final firestore.CollectionReference<Map<String, dynamic>> _collection;
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;
  final String _documentIdField;
  final P _patchBuilder;

  const BatchCollection({
    required firestore.CollectionReference<Map<String, dynamic>> collection,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required BatchContext<S> context,
    required String documentIdField,
    required P patchBuilder,
  }) : _collection = collection,
       _toJson = toJson,
       _fromJson = fromJson,
       _context = context,
       _documentIdField = documentIdField,
       _patchBuilder = patchBuilder;

  /// Gets a document reference for batch operations
  BatchDocument<S, T, Path, P> call(String id) => doc(id);

  BatchDocument<S, T, Path, P> doc(String id) => BatchDocument(
    context: _context,
    ref: _collection.doc(id),
    toJson: _toJson,
    fromJson: _fromJson,
    patchBuilder: _patchBuilder,
  );

  @override
  void insert(T value) {
    final (data, documentId) = processObject(
      _toJson,
      value,
      documentIdField: _documentIdField,
    );

    // If ID is the auto-generated constant, let Firestore generate a unique ID
    if (documentId == kAutoGeneratedIdValue) {
      final docRef = _collection.doc();
      _context._batch.set(docRef, data);
    } else if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$_documentIdField\' must not be empty. Use FirestoreODM.autoGeneratedId for auto-generated IDs.',
      );
    } else {
      final docRef = _collection.doc(documentId);
      _context._batch.set(docRef, data);
    }
  }

  @override
  void update(T value) {
    final (data, documentId) = processObject(
      _toJson,
      value,
      documentIdField: _documentIdField,
    );

    // Auto-generated IDs don't make sense for update operations
    if (documentId == kAutoGeneratedIdValue) {
      throw ArgumentError(
        'Auto-generated IDs cannot be used with update operations. '
        'Update requires a specific document ID to identify the document to update. '
        'Use insert() for auto-generated IDs or provide a specific ID for update.',
      );
    }

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$_documentIdField\' must not be empty for batch update operation.',
      );
    }

    final docRef = _collection.doc(documentId);
    _context._batch.set(docRef, data);
  }

  @override
  void upsert(T value) {
    final (data, documentId) = processObject(
      _toJson,
      value,
      documentIdField: _documentIdField,
    );

    // Auto-generated IDs don't make sense for upsert operations
    if (documentId == kAutoGeneratedIdValue) {
      throw ArgumentError(
        'Auto-generated IDs cannot be used with upsert operations. '
        'Upsert requires a specific document ID to check for existing documents. '
        'Use insert() for auto-generated IDs or provide a specific ID for upsert.',
      );
    }

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$_documentIdField\' must not be empty for batch upsert operation.',
      );
    }

    final docRef = _collection.doc(documentId);
    _context._batch.set(docRef, data, firestore.SetOptions(merge: true));
  }
}
