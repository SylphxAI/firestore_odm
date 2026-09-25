/// v5 write verbs: create (returns generated ID), set, patch (six ops),
/// delete, and document-ID validation.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('create', () {
    test('returns the generated document ID', () async {
      final (_, odm) = newDb();
      final id = await odm.users.create(sampleUser(id: 'ignored'));
      expect(id, isNotEmpty);
      // The stored document does not contain the ID field.
      final doc = await odm.firestore.collection('users').doc(id).get();
      expect(doc.data(), isNot(contains('id')));
    });
  });

  group('set', () {
    test('uses the model document ID field by default', () async {
      final (_, odm) = newDb();
      await odm.users.set(sampleUser(id: 'alice'));
      final user = await odm.users('alice').get();
      expect(user?.name, 'User alice');
    });

    test('supports an explicit ID', () async {
      final (_, odm) = newDb();
      await odm.users.set(sampleUser(id: 'model-id'), id: 'explicit-id');
      expect(await odm.users('explicit-id').get(), isNotNull);
      expect(await odm.users('model-id').get(), isNull);
    });

    test('rejects invalid document IDs', () async {
      final (_, odm) = newDb();
      await expectValidationError(() => odm.users.set(sampleUser(), id: 'a/b'));
      await expectValidationError(() => odm.users.set(sampleUser(), id: ''));
      await expectValidationError(
        () => odm.users.set(sampleUser(), id: '__reserved__'),
      );
      await expectValidationError(
        () => odm.users.set(sampleUser(), id: 'é' * 751), // 1502 bytes
      );
    });

    test('accepts IDs up to 1500 bytes', () async {
      final (_, odm) = newDb();
      final id = 'a' * 1500;
      await odm.users.set(sampleUser(), id: id);
      expect(await odm.users(id).get(), isNotNull);
    });

    test('rejects a model without a usable ID', () async {
      final (_, odm) = newDb();
      final user = sampleUser(id: '');
      await expectValidationError(() => odm.users.set(user));
    });
  });

  group('patch', () {
    test(
      'set, increment, arrayUnion, arrayRemove, delete, serverTimestamp',
      () async {
        final (_, odm) = newDb();
        await odm.users.set(sampleUser(id: 'u1', age: 30));
        await odm.users.patch(
          'u1',
          (p) => [
            p.name.set('Renamed'),
            p.age.increment(5),
            p.tags.arrayUnion(['new-tag']),
            p.updatedAt.serverTimestamp(),
            p.lastLogin.delete(),
          ],
        );
        await odm.users.patch(
          'u1',
          (p) => [
            p.tags.arrayRemove(['tag-a']),
          ],
        );
        final user = await odm.users('u1').get();
        expect(user?.name, 'Renamed');
        expect(user?.age, 35);
        expect(user?.tags, containsAll(['tag-b', 'new-tag']));
        expect(user?.tags, isNot(contains('tag-a')));
        expect(user?.lastLogin, isNull);
        expect(user?.updatedAt, isA<DateTime>());
      },
    );

    test('nested model fields patch by path', () async {
      final (fake, odm) = newDb();
      await odm.users.set(sampleUser(id: 'u1', age: 30)); // followers: 400
      await odm
          .users('u1')
          .patch(
            ($) => [
              $.profile.followers.increment(5),
              $.profile.interests.arrayUnion(['flutter']),
              $.profile.bio.set('updated'),
            ],
          );
      final user = await odm.users('u1').get();
      expect(user?.profile.followers, 405);
      expect(user?.profile.interests, ['dart', 'firestore', 'flutter']);
      expect(user?.profile.bio, 'updated');
      expect(user?.profile.avatar, 'avatar-u1'); // untouched sibling

      await odm.users.patch(
        'u1',
        ($) => [
          $.profile.set(
            const Profile(
              bio: 'new',
              avatar: 'a',
              socialLinks: {},
              interests: [],
            ),
          ),
        ],
      );
      expect((await odm.users('u1').get())?.profile.bio, 'new');

      await odm.users.patch('u1', ($) => [$.profile.story.delete()]);
      final raw = await fake.doc('users/u1').get();
      expect((raw.data()!['profile'] as Map).containsKey('story'), isFalse);
    });

    test('DateTime inside a nested model round-trips as a Timestamp', () async {
      final (fake, odm) = newDb();
      final lastActive = DateTime.utc(2026, 9, 1, 12);
      final user = sampleUser(id: 'u1');
      await odm.users.set(
        user.copyWith(profile: user.profile.copyWith(lastActive: lastActive)),
      );
      final raw = await fake.doc('users/u1').get();
      expect((raw.data()!['profile'] as Map)['lastActive'], isA<Timestamp>());
      final read = await odm.users('u1').get();
      expect(read?.profile.lastActive?.toUtc(), lastActive);
    });

    test('no-op patch leaves the document untouched', () async {
      final (_, odm) = newDb();
      await odm.users.set(sampleUser(id: 'u1'));
      await odm.users.patch('u1', (p) => []);
      expect((await odm.users('u1').get())?.name, 'User u1');
    });
  });

  group('delete', () {
    test('removes the document', () async {
      final (_, odm) = newDb();
      await odm.users.set(sampleUser(id: 'u1'));
      await odm.users.delete('u1');
      expect(await odm.users('u1').get(), isNull);
    });
  });

  group('document handle', () {
    test('get/set/patch/delete round-trip', () async {
      final (_, odm) = newDb();
      final doc = odm.users('u1');
      expect(await doc.get(), isNull);
      await doc.set(sampleUser(id: 'u1'));
      expect((await doc.get())?.id, 'u1');
      await doc.patch((p) => [p.rating.increment(0.5)]);
      expect((await doc.get())?.rating, 5.0);
      await doc.delete();
      expect(await doc.get(), isNull);
    });
  });

  group('exceptions', () {
    test('validation errors carry a stable code', () async {
      final (_, odm) = newDb();
      try {
        await odm.users.set(sampleUser(), id: 'bad/id');
        fail('expected validation error');
      } on FirestoreODMValidationException catch (e) {
        expect(e.code, 'invalid_document_id');
      }
    });
  });
}
