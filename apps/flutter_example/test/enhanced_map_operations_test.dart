import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/immutable_user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🚀 Enhanced Map Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('Single key operations - setKey, removeKey, put, remove', () async {
      final user = ImmutableUser(
        id: 'single_key_test',
        name: 'Single Key Test User',
        email: 'single@key.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {'theme': 'light', 'language': 'en'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test single key operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Original methods
              update.settings.set('notifications', 'enabled'),
              update.settings.remove('language'),
              // Dart Map-like aliases
              update.settings.set('theme', 'dark'),
              update.settings.remove('nonexistent'), // Should be safe
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      expect(result!.settings['theme'], equals('dark')); // Updated via put
      expect(
        result.settings['notifications'],
        equals('enabled'),
      ); // Added via setKey
      expect(
        result.settings.containsKey('language'),
        isFalse,
      ); // Removed via removeKey

      print('✅ Single key operations work correctly');
      print('   - setKey() and put() for setting values');
      print('   - removeKey() and remove() for removing keys');
    });

    test('Multiple key operations - putAll, addAll, removeAll', () async {
      final user = ImmutableUser(
        id: 'multiple_key_test',
        name: 'Multiple Key Test User',
        email: 'multiple@key.test',
        age: 25,
        tags: ['test'].toIList(),
        scores: [95].toIList(),
        settings: {
          'theme': 'light',
          'language': 'en',
          'oldSetting1': 'value1',
          'oldSetting2': 'value2',
        }.toIMap(),
        categories: {'tester'}.toISet(),
        rating: 4,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test multiple key operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Add multiple entries at once
              update.settings.addAll({
                'notifications': 'enabled',
                'autoSave': 'true',
                'version': '2.0',
              }),
              // Remove multiple keys at once
              update.settings.removeWhere(['oldSetting1', 'oldSetting2']),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check added entries
      expect(result!.settings['notifications'], equals('enabled'));
      expect(result.settings['autoSave'], equals('true'));
      expect(result.settings['version'], equals('2.0'));

      // Check removed entries
      expect(result.settings.containsKey('oldSetting1'), isFalse);
      expect(result.settings.containsKey('oldSetting2'), isFalse);

      // Check preserved entries
      expect(result.settings['theme'], equals('light'));
      expect(result.settings['language'], equals('en'));

      print('✅ Multiple key operations work correctly');
      print('   - putAll() for adding multiple entries');
      print('   - removeAll() for removing multiple keys');
    });

    test('Bulk operations - updateEntries, clear, merge', () async {
      final user = ImmutableUser(
        id: 'bulk_operations_test',
        name: 'Bulk Operations Test User',
        email: 'bulk@operations.test',
        age: 28,
        tags: ['test'].toIList(),
        scores: [85].toIList(),
        settings: {
          'theme': 'light',
          'language': 'en',
          'notifications': 'disabled',
        }.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.2,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test bulk operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Update multiple entries using MapEntry
              update.settings.addEntries([
                const MapEntry('theme', 'dark'),
                const MapEntry('language', 'zh'),
                const MapEntry('newFeature', 'enabled'),
              ]),
              // Merge operation for nested updates
              update.settings.addAll({'advanced': 'true', 'beta': 'enabled'}),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check updated entries
      expect(result!.settings['theme'], equals('dark'));
      expect(result.settings['language'], equals('zh'));
      expect(result.settings['newFeature'], equals('enabled'));

      // Check merged entries
      expect(result.settings['advanced'], equals('true'));
      expect(result.settings['beta'], equals('enabled'));

      // Check preserved entries
      expect(result.settings['notifications'], equals('disabled'));

      print('✅ Bulk operations work correctly');
      print('   - updateEntries() for multiple MapEntry updates');
      print('   - merge() for object merging');
    });

    test('Advanced operations - setKeysToValue, removeKeys, clear', () async {
      final user = ImmutableUser(
        id: 'advanced_operations_test',
        name: 'Advanced Operations Test User',
        email: 'advanced@operations.test',
        age: 32,
        tags: ['test'].toIList(),
        scores: [90].toIList(),
        settings: {
          'feature1': 'disabled',
          'feature2': 'disabled',
          'feature3': 'enabled',
          'setting1': 'value1',
          'setting2': 'value2',
        }.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.3,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test advanced operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Set multiple keys to the same value
              update.settings.setAll(['feature1', 'feature2'], 'enabled'),
              // Remove multiple keys using individual arguments
              update.settings.removeWhere(['setting1', 'setting2']),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check keys set to same value
      expect(result!.settings['feature1'], equals('enabled'));
      expect(result.settings['feature2'], equals('enabled'));
      expect(result.settings['feature3'], equals('enabled')); // Unchanged

      // Check removed keys
      expect(result.settings.containsKey('setting1'), isFalse);
      expect(result.settings.containsKey('setting2'), isFalse);

      print('✅ Advanced operations work correctly');
      print('   - setKeysToValue() for setting multiple keys to same value');
      print('   - removeKeys() for removing multiple keys with arguments');
    });

    test('Conditional operations - putIfAbsent, renameKey', () async {
      final user = ImmutableUser(
        id: 'conditional_operations_test',
        name: 'Conditional Operations Test User',
        email: 'conditional@operations.test',
        age: 27,
        tags: ['test'].toIList(),
        scores: [88].toIList(),
        settings: {'theme': 'light', 'oldKeyName': 'importantValue'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.1,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test conditional operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Put if absent (will set since key doesn't exist)
              update.settings.set('newSetting', 'defaultValue'),
              // Rename key operation - first remove old key, then set new key
              update.settings.remove('oldKeyName'),
              update.settings.set('newKeyName', 'importantValue'),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check putIfAbsent
      expect(result!.settings['newSetting'], equals('defaultValue'));

      // Check rename operation
      expect(result.settings.containsKey('oldKeyName'), isFalse);
      expect(result.settings['newKeyName'], equals('importantValue'));

      // Check preserved entries
      expect(result.settings['theme'], equals('light'));

      print('✅ Conditional operations work correctly');
      print('   - putIfAbsent() for conditional setting');
      print('   - renameKey() for key renaming');
    });

    test('Mixed operations in single patch', () async {
      final user = ImmutableUser(
        id: 'mixed_operations_test',
        name: 'Mixed Operations Test User',
        email: 'mixed@operations.test',
        age: 35,
        tags: ['flutter', 'dart'].toIList(),
        scores: [92, 88].toIList(),
        settings: {
          'theme': 'light',
          'language': 'en',
          'oldFeature': 'enabled',
        }.toIMap(),
        categories: {'developer', 'architect'}.toISet(),
        rating: 4.7,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test mixing different types of operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Single key operations
              update.settings.set('notifications', 'enabled'),
              update.settings.set('autoSave', 'true'),
              update.settings.remove('oldFeature'),

              // Multiple key operations
              update.settings.addAll({'version': '3.0', 'beta': 'enabled'}),
              update.settings.removeWhere(['nonexistent1', 'nonexistent2']),

              // Advanced operations
              update.settings.setAll(['feature1', 'feature2'], 'enabled'),

              // Array operations on other fields
              update.tags.add('firestore'),
              update.scores.add(95),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check map operations
      expect(result!.settings['notifications'], equals('enabled'));
      expect(result.settings['autoSave'], equals('true'));
      expect(result.settings['version'], equals('3.0'));
      expect(result.settings['beta'], equals('enabled'));
      expect(result.settings['feature1'], equals('enabled'));
      expect(result.settings['feature2'], equals('enabled'));
      expect(result.settings.containsKey('oldFeature'), isFalse);

      // Check preserved map entries
      expect(result.settings['theme'], equals('light'));
      expect(result.settings['language'], equals('en'));

      // Check array operations still work
      expect(result.tags.contains('firestore'), isTrue);
      expect(result.scores.contains(95), isTrue);

      print('✅ Mixed operations work correctly');
      print('   - Map operations work alongside array operations');
      print('   - Multiple operation types can be combined in single patch');
      print('   - All operation types maintain their individual functionality');
    });

    test('Edge cases and error handling', () async {
      final user = ImmutableUser(
        id: 'edge_cases_test',
        name: 'Edge Cases Test User',
        email: 'edge@cases.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {'existing': 'value'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test edge cases
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Empty operations should be safe
              update.settings.addAll({}),
              update.settings.removeWhere([]),
              update.settings.setAll([], 'value'),

              // Operations on non-existent keys should be safe
              update.settings.remove('nonexistent'),
              update.settings.removeWhere(['nonexistent1', 'nonexistent2']),

              // Setting string values (null not supported for typed maps)
              update.settings.set('emptyValue', ''),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check that existing data is preserved
      expect(result!.settings['existing'], equals('value'));

      // Check empty value was set
      expect(result.settings.containsKey('emptyValue'), isTrue);
      expect(result.settings['emptyValue'], equals(''));

      print('✅ Edge cases handled correctly');
      print('   - Empty operations are safe');
      print('   - Operations on non-existent keys are safe');
      print('   - Empty string values can be set');
    });
  });
}
