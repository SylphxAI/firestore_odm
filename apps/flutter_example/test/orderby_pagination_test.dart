/// Typed orderBy + object/value cursor pagination (ADR-0002).
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late FirestoreODM<TestSchema> db;

  setUp(() async {
    final (_, odm) = newDb();
    db = odm;
    for (var i = 1; i <= 10; i++) {
      await odm.users.set(
        sampleUser(id: 'u${i.toString().padLeft(2, '0')}', age: i),
      );
    }
  });

  test('orderBy ascending/descending with nested fields', () async {
    final asc = await db.users
        .orderBy(($) => ($.profile.followers(descending: true),))
        .get();
    expect(
      asc.first.profile.followers,
      greaterThan(asc.last.profile.followers),
    );
  });

  test(
    'object cursor pagination pages through without skips or duplicates',
    () async {
      final page1 = await db.users.orderBy(($) => ($.age(),)).limit(3).get();
      expect(page1.map((u) => u.age), [1, 2, 3]);

      final page2 = await db.users
          .orderBy(($) => ($.age(),))
          .startAfterObject(page1.last)
          .limit(3)
          .get();
      expect(page2.map((u) => u.age), [4, 5, 6]);

      final page3 = await db.users
          .orderBy(($) => ($.age(),))
          .startAfterObject(page2.last)
          .limit(3)
          .get();
      expect(page3.map((u) => u.age), [7, 8, 9]);

      final page4 = await db.users
          .orderBy(($) => ($.age(),))
          .startAfterObject(page3.last)
          .limit(3)
          .get();
      expect(page4.map((u) => u.age), [10]);
    },
  );

  test('documentId tie-breaker gives deterministic ordering', () async {
    // u00 shares age 1 with u01: the tie is broken deterministically by the
    // document ID (descending). (Cursor pagination over a documentId term is
    // not exercisable with fake_cloud_firestore — its cursor comparison cannot
    // resolve FieldPath.documentId — and is covered by the emulator lane.)
    await db.users.set(sampleUser(id: 'u00', age: 1));
    final ordered = await db.users
        .orderBy(($) => ($.age(), $.documentId(descending: true)))
        .limit(2)
        .get();
    expect(ordered.map((u) => u.age), [1, 1]);
    // 'u01' > 'u00', so descending documentId puts u01 first.
    expect(ordered.map((u) => u.id), ['u01', 'u00']);
  });

  test('value cursors with records', () async {
    final page = await db.users
        .orderBy(($) => ($.age(),))
        .startAfter((3,))
        .limit(2)
        .get();
    expect(page.map((u) => u.age), [4, 5]);
  });

  test('endBefore / endAt', () async {
    final before = await db.users.orderBy(($) => ($.age(),)).endBefore((
      4,
    )).get();
    expect(before.map((u) => u.age), [1, 2, 3]);
    final at = await db.users.orderBy(($) => ($.age(),)).endAt((4,)).get();
    expect(at.length, 4);
  });

  test('limit / limitToLast', () async {
    final first = await db.users.orderBy(($) => ($.age(),)).limit(2).get();
    expect(first.map((u) => u.age), [1, 2]);
    final last = await db.users.orderBy(($) => ($.age(),)).limitToLast(2).get();
    expect(last.map((u) => u.age), [9, 10]);
  });
}
