import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/filter_builder.dart';
import 'package:firestore_odm/src/firestore_odm.dart';
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/services/patch_operations.dart';
import 'package:firestore_odm/src/services/update_helpers.dart';
import 'package:firestore_odm/src/utils.dart';

/// Exception thrown when a Firestore document is not found.
///
/// This exception is typically thrown during update operations when
/// attempting to modify a document that doesn't exist in the collection.
class FirestoreDocumentNotFoundException implements Exception {
  /// The ID of the document that was not found
  final String documentId;

  /// Creates a new exception for a missing document.
  ///
  /// [documentId] - The ID of the document that could not be found
  FirestoreDocumentNotFoundException(this.documentId);

  @override
  String toString() =>
      'FirestoreDocumentNotFoundException: Document with ID "$documentId" not found';
}

/// Compute the difference between old and new data for efficient updates
Map<String, dynamic> computeDiff(
  Map<String, dynamic> oldData,
  Map<String, dynamic> newData,
) {
  final result = <String, dynamic>{};

  // Find removed fields
  for (final key in oldData.keys) {
    if (!newData.containsKey(key)) {
      result[key] = firestore.FieldValue.delete();
    }
  }

  // Find added or changed fields
  for (final entry in newData.entries) {
    final key = entry.key;
    final newValue = entry.value;

    if (!oldData.containsKey(key) || oldData[key] != newValue) {
      result[key] = newValue;
    }
  }

  return result;
}

/// Analyzes changes and converts them to atomic operations where possible
Map<String, dynamic> computeDiffWithAtomicOperations(
  Map<String, dynamic> oldData,
  Map<String, dynamic> newData,
) {
  final result = <String, dynamic>{};

  // Find removed fields
  for (final key in oldData.keys) {
    if (!newData.containsKey(key)) {
      result[key] = firestore.FieldValue.delete();
    }
  }

  // Find added or changed fields with atomic operation detection
  for (final entry in newData.entries) {
    final key = entry.key;
    final newValue = entry.value;
    final oldValue = oldData[key];

    if (!oldData.containsKey(key)) {
      // New field
      result[key] = newValue;
    } else if (oldValue != newValue) {
      // Changed field - try to detect atomic operations
      final atomicOp = _detectAtomicOperation(oldValue, newValue);
      if (atomicOp != null) {
        result[key] = atomicOp;
      } else if (oldValue is Map && newValue is Map) {
        // Handle nested objects - recursively detect atomic operations
        if (newValue.isEmpty && oldValue.isNotEmpty) {
          // Empty map means we want to clear all nested fields
          result[key] = newValue; // Set to empty map
        } else {
          // Try to detect atomic operations in nested fields
          final nestedAtomicOps = _detectNestedAtomicOperations(
            oldValue as Map<String, dynamic>,
            newValue as Map<String, dynamic>,
            key,
          );

          if (nestedAtomicOps.isNotEmpty) {
            // Use atomic operations for individual nested fields
            result.addAll(nestedAtomicOps);
          } else {
            // Fall back to complete object replacement
            result[key] = newValue;
          }
        }
      } else {
        result[key] = newValue;
      }
    }
  }

  return result;
}

/// Detects if a change can be represented as an atomic operation
dynamic _detectAtomicOperation(dynamic oldValue, dynamic newValue) {
  // Numeric increment detection
  if (oldValue is num && newValue is num) {
    final diff = newValue - oldValue;
    if (diff != 0) {
      return firestore.FieldValue.increment(diff);
    }
  }

  // Array operations detection
  if (oldValue is List && newValue is List) {
    final oldSet = Set.from(oldValue);
    final newSet = Set.from(newValue);

    final added = newSet.difference(oldSet).toList();
    final removed = oldSet.difference(newSet).toList();

    // If only additions, use arrayUnion
    if (removed.isEmpty && added.isNotEmpty) {
      return firestore.FieldValue.arrayUnion(added);
    }

    // If only removals, use arrayRemove
    if (added.isEmpty && removed.isNotEmpty) {
      return firestore.FieldValue.arrayRemove(removed);
    }

    // For mixed operations or when trying to add duplicates, fall back to direct assignment
    // Note: arrayUnion naturally handles duplicates by not adding them again
  }

  // No atomic operation detected
  return null;
}

/// Detects atomic operations in nested fields and returns a map of field paths to atomic operations
Map<String, dynamic> _detectNestedAtomicOperations(
  Map<String, dynamic> oldValue,
  Map<String, dynamic> newValue,
  String parentKey,
) {
  final result = <String, dynamic>{};

  // Find fields that exist in both old and new values
  for (final entry in newValue.entries) {
    final fieldKey = entry.key;
    final newFieldValue = entry.value;
    final oldFieldValue = oldValue[fieldKey];
    final fullFieldPath = '$parentKey.$fieldKey';

    if (oldValue.containsKey(fieldKey) && oldFieldValue != newFieldValue) {
      // Try to detect atomic operation for this nested field
      final atomicOp = _detectAtomicOperation(oldFieldValue, newFieldValue);
      if (atomicOp != null) {
        result[fullFieldPath] = atomicOp;
      } else if (oldFieldValue is Map && newFieldValue is Map) {
        // Recursively check deeper nested objects
        final deeperOps = _detectNestedAtomicOperations(
          oldFieldValue as Map<String, dynamic>,
          newFieldValue as Map<String, dynamic>,
          fullFieldPath,
        );
        result.addAll(deeperOps);
      } else {
        // Non-atomic operation (like string update) - include it too!
        result[fullFieldPath] = newFieldValue;
      }
    } else if (!oldValue.containsKey(fieldKey)) {
      // New field in nested object
      result[fullFieldPath] = newFieldValue;
    }
  }

  // Handle removed fields
  for (final key in oldValue.keys) {
    if (!newValue.containsKey(key)) {
      final fullFieldPath = '$parentKey.$key';
      result[fullFieldPath] = firestore.FieldValue.delete();
    }
  }

  return result;
}

class DocumentHandler {
  static Future<bool> exists<T>(
    firestore.DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snapshot = await ref.get();
    return snapshot.exists;
  }

  static Stream<T?> stream<T>(
    firestore.DocumentReference<Map<String, dynamic>> ref,
    JsonDeserializer<T> fromJson,
    String documentIdField,
  ) {
    return ref.snapshots().map(
      (snapshot) => snapshot.exists
          ? processDocumentSnapshot(snapshot, fromJson, documentIdField)
          : null,
    );
  }

  static Future<T?> get<T>(
    firestore.DocumentReference<Map<String, dynamic>> ref,
    JsonDeserializer<T> deserializer,
    String documentIdField,
  ) async {
    final snapshot = await ref.get();
    if (!snapshot.exists) return null;
    return fromFirestoreData(
      deserializer,
      snapshot.data()!,
      documentIdField,
      snapshot.id,
    );
  }

  static Future<void> delete(
    firestore.DocumentReference<Map<String, dynamic>> ref,
  ) async {
    await ref.delete();
  }

  static Future<void> update<T>(
    firestore.DocumentReference<Map<String, dynamic>> ref,
    T data,
    JsonSerializer<T> serializer,
    String? documentIdField,
  ) async {
    final dataMap = toFirestoreData(
      serializer,
      data,
      documentIdField: documentIdField,
    );

    await ref.set(dataMap);
  }

  static Future<void> patch<T>(
    firestore.DocumentReference<Map<String, dynamic>> ref,
    List<UpdateOperation> operations,
  ) async {
    final updateMap = operationsToMap(operations);
    if (updateMap.isEmpty) {
      return; // No updates to apply
    }
    final processedMap = processKeysTo(updateMap);
    await ref.update(processedMap);
  }

  static Map<String, dynamic> processPatch<T>(
    firestore.DocumentSnapshot<Map<String, dynamic>> snapshot,
    T Function(T) modifier,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson,
    String documentIdField,
    Map<String, dynamic> Function(
      Map<String, dynamic> oldData,
      Map<String, dynamic> newData,
    )
    computeDiff,
  ) {
    if (!snapshot.exists) {
      throw FirestoreDocumentNotFoundException(snapshot.id);
    }

    final currentData = fromFirestoreData(
      fromJson,
      snapshot.data()!,
      documentIdField,
      snapshot.id,
    );

    final newData = modifier(currentData);
    final oldDataMap = toJson(currentData);
    final newDataMap = toJson(newData);
    final updateData = computeDiff(oldDataMap, newDataMap);

    if (updateData.isNotEmpty) {
      return replaceServerTimestamps(updateData);
    }
    return {};
  }

  /// Modify a document using diff-based updates.
  ///
  /// This method performs a read operation followed by an update operation.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// Note: Firestore uses last-write-wins semantics. This read-modify-write
  /// operation is NOT transactional and may be subject to race conditions.
  /// For transactional updates, use transactions.
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  static Future<void> modify<T>(
    firestore.DocumentReference<Map<String, dynamic>> ref,
    T Function(T) modifier,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson,
    String documentIdField, {
    bool atomic = true,
  }) async {
    final currentData = await ref.get();
    final patch = processPatch(
      currentData,
      modifier,
      toJson,
      fromJson,
      documentIdField,
      atomic ? computeDiffWithAtomicOperations : computeDiff,
    );
    if (patch.isNotEmpty) {
      await ref.update(patch);
    }
  }
}

abstract class CollectionHandler {
  static Future<List<T>> get<T>(
    firestore.CollectionReference<Map<String, dynamic>> ref,
    JsonDeserializer<T> fromJson,
    String documentIdField,
  ) {
    return ref.get().then(
      (snapshot) =>
          processQuerySnapshot<T>(snapshot, fromJson, documentIdField),
    );
  }

  static Future<void> insert<T>(
    firestore.CollectionReference<Map<String, dynamic>> ref,
    T value,
    JsonSerializer<T> toJson,
    String documentIdField,
  ) async {
    // First extract the document ID without validation
    final (data, documentId) = processObject(
      toJson,
      value,
      documentIdField: documentIdField,
    );

    // If ID is the auto-generated constant, let Firestore generate a unique ID
    if (documentId == kAutoGeneratedIdValue) {
      await ref.add(data);
      return;
    }

    // Validate that document ID is not empty for explicit IDs
    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$documentIdField\' must not be empty. Use FirestoreODM.autoGeneratedId for auto-generated IDs.',
      );
    }

    // Check if document already exists
    final docRef = ref.doc(documentId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      throw StateError(
        'Document with ID \'$documentId\' already exists. Use upsert() to update existing documents.',
      );
    }

    await docRef.set(data);
  }

  static Future<void> update<T>(
    firestore.CollectionReference<Map<String, dynamic>> ref,
    T value,
    JsonSerializer<T> toJson,
    String documentIdField,
  ) async {
    final (data, documentId) = processObject(
      toJson,
      value,
      documentIdField: documentIdField,
    );

    // Auto-generated IDs don't make sense for update operations
    // because update needs a specific ID to identify which document to update
    if (documentId == kAutoGeneratedIdValue) {
      throw ArgumentError(
        'Auto-generated IDs cannot be used with update operations. '
        'Update requires a specific document ID to identify the document to update. '
        'Use insert() for auto-generated IDs or provide a specific ID for update.',
      );
    }

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$documentIdField\' must not be empty for update operation.',
      );
    }

    // Check if document exists
    final docRef = ref.doc(documentId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw StateError('Document with ID \'$documentId\' does not exist');
    }

    await docRef.set(data);
  }

  static Future<void> upsert<T>(
    firestore.CollectionReference<Map<String, dynamic>> ref,
    T value,
    JsonSerializer<T> toJson,
    String documentIdField,
  ) async {
    final (data, documentId) = processObject(
      toJson,
      value,
      documentIdField: documentIdField,
    );

    // Auto-generated IDs don't make sense for upsert operations
    // because upsert needs a specific ID to check if document exists
    if (documentId == kAutoGeneratedIdValue) {
      throw ArgumentError(
        'Auto-generated IDs cannot be used with upsert operations. '
        'Upsert requires a specific document ID to check for existing documents. '
        'Use insert() for auto-generated IDs or provide a specific ID for upsert.',
      );
    }

    if (documentId.isEmpty) {
      throw ArgumentError(
        'Document ID field \'$documentIdField\' must not be empty for upsert operation.',
      );
    }

    // Use set with merge option to upsert
    await ref.doc(documentId).set(data, firestore.SetOptions(merge: true));
  }
}

abstract class QueryLimitHandler {
  static firestore.Query<R> applyLimit<R>(
    firestore.Query<R> query,
    int? limit,
  ) {
    if (limit != null && limit > 0) {
      return query.limit(limit);
    }
    return query;
  }

  static firestore.Query<R> applyLimitToLast<R>(
    firestore.Query<R> query,
    int? limit,
  ) {
    if (limit != null && limit > 0) {
      return query.limitToLast(limit);
    }
    return query;
  }
}

abstract class QueryFilterHandler {
  /// Applies a filter to the given Firestore query
  static firestore.Query<R> applyFilter<R>(
    firestore.Query<R> query,
    FilterOperation filter,
  ) {
    return query.where(filter.toFilter());
  }

  static FilterOperation buildFilter<T, F extends FilterBuilderRoot>({
    required F builderRoot,
    required FilterOperation Function(F builder) filterBuilder,
  }) {
    return filterBuilder(builderRoot);
  }
}

abstract class QueryHandler {
  static Future<List<T>> get<T>(
    firestore.Query<Map<String, dynamic>> query,
    JsonDeserializer<T> fromJson,
    String documentIdField,
  ) {
    return query.get().then(
      (snapshot) =>
          processQuerySnapshot<T>(snapshot, fromJson, documentIdField),
    );
  }

  static Stream<List<T>> stream<T>(
    firestore.Query<Map<String, dynamic>> query,
    JsonDeserializer<T> fromJson,
    String documentIdField,
  ) {
    return query.snapshots().map(
      (snapshot) => processQuerySnapshot(snapshot, fromJson, documentIdField),
    );
  }

  /// Modify multiple documents using diff-based updates.
  ///
  /// This method performs a read operation followed by batch update operations.
  /// Performance is slightly worse than [patch] due to the additional read,
  /// but convenient when you need to read the current state before writing.
  ///
  /// Note: Firestore uses last-write-wins semantics. This read-modify-write
  /// operation is NOT transactional and may be subject to race conditions.
  /// For transactional updates, use transactions.
  ///
  /// [atomic] - When true (default), automatically detects and uses atomic
  /// operations like FieldValue.increment() and FieldValue.arrayUnion() where possible.
  /// When false, performs simple field updates without atomic operations.
  static Future<void> modify<T>(
    firestore.Query<Map<String, dynamic>> query,
    String documentIdField,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson,
    T Function(T) modifier, {
    bool atomic = true,
  }) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();

    for (final docSnapshot in snapshot.docs) {
      final patch = DocumentHandler.processPatch(
        docSnapshot,
        modifier,
        toJson,
        fromJson,
        documentIdField,
        atomic ? computeDiffWithAtomicOperations : computeDiff,
      );
      if (patch.isNotEmpty) {
        batch.update(docSnapshot.reference, patch);
      }
    }
    await batch.commit();
  }

  static Future<void> patch<T>(
    firestore.Query<Map<String, dynamic>> query,
    List<UpdateOperation> operations,
  ) async {
    final updateMap = operationsToMap(operations);

    if (updateMap.isEmpty) {
      return; // No updates to apply
    }

    final batch = query.firestore.batch();
    final snapshot = await query.get();
    for (final docSnapshot in snapshot.docs) {
      batch.update(docSnapshot.reference, processKeysTo(updateMap));
    }
    await batch.commit();
  }

  static Future<void> delete(
    firestore.Query<Map<String, dynamic>> query,
  ) async {
    final snapshot = await query.get();
    final batch = query.firestore.batch();

    for (final docSnapshot in snapshot.docs) {
      batch.delete(docSnapshot.reference);
    }

    await batch.commit();
  }
}
