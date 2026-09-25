/// `get()` forwards `GetOptions` (cache/server source) like cloud_firestore.
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  const server = GetOptions(source: Source.server);

  test('document, collection and query get accept GetOptions', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'u1', age: 20));
    await odm.users.set(sampleUser(id: 'u2', age: 40));

    expect((await odm.users('u1').get(server))?.id, 'u1');
    expect(await odm.users('missing').get(server), isNull);
    expect(await odm.users.get(server), hasLength(2));
    final adults = await odm.users
        .where(($) => $.age(isGreaterThan: 30))
        .get(server);
    expect(adults.map((u) => u.id), ['u2']);
    final ordered = await odm.users
        .orderBy(($) => ($.age(descending: true),))
        .limit(1)
        .get(server);
    expect(ordered.single.id, 'u2');
  });
}
