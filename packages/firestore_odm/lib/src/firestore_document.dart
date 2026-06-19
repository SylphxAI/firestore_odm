import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/interfaces/deletable.dart';
import 'package:firestore_odm/src/interfaces/existable.dart';
import 'package:firestore_odm/src/interfaces/gettable.dart';
import 'package:firestore_odm/src/interfaces/modifiable.dart';
import 'package:firestore_odm/src/interfaces/patchable.dart';
import 'package:firestore_odm/src/interfaces/streamable.dart';
import 'package:firestore_odm/src/interfaces/updatable.dart';
import 'package:firestore_odm/src/schema.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'services/update_operations_service.dart';
import 'filter_builder.dart';

/// A wrapper around Firestore DocumentReference with type safety and caching
/// Uses Interface + Composition architecture with services handling operations
class FirestoreDocument<
  S extends FirestoreSchema,
  T,
  Path extends Record,
  P extends PatchBuilder<T, Map<String, dynamic>?>
>
    implements
        Gettable<T?>,
        Streamable<T?>,
        Existable,
        Modifiable<T>,
        Patchable<T>,
        Deletable,
        Updatable<T> {
  /// The collection this document belongs to (nullable for fromRef constructor)
  final Map<String, dynamic> Function(T) _toJson;
  final T Function(Map<String, dynamic>) _fromJson;

  final String documentIdField;

  /// The document ID
  final DocumentReference<Map<String, dynamic>> ref;

  /// The patch builder for this document
  final P _patchBuilder;

  /// Creates a new FirestoreDocument instance from a collection and document ID
  const FirestoreDocument({
    required this.ref,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(Map<String, dynamic>) fromJson,
    required this.documentIdField,
    required P patchBuilder,
  }) : _toJson = toJson,
       _fromJson = fromJson,
       _patchBuilder = patchBuilder;

  /// Stream of document snapshots
  @override
  Stream<T?> get stream =>
      DocumentHandler.stream<T>(ref, _fromJson, documentIdField);

  /// Checks if the document exists
  @override
  Future<bool> exists() => DocumentHandler.exists(ref);

  /// Gets the document data
  @override
  Future<T?> get() => DocumentHandler.get(ref, _fromJson, documentIdField);

  /// Sets the document data
  @override
  Future<void> update(T state) =>
      DocumentHandler.update(ref, state, _toJson, documentIdField);

  /// Modify a document using diff-based updates.
  ///
  /// This method performs a read operation followed by an update operation.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// **Important Notes:**
  /// - **Performance**: This method has an additional read operation, making it slower than [patch]
  /// - **Concurrency**: Firestore uses last-write-wins semantics. This read-modify-write
  ///   operation is NOT transactional and may be subject to race conditions
  /// - **Transactions**: For transactional updates, use transactions instead
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  ///
  /// **Example:**
  /// ```dart
  /// // With atomic operations (default)
  /// await userDoc.modify((user) => user.copyWith(
  ///   age: user.age + 1,              // Auto-detects -> FieldValue.increment(1)
  ///   tags: [...user.tags, 'new'],    // Auto-detects -> FieldValue.arrayUnion(['new'])
  /// ));
  ///
  /// // Without atomic operations
  /// await userDoc.modify((user) => user.copyWith(
  ///   name: 'Updated Name',
  /// ), atomic: false);
  /// ```
  @override
  Future<void> modify(T Function(T docData) modifier, {bool atomic = true}) =>
      DocumentHandler.modify(
        ref,
        modifier,
        _toJson,
        _fromJson,
        documentIdField,
        atomic: atomic,
      );

  /// Delete this document
  @override
  Future<void> delete() => DocumentHandler.delete(ref);

  @override
  Future<void> patch(List<UpdateOperation> Function(P updateBuilder) patches) {
    final operations = patches(_patchBuilder);
    return DocumentHandler.patch(ref, operations);
  }
}
