import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:firestore_odm_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the example runs and writes what it says', () async {
    final db = FirestoreODM(appSchema, firestore: FakeFirebaseFirestore());
    await run(db);

    final kim = await db.users('kim').get();
    expect(kim?.age, 32);
    expect(kim?.tags, ['admin']);
    expect(kim?.lastLogin, isNotNull);
    expect(await db.users.count(), 2);
  });
}
