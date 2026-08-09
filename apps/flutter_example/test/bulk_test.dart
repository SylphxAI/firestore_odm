/// Bulk query writes are chunked to Firestore's 500-write batch limit
/// (ADR-0002).
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('patchAll applies the same ops to every match', () async {
    final (_, odm) = newDb();
    for (var i = 1; i <= 5; i++) {
      await odm.users.set(sampleUser(id: 'u$i', age: 20 + i));
    }
    await odm.users
        .where(($) => $.age(isGreaterThan: 22))
        .patchAll(const []);
    // patchAll with empty ops is a no-op.
    expect((await odm.users('u3').get())?.age, 23);

    await odm.users
        .where(($) => $.age(isGreaterThan: 22))
        .patchAll([SetOperation(const FieldNode(components: ['age']), 99)]);
    expect((await odm.users('u3').get())?.age, 99);
    expect((await odm.users('u2').get())?.age, 22);
  });

  test('deleteAll removes every match', () async {
    final (_, odm) = newDb();
    for (var i = 1; i <= 5; i++) {
      await odm.users.set(sampleUser(id: 'u$i', age: 20 + i));
    }
    await odm.users.where(($) => $.age(isGreaterThan: 22)).deleteAll();
    expect(await odm.users.count(), 2);
  });

  test('chunked writes respect the 500-write limit', () async {
    final (_, odm) = newDb();
    for (var i = 0; i < 5; i++) {
      await odm.users.set(sampleUser(id: 'u$i'));
    }
    // deleteAll over all matches must not trip Firestore's 500-write batch
    // limit (the fake would throw if the ODM issued one giant batch).
    await odm.users.deleteAll();
    expect(await odm.users.count(), 0);
  });
}
