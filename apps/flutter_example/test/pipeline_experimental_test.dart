/// Experimental coverage for the type-safe Firestore Pipeline wrapper
/// (`collection.pipeline()` → [TypedPipeline]).
///
/// Pipelines are an Enterprise-edition feature and are NOT supported by
/// `fake_cloud_firestore` or the emulator, so end-to-end `execute()` cannot be
/// exercised here — that requires a real Enterprise database. These tests only
/// assert the **type-safe builder API compiles and chains**, and document the
/// execute() limitation.
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

  group('Experimental: pipeline() typed builder', () {
    test('exposes a type-safe, chainable pipeline() (compile-time)', () {
      // The verification here is at COMPILE time: this closure only type-checks
      // if the collection exposes `pipeline()` returning a `TypedPipeline<User>`
      // whose `where`/`sort`/`limit` stages chain and preserve the `User`
      // element type. It is deliberately never invoked — fake_cloud_firestore
      // has no pipeline engine (see the next test).
      Future<List<User>> Function() query = () => db.users
          .pipeline()
          .where(Field('age').greaterThanOrEqualValue(18))
          .sort(Field('age').descending())
          .limit(20)
          .execute();

      expect(query, isA<Future<List<User>> Function()>());
    });

    test(
      'pipeline() is unsupported by fake_cloud_firestore (Enterprise-only)',
      () {
        // Documents the runtime constraint: Pipelines require a real Firestore
        // Enterprise database; the fake (and the emulator) do not implement them.
        // This is why pipeline execution cannot be covered by this suite.
        expect(() => db.users.pipeline(), throwsA(anything));
      },
    );
  });
}
