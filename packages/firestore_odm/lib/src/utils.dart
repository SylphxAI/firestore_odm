/// Shared serialization helpers used by every write/read path.
///
/// v5 semantics: DateTime is a native Timestamp, no sentinels, no implicit
/// type rewriting. These helpers only splice the document ID field in/out.
library;

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'exceptions.dart';
import 'types.dart';

/// Adds the document ID into the JSON map (if a document ID field is
/// declared) and returns the deserialized model.
T fromFirestoreData<T>(
  JsonDeserializer<T> fromJson,
  Map<String, dynamic> json,
  String? documentIdField,
  String documentId,
) {
  final processed = Map<String, dynamic>.from(json);
  if (documentIdField != null) {
    processed[documentIdField] = documentId;
  }
  return fromJson(processed);
}

/// Serializes [value] and removes the document ID field (it is not stored).
Map<String, dynamic> toFirestoreData<T>(
  JsonSerializer<T> toJson,
  T value, {
  String? documentIdField,
}) {
  final map = toJson(value);
  if (documentIdField != null) {
    map.remove(documentIdField);
  }
  return map;
}

/// Serializes [value] and returns `(data, documentId)` where the document ID
/// is read from the model (or `null` when the model declares no ID field).
({Map<String, dynamic> data, String? documentId}) processObject<T>(
  JsonSerializer<T> toJson,
  T value, {
  String? documentIdField,
}) {
  final map = toJson(value);
  final documentId = documentIdField == null
      ? null
      : map[documentIdField] as String?;
  if (documentIdField != null) {
    map.remove(documentIdField);
  }
  return (data: map, documentId: documentId);
}

/// Deserializes a query snapshot into a list of models.
List<T> processQuerySnapshot<T>(
  firestore.QuerySnapshot<Map<String, dynamic>> snapshot,
  JsonDeserializer<T> fromJson,
  String? documentIdField,
) {
  return snapshot.docs
      .map(
        (doc) =>
            fromFirestoreData(fromJson, doc.data(), documentIdField, doc.id),
      )
      .toList();
}

/// Deserializes a document snapshot; throws [FirestoreODMDocumentException]
/// when the document does not exist.
T processDocumentSnapshot<T>(
  firestore.DocumentSnapshot<Map<String, dynamic>> snapshot,
  JsonDeserializer<T> fromJson,
  String? documentIdField,
) {
  final data = snapshot.data();
  if (data == null) {
    throw FirestoreODMDocumentException(
      'Document does not exist',
      code: 'not_found',
      documentPath: snapshot.reference.path,
    );
  }
  return fromFirestoreData(fromJson, data, documentIdField, snapshot.id);
}

/// Validates a document ID against Firestore's ID rules.
///
/// Firestore document IDs must be non-empty, at most 1500 bytes, and must not
/// contain `/` or the lone `*`/`.` characters (`.` alone is illegal, and `..`
/// as a segment is illegal).
void validateDocumentId(String id) {
  if (id.isEmpty) {
    throw FirestoreODMValidationException(
      'Document ID must not be empty',
      code: 'invalid_document_id',
    );
  }
  if (id.contains('/')) {
    throw FirestoreODMValidationException(
      'Document ID must not contain "/"',
      code: 'invalid_document_id',
    );
  }
  if (id == '.' || id == '..') {
    throw FirestoreODMValidationException(
      'Document ID must not be "." or ".."',
      code: 'invalid_document_id',
    );
  }
  if (id.length * 4 > 1500) {
    throw FirestoreODMValidationException(
      'Document ID exceeds Firestore limit of 1500 bytes',
      code: 'invalid_document_id',
    );
  }
}

/// Returns a sensible dummy value for capture contexts (orderBy/aggregate
/// record builders). The value is never written to Firestore.
T defaultValue<T>() {
  if (null is T) return null as T;
  if (T == int) return 0 as T;
  if (T == double) return 0.0 as T;
  if (T == num) return 0 as T;
  if (T == bool) return false as T;
  if (T == String) return '' as T;
  if (T == DateTime) return DateTime.fromMillisecondsSinceEpoch(0) as T;
  if (T == Duration) return Duration.zero as T;
  final typeName = T.toString();
  if (typeName.startsWith('List<')) return <dynamic>[] as T;
  if (typeName.startsWith('Set<')) return <dynamic>{} as T;
  if (typeName.startsWith('Map<')) return <String, dynamic>{} as T;
  throw UnsupportedError(
    'Cannot create default value for type $T in a capture context. '
    'Supported: nullable, int, double, num, bool, String, DateTime, Duration, '
    'List, Set, Map.',
  );
}

/// Identity value converter (primitives, DateTime, Timestamp, GeoPoint, Blob,
/// DocumentReference — everything Firestore stores natively).
T identity<T>(T value) => value;

/// Converts a stored Timestamp (or DateTime, as returned by test doubles)
/// back to DateTime.
DateTime dateTimeFromJson(Object? value) =>
    value is firestore.Timestamp ? value.toDate() : value as DateTime;

/// Converts a Duration to Firestore microseconds (int).
Object? durationToJson(Duration value) => value.inMicroseconds;

/// Converts a stored microseconds int back to Duration.
Duration durationFromJson(Object? value) => Duration(microseconds: value as int);
