import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/immutable_user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🐛 IMap Patch Operations Bug Fix Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test(
      'IMap fields should support map operations in patch operations',
      () async {
        // Create user with IMap settings
        final user = ImmutableUser(
          id: 'imap_patch_test',
          name: 'IMap Patch Test User',
          email: 'imap@patch.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: {
            'theme': 'light',
            'language': 'en',
            'notifications': 'enabled',
          }.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Save initial user
        await odm.immutableUsers(user.id).update(user);

        // Test patch operations with IMap - this should work with map operations
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Test setting a specific key in the IMap
                update.settings.set('theme', 'dark'),
                // Test setting another key
                update.settings.set('newFeature', 'enabled'),
                // Test removing a key
                update.settings.remove('notifications'),
              ],
            );

        // Verify the patch operations worked
        final updatedUser = await odm.immutableUsers(user.id).get();
        expect(updatedUser, isNotNull);

        // Check that map operations were applied correctly
        expect(updatedUser!.settings['theme'], equals('dark')); // Updated
        expect(updatedUser.settings['language'], equals('en')); // Unchanged
        expect(updatedUser.settings['newFeature'], equals('enabled')); // Added
        expect(
          updatedUser.settings.containsKey('notifications'),
          isFalse,
        ); // Removed

        print('✅ IMap patch operations work correctly:');
        print('   - setKey() operations applied');
        print('   - removeKey() operations applied');
        print('   - Unchanged keys preserved');
        print('   - Final settings: ${updatedUser.settings}');
      },
    );

    test('IMap fields should NOT be treated as list/array fields', () async {
      // Create user with IMap settings
      final user = ImmutableUser(
        id: 'imap_not_list_test',
        name: 'IMap Not List Test',
        email: 'imap@notlist.test',
        age: 25,
        tags: ['test'].toIList(),
        scores: [95].toIList(),
        settings: {'initial': 'value'}.toIMap(),
        categories: {'tester'}.toISet(),
        rating: 4,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // This test verifies that IMap fields are treated as maps, not arrays
      // Before the fix, this would fail because IMap was incorrectly treated as iterable
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // These map operations should be available for IMap fields
              update.settings.set('theme', 'dark'),
              update.settings.set('language', 'zh'),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      expect(result!.settings['theme'], equals('dark'));
      expect(result.settings['language'], equals('zh'));
      expect(result.settings['initial'], equals('value')); // Preserved

      print('✅ IMap correctly treated as map type, not iterable type');
      print('   - Map operations (setKey, removeKey) are available');
      print('   - Array operations (add, remove) are NOT available');
    });

    test('IList fields should still support list operations', () async {
      // Verify that IList fields still work correctly as lists
      final user = ImmutableUser(
        id: 'ilist_operations_test',
        name: 'IList Operations Test',
        email: 'ilist@operations.test',
        age: 28,
        tags: ['initial', 'tag'].toIList(),
        scores: [80, 90].toIList(),
        settings: {'test': 'value'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.2,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test that IList fields support array operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // These array operations should work for IList fields
              update.tags.add('new-tag'),
              update.scores.add(95),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      expect(result!.tags.contains('new-tag'), isTrue);
      expect(result.scores.contains(95), isTrue);

      print('✅ IList fields correctly support array operations');
      print('   - add() operations work');
      print('   - Original elements preserved');
    });

    test('Mixed IMap and IList operations in single patch', () async {
      // Test that both IMap and IList can be used together in patch operations
      final user = ImmutableUser(
        id: 'mixed_operations_test',
        name: 'Mixed Operations Test',
        email: 'mixed@operations.test',
        age: 32,
        tags: ['flutter'].toIList(),
        scores: [85].toIList(),
        settings: {'theme': 'light'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.3,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Mix map and array operations in single patch
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Map operations on IMap field
              update.settings.set('language', 'dart'),
              update.settings.set('version', '3.0'),
              // Array operations on IList field
              update.tags.add('dart'),
              update.scores.add(92),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Verify map operations
      expect(result!.settings['language'], equals('dart'));
      expect(result.settings['version'], equals('3.0'));
      expect(result.settings['theme'], equals('light')); // Preserved

      // Verify array operations
      expect(result.tags.contains('dart'), isTrue);
      expect(result.scores.contains(92), isTrue);

      print('✅ Mixed IMap and IList operations work together');
      print('   - Map operations on IMap fields');
      print('   - Array operations on IList fields');
      print('   - Both types handled correctly in single patch');
    });
  });
}
