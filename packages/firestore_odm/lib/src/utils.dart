import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm/src/model_converter.dart';
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

dynamic _processValue(dynamic value) {
  if (value == null) {
    return null;
  }

  // Try to convert any potential Timestamp first
  try {
    // Try calling toDate() on any object - if it works, it's a Timestamp
    final dateTime = (value as dynamic).toDate() as DateTime;
    return dateTime.toIso8601String();
  } catch (e) {
    // Not a Timestamp, continue with other processing
  }

  // Try string detection as fallback
  try {
    final runtimeType = value.runtimeType.toString();
    final stringValue = value.toString();
    if (runtimeType.contains('Timestamp') ||
        stringValue.contains('Timestamp')) {
      final timestamp = value as dynamic;
      final dateTime = timestamp.toDate() as DateTime;
      return dateTime.toIso8601String();
    }
  } catch (e) {
    // Continue with normal processing
  }

  if (value is Map<String, dynamic>) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      result[entry.key] = _processValue(entry.value);
    }
    return result;
  } else if (value is List) {
    return value.map((item) => _processValue(item)).toList();
  } else {
    return value;
  }
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
  final timestampedData = replaceServerTimestamps(processedData);

  // Serialize the data for Firestore storage
  return (timestampedData, documentId);
}

/// Recursively replace special timestamps with FieldValue.serverTimestamp()
Map<K, dynamic> replaceServerTimestamps<K>(Map<K, dynamic> data) {
  return data.map(
    (key, value) => MapEntry(key, switch (value) {
      String() when value == kServerTimestamp.toIso8601String() =>
        firestore.FieldValue.serverTimestamp(),
      Map<String, dynamic> map => replaceServerTimestamps(map),
      Map<FieldPath, dynamic> map => replaceServerTimestamps(map),
      List list => list.map((item) {
        return switch (item) {
          String()
              when item == kServerTimestamp.toIso8601String() =>
            firestore.FieldValue.serverTimestamp(),
          Map<String, dynamic> map => replaceServerTimestamps(map),
          Map<FieldPath, dynamic> map => replaceServerTimestamps(map),
          _ => item,
        };
      }).toList(),
      _ => value,
    }),
  );
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

T defaultValue<T>() {
  // Handle nullable types
  if (null is T) return null as T;

  // Numeric types
  if (T == int) return 0 as T;
  if (T == double) return 0.0 as T;
  if (T == num) return 0 as T;

  // Boolean type
  if (T == bool) return false as T;

  // String type
  if (T == String) return '' as T;

  // Collection types - use reflection check
  final typeString = T.toString();
  if (typeString.startsWith('List<')) return <dynamic>[] as T;
  if (typeString.startsWith('Set<')) return <dynamic>{} as T;
  if (typeString.startsWith('Map<')) return <String, dynamic>{} as T;

  // DateTime
  if (T == DateTime) return DateTime.fromMillisecondsSinceEpoch(0) as T;

  // Duration
  if (T == Duration) return Duration.zero as T;

  // Unsupported types
  throw UnsupportedError('Cannot create default value for type $T');
}
