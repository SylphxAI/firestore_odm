import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/src/services/update_helpers.dart';
import 'package:firestore_odm/src/types.dart';

/// Represents a single update operation
sealed class UpdateOperation {
  final PathFieldPath field;

  const UpdateOperation(this.field);

  @override
  String toString() => 'UpdateOperation(${field.path})';
}

class SetOperation<T> extends UpdateOperation {
  final T value;

  SetOperation(super.field, this.value);

  @override
  String toString() => 'SetOperation($field, $value)';
}

class IncrementOperation<T extends num> extends UpdateOperation {
  final T value;

  IncrementOperation(super.field, this.value);

  @override
  String toString() => 'IncrementOperation($field, $value)';
}

class ArrayAddAllOperation<T> extends UpdateOperation {
  final List<T> values;

  ArrayAddAllOperation(super.field, this.values);

  @override
  String toString() => 'ArrayAddAllOperation($field, $values)';
}

class ArrayRemoveAllOperation<T> extends UpdateOperation {
  final List<T> values;

  ArrayRemoveAllOperation(super.field, this.values);

  @override
  String toString() => 'ArrayRemoveAllOperation($field, $values)';
}

class DeleteOperation extends UpdateOperation {
  DeleteOperation(super.field);

  @override
  String toString() => 'DeleteOperation($field)';
}

class ServerTimestampOperation extends UpdateOperation {
  ServerTimestampOperation(super.field);

  @override
  String toString() => 'ServerTimestampOperation($field)';
}

class ObjectMergeOperation extends UpdateOperation {
  final Map<String, dynamic> data;

  ObjectMergeOperation(super.field, this.data);

  @override
  String toString() => 'ObjectMergeOperation($field, $data)';
}

class MapPutAllOperation<V> extends UpdateOperation {
  final Map<String, V> entries;

  MapPutAllOperation(super.field, this.entries);

  @override
  String toString() => 'MapPutAllOperation($field, $entries)';
}

class MapRemoveAllOperation<K> extends UpdateOperation {
  final List<K> keys;

  MapRemoveAllOperation(super.field, this.keys);

  @override
  String toString() => 'MapRemoveAllOperation($field, $keys)';
}

class MapClearOperation extends UpdateOperation {
  MapClearOperation(super.field);

  @override
  String toString() => 'MapClearOperation($field)';
}

class MapSetOperation<K, V> extends UpdateOperation {
  final Map<K, V> entries;

  MapSetOperation(super.field, this.entries);

  @override
  String toString() => 'MapSetOperation($field, $entries)';
}

/// Convert operations to Firestore update map
Map<PathFieldPath, dynamic> operationsToMap(List<UpdateOperation> operations) {
  final Map<PathFieldPath, dynamic> updateMap = {};
  final Map<PathFieldPath, List<dynamic>> arrayAdds = {};
  final Map<PathFieldPath, List<dynamic>> arrayRemoves = {};
  final Map<PathFieldPath, num> increments = {};

  // Track which fields have set operations to handle precedence
  final Set<PathFieldPath> fieldsWithSetOperations = {};

  // First pass: identify fields with set operations
  for (final operation in operations) {
    if (operation is SetOperation) {
      print(
        'Processing operation: value: ${operation.value}, type: ${operation.value.runtimeType}',
      );
    }
    if (operation is SetOperation ||
        operation is DeleteOperation ||
        operation is ServerTimestampOperation ||
        operation is ObjectMergeOperation) {
      fieldsWithSetOperations.add(operation.field);
    }
  }

  // Second pass: process operations with precedence rules
  for (final operation in operations) {
    switch (operation) {
      case SetOperation setOp:
        updateMap[setOp.field] = setOp.value;
        break;
      case IncrementOperation incOp:
        // Increment operations are not affected by set operations
        increments[incOp.field] = (increments[incOp.field] ?? 0) + incOp.value;
        break;
      case ArrayAddAllOperation arrayAddAllOp:
        // Skip array operations if field has set operation
        if (!fieldsWithSetOperations.contains(arrayAddAllOp.field)) {
          arrayAdds
              .putIfAbsent(arrayAddAllOp.field, () => [])
              .addAll(arrayAddAllOp.values);
        }
        break;
      case ArrayRemoveAllOperation arrayRemoveAllOp:
        // Skip array operations if field has set operation
        if (!fieldsWithSetOperations.contains(arrayRemoveAllOp.field)) {
          arrayRemoves
              .putIfAbsent(arrayRemoveAllOp.field, () => [])
              .addAll(arrayRemoveAllOp.values);
        }
        break;
      case DeleteOperation deleteOp:
        updateMap[deleteOp.field] = FieldValue.delete();
        break;
      case ServerTimestampOperation serverTimestampOp:
        updateMap[serverTimestampOp.field] = FieldValue.serverTimestamp();
        break;
      case ObjectMergeOperation operation:
        // For object merge, flatten the nested fields
        final data = operation.data;
        for (final entry in data.entries) {
          final fieldPath = operation.field.append(entry.key);
          updateMap[fieldPath] = entry.value;
        }
        break;
      case MapPutAllOperation mapPutAllOp:
        // For map putAll, set multiple nested fields
        final data = mapPutAllOp.entries;
        for (final entry in data.entries) {
          final keyPath = mapPutAllOp.field.append(entry.key);
          updateMap[keyPath] = entry.value;
        }
        break;
      case MapRemoveAllOperation mapRemoveAllOp:
        // For map removeAll, delete multiple nested fields
        final keys = mapRemoveAllOp.keys;
        for (final key in keys) {
          final keyPath = operation.field.append(key);
          updateMap[keyPath] = FieldValue.delete();
        }
        break;
      case MapClearOperation mapClearOp:
        // For map clear, delete the entire map field
        updateMap[mapClearOp.field] = FieldValue.delete();
        // Note: Firestore does not support clearing a map field directly,
        // so we delete the field instead.

        // This is a workaround to clear the map field and preserve the structure
        updateMap[mapClearOp.field.append('_tmp')] = FieldValue.delete();
        break;

      case MapSetOperation mapSetOp:
        // for map set, delete the existing map field
        updateMap[mapSetOp.field] = FieldValue.delete();

        // For map set, set multiple nested fields
        final data = mapSetOp.entries;
        for (final entry in data.entries) {
          updateMap[mapSetOp.field.append(entry.key)] = entry.value;
        }
        break;
    }
  }

  // Handle fields with both add and remove operations
  // Note: Firestore doesn't support both arrayUnion and arrayRemove on the same field
  // in a single update, but we can combine the operations by computing the net effect
  final fieldsWithBothOps = arrayAdds.keys.toSet().intersection(
    arrayRemoves.keys.toSet(),
  );

  for (final field in fieldsWithBothOps) {
    final toAdd = arrayAdds[field]!;
    final toRemove = arrayRemoves[field]!;

    // Remove items that are both added and removed (they cancel out)
    final netAdd = toAdd.where((item) => !toRemove.contains(item)).toList();
    final netRemove = toRemove.where((item) => !toAdd.contains(item)).toList();

    // Update the maps with net operations
    if (netAdd.isNotEmpty) {
      arrayAdds[field] = netAdd;
    } else {
      arrayAdds.remove(field);
    }

    if (netRemove.isNotEmpty) {
      arrayRemoves[field] = netRemove;
    } else {
      arrayRemoves.remove(field);
    }
  }

  // After computing net operations, check if we still have conflicts
  final remainingConflicts = arrayAdds.keys.toSet().intersection(
    arrayRemoves.keys.toSet(),
  );
  if (remainingConflicts.isNotEmpty) {
    throw ArgumentError(
      'Cannot perform both arrayUnion and arrayRemove operations on the same field in a single update. Fields: $remainingConflicts',
    );
  }

  // Apply accumulated increment operations
  for (final entry in increments.entries) {
    updateMap[entry.key] = FieldValue.increment(entry.value);
  }

  // Apply accumulated array operations
  for (final entry in arrayAdds.entries) {
    updateMap[entry.key] = FieldValue.arrayUnion(entry.value);
  }
  for (final entry in arrayRemoves.entries) {
    updateMap[entry.key] = FieldValue.arrayRemove(entry.value);
  }

  final processedUpdateMap = replaceServerTimestamps(updateMap);

  print('Generated update map: $processedUpdateMap');

  return processedUpdateMap;
}
