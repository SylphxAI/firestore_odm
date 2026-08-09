/// Typed where filters: every comparison operator, and/or composition, and
/// the documentId pseudo-field.
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late FirestoreODM<TestSchema> db;

  setUp(() async {
    final (_, odm) = newDb();
    db = odm;
    for (var i = 1; i <= 5; i++) {
      await odm.users.set(
        sampleUser(
          id: 'u$i',
          age: 20 + i,
        ).copyWith(isActive: i.isEven, tags: ['common', 't$i']),
      );
    }
  });

  test('isEqualTo / isNotEqualTo', () async {
    final eq = await db.users
        .where(($) => $.name(isEqualTo: 'User u2'))
        .get();
    expect(eq.single.id, 'u2');
    final neq = await db.users
        .where(($) => $.age(isNotEqualTo: 21))
        .get();
    expect(neq.map((u) => u.id), isNot(contains('u1')));
  });

  test('comparison operators', () async {
    final gt = await db.users.where(($) => $.age(isGreaterThan: 23)).get();
    expect(gt.map((u) => u.id), containsAll(['u4', 'u5']));
    final gte = await db.users
        .where(($) => $.age(isGreaterThanOrEqualTo: 23))
        .get();
    expect(gte.length, 3);
    final lt = await db.users.where(($) => $.age(isLessThan: 22)).get();
    expect(lt.single.id, 'u1');
    final lte = await db.users
        .where(($) => $.age(isLessThanOrEqualTo: 22))
        .get();
    expect(lte.length, 2);
  });

  test('array operations', () async {
    final contains = await db.users
        .where(($) => $.tags(arrayContains: 't3'))
        .get();
    expect(contains.single.id, 'u3');
    final containsAny = await db.users
        .where(($) => $.tags(arrayContainsAny: ['t1', 't5']))
        .get();
    expect(containsAny.length, 2);
  });

  test('whereIn / whereNotIn / isNull', () async {
    final inQ = await db.users
        .where(($) => $.age(whereIn: [21, 23]))
        .get();
    expect(inQ.length, 2);
    final notIn = await db.users
        .where(($) => $.age(whereNotIn: [21, 23]))
        .get();
    expect(notIn.length, 3);
    final nullQ = await db.users
        .where(($) => $.lastLogin(isNull: true))
        .get();
    // All sample users have lastLogin set; none should match.
    expect(nullQ, isEmpty);
  });

  test('nested field paths', () async {
    final result = await db.users
        .where(($) => $.profile.followers(isGreaterThan: 335))
        .get();
    expect(result.map((u) => u.id), containsAll(['u4', 'u5']));
  });

  test('and / or composition', () async {
    final andQ = await db.users
        .where(
          ($) => $.age(isGreaterThan: 22) & $.isActive(isEqualTo: true),
        )
        .get();
    expect(andQ.map((u) => u.id), containsAll(['u4']));
    final orQ = await db.users
        .where(
          ($) => $.age(isEqualTo: 21) | $.age(isEqualTo: 25),
        )
        .get();
    expect(orQ.length, 2);
  });

  test('documentId pseudo-field', () async {
    final result = await db.users
        .where(($) => $.documentId(isEqualTo: 'u3'))
        .get();
    expect(result.single.id, 'u3');
  });

  test('filter requires exactly one condition', () {
    expect(
      () => db.users.where(($) => $.age()),
      throwsArgumentError,
    );
  });

  test('stream emits matching documents', () async {
    final emitted = <List<User>>[];
    final sub = db.users
        .where(($) => $.isActive(isEqualTo: true))
        .stream
        .listen(emitted.add);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    expect(emitted, isNotEmpty);
    expect(emitted.last.every((u) => u.isActive), isTrue);
  });
}
