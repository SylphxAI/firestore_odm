import 'package:firestore_odm/firestore_odm.dart';

Map<String, dynamic> processKeysTo(Map<PathFieldPath, dynamic> data) {
  return data.map((key, value) {
    return MapEntry(key.toFirestore(), switch (value) {
      Map<PathFieldPath, dynamic> map => processKeysTo(map),
      List list => list.map((item) => switch (item) {
          Map<PathFieldPath, dynamic> map => processKeysTo(map),
          _ => item,
        }).toList(),
      _ => value,
    });
  });
}
