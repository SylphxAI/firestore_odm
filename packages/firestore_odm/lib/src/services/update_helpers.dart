import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firestore_odm/firestore_odm.dart';

/// Recursively replace special timestamps with FieldValue.serverTimestamp()
Map<K, dynamic> replaceServerTimestamps<K>(Map<K, dynamic> data) {
  return data.map(
    (key, value) => MapEntry(key, switch (value) {
      String() when value == FirestoreODM.serverTimestamp.toIso8601String() =>
        firestore.FieldValue.serverTimestamp(),
      Map<String, dynamic> map => replaceServerTimestamps(map),
      Map<FieldPath, dynamic> map => replaceServerTimestamps(map),
      List list => list.map((item) {
        return switch (item) {
          String()
              when item == FirestoreODM.serverTimestamp.toIso8601String() =>
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

Map<String, dynamic> processKeysTo(Map<PathFieldPath, dynamic> data) {
  return data.map((key, value) {
    return MapEntry(key.toFirestore(), switch (value) {
      Map<PathFieldPath, dynamic> map => processKeysTo(map),
      List list =>
        list
            .map(
              (item) => switch (item) {
                Map<PathFieldPath, dynamic> map => processKeysTo(map),
                _ => item,
              },
            )
            .toList(),
      _ => value,
    });
  });
}
