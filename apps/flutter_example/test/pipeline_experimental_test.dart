/// Experimental coverage for the **fully type-safe** Firestore Pipeline API
/// (`collection.pipeline()` → generated `$.field` selector → [TypedPipeline]).
///
/// Pipelines are an Enterprise-edition feature and are NOT supported by
/// `fake_cloud_firestore` or the emulator, so end-to-end `execute()` cannot be
/// exercised here — that requires a real Enterprise database. These tests assert
/// the **type-safe `$.field` builder compiles and chains** (no string field
/// paths), and document the execute() limitation.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreODM<TestSchema> db;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    db = FirestoreODM(testSchema, firestore: firestore);
  });

  group('Experimental: fully-typed pipeline() builder', () {
    test('builds where/sort/limit from the typed \$.field selector', () {
      // Compile-time proof: this only type-checks if `pipeline()` returns a
      // `TypedPipeline<User, UserPipelineSelector>` whose stages take the typed
      // `$.field` selector (no string `Field('age')`), the comparison value is
      // typed (`int` for age), nested fields work (`$.profile.followers`), and
      // the element type stays `User` through the chain. Never invoked —
      // fake_cloud_firestore has no pipeline engine (next test).
      Future<List<User>> Function() query = () => db.users
          .pipeline()
          .where(($) => $.age(isGreaterThanOrEqualTo: 18))
          .where(($) => $.profile.followers(isGreaterThan: 100))
          .sort(($) => $.age.descending(), ($) => $.name.ascending())
          .limit(20)
          .execute();

      expect(query, isA<Future<List<User>> Function()>());
    });

    test('select() projects into a typed record (compile-time)', () {
      // Proves `select` returns a `ProjectedPipeline` whose `execute()` yields a
      // typed record list — projected purely from `$.field`, no strings.
      Future<List<({String who, int years})>> Function() projected = () => db
          .users
          .pipeline()
          .where(($) => $.age(isGreaterThanOrEqualTo: 18))
          .select(($) => (who: $.name.value, years: $.age.value))
          .execute();

      expect(projected, isA<Future<List<({String who, int years})>> Function()>());
    });

    test('aggregate() returns a typed record (compile-time)', () {
      // Proves `aggregate` returns a typed record built from `$.field`
      // aggregates (count-all + per-field average), no strings.
      Future<({int count, double avgAge})> Function() stats = () => db.users
          .pipeline()
          .where(($) => $.age(isGreaterThan: 0))
          .aggregate(($) => (count: $.count(), avgAge: $.age.average()));

      expect(stats, isA<Future<({int count, double avgAge})> Function()>());
    });

    test('pipeline() is unsupported by fake_cloud_firestore (Enterprise-only)',
        () {
      // Pipelines require a real Firestore Enterprise database; the fake (and
      // the emulator) do not implement them. This is why pipeline execution
      // cannot be covered by this suite.
      expect(() => db.users.pipeline(), throwsA(anything));
    });
  });
}
