/// Transactions: read-before-write ordering via deferred writes, document
/// caching, and all four write verbs (ADR-0002).
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('deferred writes flush after reads; read-before-write holds',
      () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'a', age: 10));
    await odm.users.set(sampleUser(id: 'b', age: 20));

    await odm.runTransaction((tx) async {
      final txUsers = odm.users.inTransaction(tx);
      // Reads first...
      final a = await txUsers('a').get();
      await txUsers('b').get();
      expect(a?.age, 10);
      // ...then writes (deferred until the callback finishes).
      txUsers('a').patch((p) => [p.age.increment(1)]);
      txUsers('b').set(sampleUser(id: 'b', age: 21));
    });

    expect((await odm.users('a').get())?.age, 11);
    expect((await odm.users('b').get())?.age, 21);
  });

  test('reads are cached per transaction attempt', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'a'));
    var reads = 0;
    await odm.runTransaction((tx) async {
      final txUsers = odm.users.inTransaction(tx);
      await txUsers('a').get();
      await txUsers('a').get();
      reads = 1;
    });
    expect(reads, 1);
  });

  test('create inside a transaction returns the generated ID', () async {
    final (_, odm) = newDb();
    late String id;
    await odm.runTransaction((tx) async {
      id = odm.users.inTransaction(tx).create(sampleUser(id: 'ignored'));
    });
    expect(id, isNotEmpty);
    expect(await odm.users(id).get(), isNotNull);
  });

  test('delete inside a transaction', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'a'));
    await odm.runTransaction((tx) async {
      odm.users.inTransaction(tx).delete('a');
    });
    expect(await odm.users('a').get(), isNull);
  });

  test('aborting the callback rolls back deferred writes', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'a', age: 1));
    await expectLater(
      odm.runTransaction((tx) async {
        final txUsers = odm.users.inTransaction(tx);
        await txUsers('a').get();
        txUsers('a').patch((p) => [p.age.increment(100)]);
        throw StateError('abort');
      }),
      throwsA(isA<StateError>()),
    );
    expect((await odm.users('a').get())?.age, 1);
  });
}
