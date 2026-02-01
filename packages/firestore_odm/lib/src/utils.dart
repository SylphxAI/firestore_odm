import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/src/model_converter.dart';
import 'package:firestore_odm/src/services/update_helpers.dart';
import 'package:firestore_odm/src/types.dart';

T fromFirestoreData<T>(
  JsonDeserializer<T> fromJsonFunction,
  Map<String, dynamic> json,
  String documentIdField,
  String documentId,
) {
  // Process the JSON data

  final processedData = processFirestoreData(
    json,
    documentIdField: documentIdField,
    documentId: documentId,
  );
  final result = fromJsonFunction(processedData);
  return result;
}

Map<String, dynamic> processFirestoreData(
  Map<String, dynamic> data, {
  String? documentIdField,
  String? documentId,
}) {
  final result = Map<String, dynamic>.from(data);

  // Add document ID field if specified
  if (documentIdField != null && documentId != null) {
    result[documentIdField] = documentId;
  }

  // Process all values recursively to convert Timestamps
  return _processValue(result) as Map<String, dynamic>;
}

/// Recursively processes Firestore data, converting Timestamps to ISO8601 strings.
dynamic _processValue(dynamic value) {
  if (value == null) {
    return null;
  }

  // Handle Firestore Timestamp type directly
  if (value is firestore.Timestamp) {
    return value.toDate().toIso8601String();
  }

  // Handle nested structures
  if (value is Map<String, dynamic>) {
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key: _processValue(entry.value),
    };
  }

  if (value is List) {
    return value.map(_processValue).toList();
  }

  return value;
}

Map<String, dynamic> toFirestoreData<T>(
  JsonSerializer<T> toJsonFunction,
  T data, {
  String? documentIdField,
}) {
  final mapData = toJsonFunction(data);
  return removeDocumentIdField(mapData, documentIdField);
}

(Map<String, dynamic>, String) processObject<T>(
  Map<String, dynamic> Function(T) toJson,
  T data, {
  String? documentIdField,
}) {
  // Process the data to ensure it is ready for Firestore storage
  final mapData = toJson(data);
  final documentId = extractDocumentId(mapData, documentIdField);
  final processedData = removeDocumentIdField(mapData, documentIdField);

  // Replace FirestoreODM.serverTimestamp with FieldValue.serverTimestamp()
  // This ensures server timestamps work correctly on insert (not just update)
  final timestampedData = replaceServerTimestamps(processedData);

  return (timestampedData, documentId);
}

String extractDocumentId(Map<String, dynamic> json, String? documentIdField) {
  if (documentIdField == null) return '';
  return json[documentIdField] as String? ?? '';
}

void validateDocumentId(
  String? documentId,
  String? fieldName, {
  bool isInsert = false,
}) {
  // if it is an insert operation, allow empty string for auto ID generation
  if (isInsert && documentId == null) {
    return; // Allow null for insert operation
  }

  // Validate that the document ID is not null or empty
  if (fieldName != null && (documentId == null || documentId.isEmpty)) {
    throw ArgumentError(
      'Document ID field \'$fieldName\' must not be null or empty for upsert operation',
    );
  }
}

Map<String, dynamic> removeDocumentIdField(
  Map<String, dynamic> json,
  String? documentIdField,
) {
  final result = Map<String, dynamic>.from(json);
  if (documentIdField != null) {
    result.remove(documentIdField);
  }
  return result;
}

List<T> processQuerySnapshot<T>(
  firestore.QuerySnapshot<Map<String, dynamic>> snapshot,
  JsonDeserializer<T> fromMap,
  String documentIdField,
) {
  if (snapshot.docs.isEmpty) return [];
  return snapshot.docs
      .map((doc) => processDocumentSnapshot<T>(doc, fromMap, documentIdField))
      .toList();
}

T processDocumentSnapshot<T>(
  firestore.DocumentSnapshot<Map<String, dynamic>> snapshot,
  JsonDeserializer<T> fromMap,
  String documentIdField,
) {
  if (!snapshot.exists) {
    throw StateError('Document does not exist: ${snapshot.id}');
  }
  return fromFirestoreData<T>(
    fromMap,
    snapshot.data()!,
    documentIdField,
    snapshot.id,
  );
}

T resolveJsonWithParts<T>(
  Map<String, dynamic> json,
  String id,
  FieldPath path,
) {
  switch (path) {
    case DocumentIdFieldPath():
      // Special case for document ID field
      return id as T;
    case PathFieldPath(:final components, :final path):
      if (path is DocumentIdFieldPath) {
        // Special case for document ID field
        return id as T;
      }

      dynamic current = json;

      for (final part in components) {
        if (current == null) {
          throw ArgumentError(
            'Cannot resolve path ${path} - null encountered at "$part"',
          );
        }

        // Check if it's a numeric index (array access)
        if (RegExp(r'^\d+$').hasMatch(part)) {
          final index = int.parse(part);
          if (current is List) {
            if (index >= 0 && index < current.length) {
              current = current[index];
            } else {
              throw RangeError(
                'Index $index out of bounds for array of length ${current.length} at path ${path}',
              );
            }
          } else {
            throw ArgumentError(
              'Expected List but found ${current.runtimeType} when accessing index "$part" in path ${path}',
            );
          }
        } else {
          // String key (object access)
          if (current is Map<String, dynamic>) {
            if (current.containsKey(part)) {
              current = current[part];
            } else {
              throw ArgumentError(
                'Key "$part" not found in object at path ${components.join(".")}',
              );
            }
          } else {
            throw ArgumentError(
              'Expected Map but found ${current.runtimeType} when accessing key "$part" in path ${path}',
            );
          }
        }
      }

      // Type checking and conversion
      if (current is T) {
        return current;
      } else {
        throw ArgumentError(
          'Expected type $T but found ${current.runtimeType} at path ${path}. Value: $current',
        );
      }
  }
}

/// Returns a sensible default value for the given type [T].
///
/// Supported types:
/// - Nullable types: null
/// - int, double, num: 0
/// - bool: false
/// - String: ''
/// - List, Set, Map: empty collection
/// - DateTime: epoch (1970-01-01)
/// - Duration: zero
///
/// Throws [UnsupportedError] for unsupported types.
T defaultValue<T>() {
  // Handle nullable types - null is a valid value for T?
  if (null is T) return null as T;

  // Primitive types - direct type comparison works here
  if (T == int) return 0 as T;
  if (T == double) return 0.0 as T;
  if (T == num) return 0 as T;
  if (T == bool) return false as T;
  if (T == String) return '' as T;
  if (T == DateTime) return DateTime.fromMillisecondsSinceEpoch(0) as T;
  if (T == Duration) return Duration.zero as T;

  // Generic collection types require string-based type inspection since
  // Dart doesn't support pattern matching on generic types at runtime.
  // e.g., List<int> cannot be matched with `T == List<int>` when T is generic.
  final typeName = T.toString();
  if (typeName.startsWith('List<')) return <dynamic>[] as T;
  if (typeName.startsWith('Set<')) return <dynamic>{} as T;
  if (typeName.startsWith('Map<')) return <String, dynamic>{} as T;

  throw UnsupportedError(
    'Cannot create default value for type $T. '
    'Supported types: nullable, int, double, num, bool, String, '
    'DateTime, Duration, List, Set, Map.',
  );
}
