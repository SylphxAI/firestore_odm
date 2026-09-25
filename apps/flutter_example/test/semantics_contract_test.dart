/// Type mapping contract (ADR-0002): Duration as µs int, enums via
/// @JsonValue/name, nested models, maps/lists, and document-ID handling.
library;

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/enum_models.dart';
import 'package:flutter_example/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('document ID is injected on read and stripped on write', () async {
    final (_, odm) = newDb();
    await odm.users.set(sampleUser(id: 'u1'));
    final raw = (await odm.firestore.collection('users').doc('u1').get())
        .data();
    expect(raw, isNot(contains('id')));
    final user = await odm.users('u1').get();
    expect(user?.id, 'u1');
  });

  test('nested model round-trips including maps and lists', () async {
    final (_, odm) = newDb();
    final user = sampleUser(id: 'u1');
    await odm.users.set(user);
    final read = await odm.users('u1').get();
    expect(read?.profile.bio, user.profile.bio);
    expect(read?.profile.socialLinks, user.profile.socialLinks);
    expect(read?.profile.interests, user.profile.interests);
    expect(read?.settings, user.settings);
    expect(read?.metadata, user.metadata);
    expect(read?.scores, user.scores);
  });

  test('Duration is stored as microseconds (int)', () async {
    final (_, odm) = newDb();
    final task = Task(
      id: 't1',
      title: 'Task',
      description: 'Do the thing',
      estimatedDuration: const Duration(seconds: 90),
      createdAt: DateTime.utc(2026, 1, 1),
    );
    await odm.tasks.set(task);
    final raw = (await odm.firestore.collection('tasks').doc('t1').get())
        .data();
    expect(raw?['estimatedDuration'], 90000000);
    expect(
      (await odm.tasks('t1').get())?.estimatedDuration,
      const Duration(seconds: 90),
    );
  });

  test('enums serialize via @JsonValue and read back', () async {
    final (_, odm) = newDb();
    final user = EnumUser(
      id: 'e1',
      name: 'Enum',
      accountType: AccountType.pro,
      plan: AccountType.free,
      optional: AccountType.pro,
    );
    await odm.enumUsers.set(user);
    final raw = (await odm.firestore.collection('enumUsers').doc('e1').get())
        .data();
    expect(raw?['accountType'], 'pro');
    expect(raw?['plan'], 'free');
    final read = await odm.enumUsers('e1').get();
    expect(read?.accountType, AccountType.pro);
    expect(read?.optional, AccountType.pro);
  });

  test(
    'DateTime reads accept both Timestamp and DateTime (fake vs live)',
    () async {
      final (_, odm) = newDb();
      final when = DateTime.utc(2026, 6, 1);
      await odm.users.set(sampleUser(id: 'u1').copyWith(createdAt: when));
      final raw = (await odm.firestore.collection('users').doc('u1').get())
          .data();
      final user = await odm.users('u1').get();
      expect(
        user?.createdAt?.microsecondsSinceEpoch,
        when.microsecondsSinceEpoch,
      );
      // The raw stored value is a Timestamp (never an ISO string).
      expect(raw?['createdAt'], isA<Timestamp>());
      // Simulate the live SDK shape (Timestamp) directly through the converter.
      final ts = Timestamp.fromDate(when);
      final viaTimestamp = dateTimeFromJson(ts);
      expect(viaTimestamp.microsecondsSinceEpoch, when.microsecondsSinceEpoch);
    },
  );
}
