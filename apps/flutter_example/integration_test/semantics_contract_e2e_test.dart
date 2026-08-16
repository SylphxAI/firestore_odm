/// Emulator e2e lane (ADR-0002): the live-Firestore behavior the fake cannot
/// model — Timestamp storage, dotted-path updates, transactions and queries.
///
/// Requires the Firestore emulator on localhost:8080 (CI runs it as a service
/// container). This lane is the deploy/live evidence for the semantics
/// contract; it is NOT run by the plain unit-test suite.
library;

import 'package:firestore_odm/firestore_odm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('write/read/query semantics against the emulator', (
    tester,
  ) async {
    await initializeFirebase();
    await clearFirestoreEmulator();
    final odm = FirestoreODM(testSchema);

    // Native FieldPath semantics: a dot within one component is a literal
    // field-name character, not a nested-path separator.
    final fieldPathRef = FirebaseFirestore.instance
        .collection('fieldPathContract')
        .doc('literal-dot');
    await fieldPathRef.set({
      'profile': {'v2.x': 1},
    });
    await fieldPathRef.update(
      operationsToMap([
        SetOperation(FieldNode(components: ['profile', 'v2.x']), 2),
      ]),
    );
    final fieldPathSnapshot = await fieldPathRef.get();
    expect(fieldPathSnapshot.get(FieldPath(['profile', 'v2.x'])), 2);

    // create returns a generated ID and stores native Timestamps.
    final id = await odm.users.create(
      User(
        id: 'ignored',
        name: 'E2E',
        email: 'e2e@example.com',
        age: 30,
        profile: const Profile(
          bio: 'b',
          avatar: 'a',
          socialLinks: {},
          interests: ['dart'],
          followers: 10,
        ),
        createdAt: DateTime.utc(2026, 7, 1),
      ),
    );
    expect(id, isNotEmpty);
    final doc = await odm.users(id).get();
    expect(doc?.name, 'E2E');
    expect(
      doc?.createdAt?.microsecondsSinceEpoch,
      DateTime.utc(2026, 7, 1).microsecondsSinceEpoch,
    );

    // patch ops (increment/union/serverTimestamp) round-trip.
    await odm.users.patch(
      id,
      (p) => [
        p.age.increment(5),
        p.tags.arrayUnion(['e2e']),
        p.updatedAt.serverTimestamp(),
      ],
    );
    final patched = await odm.users(id).get();
    expect(patched?.age, 35);
    expect(patched?.tags, contains('e2e'));
    expect(patched?.updatedAt, isA<DateTime>());

    // Filters incl. nested dotted paths.
    final matches = await odm.users
        .where(($) => $.profile.followers(isGreaterThan: 5))
        .get();
    expect(matches.single.id, id);

    // Transactions.
    await odm.runTransaction((tx) async {
      final txUsers = odm.users.inTransaction(tx);
      final current = await txUsers(id).get();
      txUsers(id).patch((p) => [p.age.increment(1)]);
      expect(current?.age, 35);
    });
    expect((await odm.users(id).get())?.age, 36);

    // Bulk delete.
    await odm.users.deleteAll();
    expect(await odm.users.count(), 0);
  });
}
