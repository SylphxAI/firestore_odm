/// v5 write verbs: create (returns generated ID), set, patch (six ops),
/// delete, and document-ID validation (ADR-0002).
library;

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
    });

    test('rejects a model without a usable ID', () async {
      final (_, odm) = newDb();
      final user = sampleUser(id: '');
      await expectValidationError(() => odm.users.set(user));
    });
  });

  group('patch', () {
    test('set, increment, arrayUnion, arrayRemove, delete, serverTimestamp',
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
      await odm.users.patch('u1', (p) => [p.tags.arrayRemove(['tag-a'])]);
      final user = await odm.users('u1').get();
      expect(user?.name, 'Renamed');
      expect(user?.age, 35);
      expect(user?.tags, containsAll(['tag-b', 'new-tag']));
      expect(user?.tags, isNot(contains('tag-a')));
      expect(user?.lastLogin, isNull);
      expect(user?.updatedAt, isA<DateTime>());
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
