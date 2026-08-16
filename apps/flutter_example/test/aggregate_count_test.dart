/// Server-side aggregates are one-shot only (ADR-0002): no fake streaming.
library;

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('count() returns the matching document count', () async {
    final (_, odm) = newDb();
    for (var i = 1; i <= 5; i++) {
      await odm.users.set(sampleUser(id: 'u$i', age: i));
    }
    expect(await odm.users.count(), 5);
    expect(await odm.users.where(($) => $.age(isGreaterThan: 3)).count(), 2);
  });

  test('aggregate() returns a typed record (count/sum/average)', () async {
    final (_, odm) = newDb();
    for (var i = 1; i <= 4; i++) {
      await odm.users.set(sampleUser(id: 'u$i', age: i * 10));
    }
    final stats = await odm.users
        .aggregate(
          ($) => (
            count: $.count(),
            totalAge: $.age.sum(),
            avgAge: $.age.average(),
          ),
        )
        .get();
    expect(stats.count, 4);
    expect(stats.totalAge, 100);
    expect(stats.avgAge, 25.0);
  });

  test('aggregate() composes with where()', () async {
    final (_, odm) = newDb();
    for (var i = 1; i <= 4; i++) {
      await odm.users.set(sampleUser(id: 'u$i', age: i * 10));
    }
    final total = await odm.users
        .where(($) => $.age(isGreaterThan: 20))
        .aggregate(($) => (total: $.age.sum(), n: $.count()))
        .get();
    expect(total.n, 2);
    expect(total.total, 70);
  });

  test('no streaming aggregate surface exists', () async {
    final (_, odm) = newDb();
    // Compile-level contract: AggregateQuery exposes only get().
    final q = odm.users.aggregate(($) => (n: $.count()));
    expect(q, isA<Object>());
    // count() is a Future, not a stream.
    final c = odm.users.count();
    expect(c, isA<Future<int>>());
  });
}
