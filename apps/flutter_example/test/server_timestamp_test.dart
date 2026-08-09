/// Server timestamps are set explicitly via the patch `serverTimestamp()` op
/// (ADR-0002); DateTime fields round-trip as native timestamps, not strings.
library;

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('serverTimestamp() writes and reads back as a DateTime', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'u1'));
    await odm.users.patch('u1', (p) => [p.updatedAt.serverTimestamp()]);
    final user = await odm.users('u1').get();
    expect(user?.updatedAt, isA<DateTime>());
  });

  test('insert with a DateTime stores a native timestamp value', () async {
    final (_, odm) = newDb();
    final when = DateTime.utc(2026, 5, 1, 12, 30);
    await odm.users.set(sampleUser(id: 'u1').copyWith(createdAt: when));
    final raw = (await odm.firestore.collection('users').doc('u1').get()).data();
    // The raw stored value is a Timestamp — never an ISO string.
    expect(raw?['createdAt'], isA<Timestamp>());
    expect(raw?['createdAt'], isNot(isA<String>()));
    // And it round-trips through the ODM as the same instant (Timestamps are
    // timezone-less; the read value is a local-time DateTime).
    final read = (await odm.users('u1').get())?.createdAt;
    expect(read?.microsecondsSinceEpoch, when.microsecondsSinceEpoch);
  });
}
