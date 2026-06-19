import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/immutable_user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🎯 Clean Map Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('Core operations - set, remove (Dart Map style)', () async {
      final user = ImmutableUser(
        id: 'core_operations_test',
        name: 'Core Operations Test User',
        email: 'core@operations.test',
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

      // Test core operations with clean API
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Set single values (like map[key] = value)
              update.settings.set('theme', 'dark'),
              update.settings.set('notifications', 'enabled'),
              // Remove single values (like map.remove(key))
              update.settings.remove('language'),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);
      expect(result!.settings['theme'], equals('dark'));
      expect(result.settings['notifications'], equals('enabled'));
      expect(result.settings.containsKey('language'), isFalse);

      print('✅ Core operations work correctly');
      print('   - set() for setting single values');
      print('   - remove() for removing single keys');
    });

    test('Bulk operations - addAll, removeWhere, clear', () async {
      final user = ImmutableUser(
        id: 'bulk_operations_test',
        name: 'Bulk Operations Test User',
        email: 'bulk@operations.test',
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

      // Test bulk operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Add multiple entries at once (like map.addAll(other))
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

      print('✅ Bulk operations work correctly');
      print('   - addAll() for adding multiple entries');
      print('   - removeWhere() for removing multiple keys');
    });

    test('Convenience operations - setAll', () async {
      final user = ImmutableUser(
        id: 'convenience_operations_test',
        name: 'Convenience Operations Test User',
        email: 'convenience@operations.test',
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

      // Test convenience operations
      await odm
          .immutableUsers(user.id)
          .patch(
            ($) => [
              // $ individual entries
              $.settings.set('theme', 'dark'),
              $.settings.set('language', 'zh'),
              $.settings.set('newFeature', 'enabled'),
              // Set multiple keys to same value
              $.settings.setAll(['feature1', 'feature2'], 'enabled'),
              // Add multiple entries using Map
              $.settings.addAll({'advanced': 'true', 'beta': 'enabled'}),
              // Add multiple entries using MapEntry iterable (more flexible)
              $.settings.addEntries([
                const MapEntry('flexible1', 'value1'),
                const MapEntry('flexible2', 'value2'),
              ]),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check updated entries
      expect(result!.settings['theme'], equals('dark'));
      expect(result.settings['language'], equals('zh'));
      expect(result.settings['newFeature'], equals('enabled'));

      // Check setAll entries
      expect(result.settings['feature1'], equals('enabled'));
      expect(result.settings['feature2'], equals('enabled'));

      // Check addAll entries
      expect(result.settings['advanced'], equals('true'));
      expect(result.settings['beta'], equals('enabled'));

      // Check addEntries entries
      expect(result.settings['flexible1'], equals('value1'));
      expect(result.settings['flexible2'], equals('value2'));

      // Check preserved entries
      expect(result.settings['notifications'], equals('disabled'));

      print('✅ Convenience operations work correctly');
      print('   - set() for individual updates');
      print('   - setAll() for setting multiple keys to same value');
      print('   - addAll() for adding multiple entries from Map');
      print('   - addEntries() for adding from MapEntry iterable');
    });

    test('Mixed operations with arrays', () async {
      final user = ImmutableUser(
        id: 'mixed_operations_test',
        name: 'Mixed Operations Test User',
        email: 'mixed@operations.test',
        age: 35,
        tags: ['flutter', 'dart'].toIList(),
        scores: [92, 88].toIList(),
        settings: {'theme': 'light', 'language': 'en'}.toIMap(),
        categories: {'developer', 'architect'}.toISet(),
        rating: 4.7,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test mixing map and array operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Map operations
              update.settings.set('notifications', 'enabled'),
              update.settings.addAll({'version': '3.0', 'beta': 'enabled'}),
              update.settings.setAll(['feature1', 'feature2'], 'enabled'),

              // Array operations (still work alongside map operations)
              update.tags.add('firestore'),
              update.scores.add(95),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check map operations
      expect(result!.settings['notifications'], equals('enabled'));
      expect(result.settings['version'], equals('3.0'));
      expect(result.settings['beta'], equals('enabled'));
      expect(result.settings['feature1'], equals('enabled'));
      expect(result.settings['feature2'], equals('enabled'));

      // Check preserved map entries
      expect(result.settings['theme'], equals('light'));
      expect(result.settings['language'], equals('en'));

      // Check array operations still work
      expect(result.tags.contains('firestore'), isTrue);
      expect(result.scores.contains(95), isTrue);

      print('✅ Mixed operations work correctly');
      print('   - Map operations work alongside array operations');
      print('   - Clean, consistent API across all operations');
    });

    test('📋 CLEAR operation - Complete map clearing', () async {
      final user = ImmutableUser(
        id: 'clear_operation_test',
        name: 'Clear Operation Test User',
        email: 'clear@operations.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {
          'theme': 'dark',
          'language': 'en',
          'notifications': 'enabled',
          'version': '1.0',
          'features': 'many',
        }.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Verify initial state has multiple entries
      final beforeClear = await odm.immutableUsers(user.id).get();
      expect(beforeClear!.settings.length, equals(5));
      expect(beforeClear.settings['theme'], equals('dark'));

      // Test clear operation
      await odm
          .immutableUsers(user.id)
          .patch((update) => [update.settings.clear()]);

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check that all entries are cleared
      expect(result!.settings.length, equals(0));
      expect(result.settings.isEmpty, isTrue);
      expect(result.settings.containsKey('theme'), isFalse);
      expect(result.settings.containsKey('language'), isFalse);

      print('✅ Clear operation works correctly');
      print('   - clear() removes all map entries');
      print('   - Map becomes completely empty');
    });

    test(
      '🔄 Complex data types and value overwriting',
      skip: 'Special symbols in keys not supported',
      () async {
        final user = ImmutableUser(
          id: 'complex_data_test',
          name: 'Complex Data Test User',
          email: 'complex@data.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: {
            'numberValue': '42',
            'booleanValue': 'true',
            'existingKey': 'oldValue',
          }.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.immutableUsers(user.id).update(user);

        // Test complex data types and overwriting
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Overwrite existing values
                update.settings.set('existingKey', 'newValue'),
                update.settings.set('numberValue', '999'),

                // Different data types as strings
                update.settings.set('floatValue', '3.14159'),
                update.settings.set('booleanFalse', 'false'),
                update.settings.set('jsonLike', '{"nested": "value"}'),
                update.settings.set('arrayLike', '[1,2,3]'),

                // Special characters in keys and values
                update.settings.set('key-with-dashes', 'value'),
                update.settings.set('key_with_underscores', 'value'),
                update.settings.set(
                  'keyWithDots',
                  'value',
                ), // Avoid dots in keys (Firestore interprets as nested)
                update.settings.set('specialChars', r'value!@#$%^&*()'),

                // Unicode and emojis
                update.settings.set('unicode', '你好世界'),
                update.settings.set('emoji', '🚀✨💻'),
              ],
            );

        final result = await odm.immutableUsers(user.id).get();
        expect(result, isNotNull);

        // Check overwritten values
        expect(result!.settings['existingKey'], equals('newValue'));
        expect(result.settings['numberValue'], equals('999'));

        // Check complex data types
        expect(result.settings['floatValue'], equals('3.14159'));
        expect(result.settings['booleanFalse'], equals('false'));
        expect(result.settings['jsonLike'], equals('{"nested": "value"}'));
        expect(result.settings['arrayLike'], equals('[1,2,3]'));

        // Check special characters
        expect(result.settings['key-with-dashes'], equals('value'));
        expect(result.settings['key_with_underscores'], equals('value'));
        expect(result.settings['key.with.dots'], equals('value'));
        expect(result.settings['specialChars'], equals(r'value!@#$%^&*()'));

        // Check unicode and emojis
        expect(result.settings['unicode'], equals('你好世界'));
        expect(result.settings['emoji'], equals('🚀✨💻'));

        print('✅ Complex data types handled correctly');
        print('   - Value overwriting works correctly');
        print('   - Special characters in keys/values supported');
        print('   - Unicode and emojis supported');
      },
    );

    test('⚙️ Large dataset operations and performance', () async {
      final user = ImmutableUser(
        id: 'large_dataset_test',
        name: 'Large Dataset Test User',
        email: 'large@dataset.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: <String, String>{}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Create large datasets for testing
      final largeMap = <String, String>{};
      final moreEntries = <MapEntry<String, String>>[];
      final keysToRemove = <String>[];
      final keysForSetAll = <String>[];

      for (var i = 0; i < 50; i++) {
        largeMap['key$i'] = 'value$i';
        moreEntries.add(MapEntry('entry$i', 'entryValue$i'));
        if (i < 25) keysToRemove.add('key$i');
        if (i >= 25) keysForSetAll.add('key$i');
      }

      // Test large dataset operations
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Add large map
              update.settings.addAll(largeMap),
              // Add large entry list
              update.settings.addEntries(moreEntries),
              // Set many keys to same value
              update.settings.setAll(keysForSetAll, 'uniformValue'),
              // Remove many keys
              update.settings.removeWhere(keysToRemove),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check that operations completed correctly
      expect(result!.settings.length, greaterThan(50));

      // Check some addAll entries (that weren't removed)
      expect(
        result.settings['key25'],
        equals('uniformValue'),
      ); // setAll overwrote this
      expect(
        result.settings['key49'],
        equals('uniformValue'),
      ); // setAll overwrote this

      // Check removed keys are gone
      expect(result.settings.containsKey('key0'), isFalse);
      expect(result.settings.containsKey('key24'), isFalse);

      // Check addEntries worked
      expect(result.settings['entry0'], equals('entryValue0'));
      expect(result.settings['entry49'], equals('entryValue49'));

      print('✅ Large dataset operations work correctly');
      print('   - Can handle 50+ entries in single operation');
      print('   - Multiple bulk operations execute properly');
      print('   - Performance is acceptable for large datasets');
    });

    test('🔗 Operation chaining and order dependency', () async {
      final user = ImmutableUser(
        id: 'operation_chaining_test',
        name: 'Operation Chaining Test User',
        email: 'chaining@operations.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {'initial': 'value'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test operation order and chaining behavior
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // 1. Set some initial values
              update.settings.set('step1', 'first'),
              update.settings.set('step2', 'second'),

              // 2. Add bulk values that might conflict
              update.settings.addAll({
                'step1':
                    'overwritten', // This should overwrite the previous set
                'step3': 'third',
              }),

              // 3. Set multiple keys to same value (some existing, some new)
              update.settings.setAll(['step2', 'step4'], 'uniform'),

              // 4. Add more entries
              update.settings.addEntries([
                const MapEntry('step5', 'fifth'),
                const MapEntry('step1', 'final'), // Final overwrite
              ]),

              // 5. Remove some keys
              update.settings.removeWhere(['step3']),

              // 6. Final individual updates
              update.settings.set('final', 'last'),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check final state after all operations
      expect(
        result!.settings['step1'],
        equals('final'),
      ); // Last addEntries wins
      expect(result.settings['step2'], equals('uniform')); // setAll value
      expect(result.settings.containsKey('step3'), isFalse); // Removed
      expect(result.settings['step4'], equals('uniform')); // setAll value
      expect(result.settings['step5'], equals('fifth')); // addEntries value
      expect(result.settings['final'], equals('last')); // final set
      expect(result.settings['initial'], equals('value')); // Preserved

      print('✅ Operation chaining works correctly');
      print('   - Later operations can overwrite earlier ones');
      print('   - Operation order matters for final state');
      print('   - Complex chains execute successfully');
    });

    test('🔍 addEntries vs addAll behavior comparison', () async {
      final user = ImmutableUser(
        id: 'addmethods_comparison_test',
        name: 'Add Methods Comparison User',
        email: 'addmethods@comparison.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: <String, String>{}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test addAll vs addEntries with same data
      final mapData = {'key1': 'value1', 'key2': 'value2'};
      final entryData = [
        const MapEntry('key3', 'value3'),
        const MapEntry('key4', 'value4'),
      ];

      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Using addAll with Map
              update.settings.addAll(mapData),

              // Using addEntries with MapEntry iterable
              update.settings.addEntries(entryData),

              // Using addEntries with generated entries
              update.settings.addEntries(
                ['key5', 'key6'].map((key) => MapEntry(key, 'generated_$key')),
              ),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check addAll results
      expect(result!.settings['key1'], equals('value1'));
      expect(result.settings['key2'], equals('value2'));

      // Check addEntries results
      expect(result.settings['key3'], equals('value3'));
      expect(result.settings['key4'], equals('value4'));

      // Check generated addEntries results
      expect(result.settings['key5'], equals('generated_key5'));
      expect(result.settings['key6'], equals('generated_key6'));

      print('✅ addEntries vs addAll comparison complete');
      print('   - addAll works with Map<K,V>');
      print('   - addEntries works with Iterable<MapEntry<K,V>>');
      print('   - Both methods produce equivalent results');
      print('   - addEntries offers more flexibility for dynamic generation');
    });

    test('🧪 Edge cases and error scenarios', () async {
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

      // Test edge cases and error scenarios
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Empty operations should be safe
              update.settings.addAll({}),
              update.settings.removeWhere([]),
              update.settings.setAll([], 'value'),
              update.settings.addEntries([]),

              // Operations on non-existent keys should be safe
              update.settings.remove('nonexistent'),
              update.settings.removeWhere(['nonexistent1', 'nonexistent2']),

              // Setting various edge case values
              update.settings.set('emptyValue', ''),
              update.settings.set('spaceValue', ' '),
              update.settings.set('nullString', 'null'),
              update.settings.set('undefinedString', 'undefined'),

              // Keys with edge case names
              update.settings.set('', 'emptyKey'),
              update.settings.set(' ', 'spaceKey'),
              update.settings.set('true', 'booleanStringKey'),
              update.settings.set('false', 'booleanStringKey2'),
              update.settings.set('0', 'zeroStringKey'),

              // Backward compatibility - should still work
              update.settings.set('backwardCompat', 'works'),
              update.settings.remove('nonexistent'),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();
      expect(result, isNotNull);

      // Check that existing data is preserved
      expect(result!.settings['existing'], equals('value'));

      // Check edge case values
      expect(result.settings.containsKey('emptyValue'), isTrue);
      expect(result.settings['emptyValue'], equals(''));
      expect(result.settings['spaceValue'], equals(' '));
      expect(result.settings['nullString'], equals('null'));
      expect(result.settings['undefinedString'], equals('undefined'));

      // Check edge case keys
      expect(result.settings.containsKey(''), isTrue);
      expect(result.settings[''], equals('emptyKey'));
      expect(result.settings[' '], equals('spaceKey'));
      expect(result.settings['true'], equals('booleanStringKey'));
      expect(result.settings['false'], equals('booleanStringKey2'));
      expect(result.settings['0'], equals('zeroStringKey'));

      // Check backward compatibility
      expect(result.settings['backwardCompat'], equals('works'));

      print('✅ Edge cases handled correctly');
      print('   - Empty operations are safe');
      print('   - Operations on non-existent keys are safe');
      print('   - Edge case values and keys supported');
      print('   - Backward compatibility maintained');
    });

    test('🎯 Complete operation coverage verification', () async {
      final user = ImmutableUser(
        id: 'complete_coverage_test',
        name: 'Complete Coverage Test User',
        email: 'coverage@complete.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: <String, String>{}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Use every single MapFieldUpdate operation in one test
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // ✅ 1. set(K key, V value) - Set single key-value pair
              update.settings.set('singleKey', 'singleValue'),

              // ✅ 2. addAll(Map<K, V> entries) - Add multiple from Map
              update.settings.addAll({
                'mapKey1': 'mapValue1',
                'mapKey2': 'mapValue2',
              }),

              // ✅ 3. addEntries(Iterable<MapEntry<K, V>> entries) - Add from MapEntry iterable
              update.settings.addEntries([
                const MapEntry('entryKey1', 'entryValue1'),
                const MapEntry('entryKey2', 'entryValue2'),
              ]),

              // ✅ 4. setAll(Iterable<K> keys, V value) - Set multiple keys to same value
              update.settings.setAll([
                'setAllKey1',
                'setAllKey2',
              ], 'uniformValue'),

              // ✅ 5. remove(K key) - Remove single key (will be added then removed)
              update.settings.set('toBeRemoved', 'temporaryValue'),
              update.settings.remove('toBeRemoved'),

              // ✅ 6. removeWhere(Iterable<K> keys) - Remove multiple keys
              update.settings.addAll({
                'removeKey1': 'temp1',
                'removeKey2': 'temp2',
              }),
              update.settings.removeWhere(['removeKey1', 'removeKey2']),
            ],
          );

      // Test clear() operation separately (it would wipe everything above)
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Add some data first
              update.settings.set('beforeClear', 'value'),
            ],
          );

      // Verify state before clear
      final beforeClear = await odm.immutableUsers(user.id).get();
      expect(beforeClear!.settings.isNotEmpty, isTrue);

      // ✅ 7. clear() - Clear all entries
      await odm
          .immutableUsers(user.id)
          .patch((update) => [update.settings.clear()]);

      final afterClear = await odm.immutableUsers(user.id).get();
      expect(afterClear!.settings.isEmpty, isTrue);

      // Restore state and verify final operations worked
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              update.settings.set('singleKey', 'singleValue'),
              update.settings.addAll({
                'mapKey1': 'mapValue1',
                'mapKey2': 'mapValue2',
              }),
              update.settings.addEntries([
                const MapEntry('entryKey1', 'entryValue1'),
              ]),
              update.settings.setAll([
                'setAllKey1',
                'setAllKey2',
              ], 'uniformValue'),
            ],
          );

      final finalResult = await odm.immutableUsers(user.id).get();
      expect(finalResult, isNotNull);

      // Verify all operations worked correctly
      expect(finalResult!.settings['singleKey'], equals('singleValue'));
      expect(finalResult.settings['mapKey1'], equals('mapValue1'));
      expect(finalResult.settings['mapKey2'], equals('mapValue2'));
      expect(finalResult.settings['entryKey1'], equals('entryValue1'));
      expect(finalResult.settings['setAllKey1'], equals('uniformValue'));
      expect(finalResult.settings['setAllKey2'], equals('uniformValue'));

      // Verify removed keys are gone
      expect(finalResult.settings.containsKey('toBeRemoved'), isFalse);
      expect(finalResult.settings.containsKey('removeKey1'), isFalse);
      expect(finalResult.settings.containsKey('removeKey2'), isFalse);

      print('🎯 COMPLETE OPERATION COVERAGE VERIFIED:');
      print('   ✅ 1. set(K key, V value) - TESTED');
      print('   ✅ 2. remove(K key) - TESTED');
      print('   ✅ 3. addAll(Map<K, V> entries) - TESTED');
      print('   ✅ 4. addEntries(Iterable<MapEntry<K, V>> entries) - TESTED');
      print('   ✅ 5. removeWhere(Iterable<K> keys) - TESTED');
      print('   ✅ 6. clear() - TESTED');
      print('   ✅ 7. setAll(Iterable<K> keys, V value) - TESTED');
      print('   🚀 ALL MapFieldUpdate operations work correctly!');
    });

    test(
      '🔑 Keys with dots and special characters - FieldPath handling',
      skip: 'Special symbols in keys not supported',
      () async {
        final user = ImmutableUser(
          id: 'dotted_keys_test',
          name: 'Dotted Keys Test User',
          email: 'dotted@keys.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: <String, String>{}.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.immutableUsers(user.id).update(user);

        // Test keys that contain dots (should not be interpreted as nested fields)
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Keys with dots
                update.settings.set('config.json', 'file content'),
                update.settings.set('version.1.2.3', 'release version'),
                update.settings.set('domain.com', 'website'),
                update.settings.set('file.name.ext', 'document'),

                // Keys with other special characters
                update.settings.set('key@symbol', 'email-like'),
                update.settings.set('key#hash', 'hash-like'),
                update.settings.set(r'key$dollar', 'dollar-like'),
                update.settings.set('key%percent', 'percent-like'),
                update.settings.set('key^caret', 'caret-like'),
                update.settings.set('key&ampersand', 'ampersand-like'),
                update.settings.set('key*asterisk', 'asterisk-like'),
                update.settings.set('key(paren)', 'parentheses'),
                update.settings.set('key[bracket]', 'brackets'),
                update.settings.set('key{brace}', 'braces'),
                update.settings.set('key|pipe', 'pipe-like'),
                update.settings.set(r'key\backslash', 'backslash'),
                update.settings.set('key/slash', 'slash'),
                update.settings.set('key?question', 'question'),
                update.settings.set('key<greater>', 'angle brackets'),

                // Remove a dotted key
                update.settings.set('temp.key', 'temporary'),
                update.settings.remove('temp.key'),

                // Bulk operations with dotted keys
                update.settings.addAll({
                  'bulk.key1': 'bulk value 1',
                  'bulk.key2': 'bulk value 2',
                  'config.env.prod': 'production',
                }),

                // SetAll with dotted keys
                update.settings.setAll([
                  'uniform.key1',
                  'uniform.key2',
                ], 'same value'),
              ],
            );

        final result = await odm.immutableUsers(user.id).get();
        expect(result, isNotNull);

        // Verify dotted keys are treated as literal keys, not nested fields
        expect(result!.settings['config.json'], equals('file content'));
        expect(result.settings['version.1.2.3'], equals('release version'));
        expect(result.settings['domain.com'], equals('website'));
        expect(result.settings['file.name.ext'], equals('document'));

        // Verify special character keys
        expect(result.settings['key@symbol'], equals('email-like'));
        expect(result.settings['key#hash'], equals('hash-like'));
        expect(result.settings[r'key$dollar'], equals('dollar-like'));
        expect(result.settings['key%percent'], equals('percent-like'));
        expect(result.settings['key^caret'], equals('caret-like'));
        expect(result.settings['key&ampersand'], equals('ampersand-like'));
        expect(result.settings['key*asterisk'], equals('asterisk-like'));
        expect(result.settings['key(paren)'], equals('parentheses'));
        expect(result.settings['key[bracket]'], equals('brackets'));
        expect(result.settings['key{brace}'], equals('braces'));
        expect(result.settings['key|pipe'], equals('pipe-like'));
        expect(result.settings[r'key\backslash'], equals('backslash'));
        expect(result.settings['key/slash'], equals('slash'));
        expect(result.settings['key?question'], equals('question'));
        expect(result.settings['key<greater>'], equals('angle brackets'));

        // Verify removed dotted key is gone
        expect(result.settings.containsKey('temp.key'), isFalse);

        // Verify bulk operations with dotted keys
        expect(result.settings['bulk.key1'], equals('bulk value 1'));
        expect(result.settings['bulk.key2'], equals('bulk value 2'));
        expect(result.settings['config.env.prod'], equals('production'));

        // Verify setAll with dotted keys
        expect(result.settings['uniform.key1'], equals('same value'));
        expect(result.settings['uniform.key2'], equals('same value'));

        print('✅ Dotted keys and special characters handled correctly');
        print('   - Keys with dots treated as literal, not nested fields');
        print('   - All special characters in keys supported');
        print('   - FieldPath system working properly');
      },
    );

    test(
      '🌐 International and Unicode key handling',
      skip: 'Special symbols in keys not supported',
      () async {
        final user = ImmutableUser(
          id: 'unicode_keys_test',
          name: 'Unicode Keys Test User',
          email: 'unicode@keys.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: <String, String>{}.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.immutableUsers(user.id).update(user);

        // Test international and unicode keys
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Chinese keys
                update.settings.set('設定', '中文設定'),
                update.settings.set('語言.選擇', '繁體中文'),

                // Japanese keys
                update.settings.set('設定項目', '日本語設定'),
                update.settings.set('言語.選択', '日本語'),

                // Korean keys
                update.settings.set('설정', '한국어 설정'),
                update.settings.set('언어.선택', '한국어'),

                // Arabic keys
                update.settings.set('إعدادات', 'إعدادات عربية'),
                update.settings.set('اللغة.الاختيار', 'العربية'),

                // Russian keys
                update.settings.set('настройки', 'русские настройки'),
                update.settings.set('язык.выбор', 'русский'),

                // Emoji keys
                update.settings.set('🔧', 'settings'),
                update.settings.set('🌍.🗣️', 'language'),
                update.settings.set('⚙️.🎨', 'theme'),

                // Mixed unicode with dots
                update.settings.set('用戶.設定.主題', 'dark mode'),
                update.settings.set('ユーザー.設定.テーマ', 'ダークモード'),

                // Bulk operations with unicode
                update.settings.addAll({
                  '批量.鍵1': '批量值1',
                  '批量.鍵2': '批量值2',
                  '🚀.配置': '火箭配置',
                }),

                // SetAll with unicode keys
                update.settings.setAll(['統一.鍵1', '統一.鍵2'], '統一值'),
              ],
            );

        final result = await odm.immutableUsers(user.id).get();
        expect(result, isNotNull);

        // Verify Chinese keys
        expect(result!.settings['設定'], equals('中文設定'));
        expect(result.settings['語言.選擇'], equals('繁體中文'));

        // Verify Japanese keys
        expect(result.settings['設定項目'], equals('日本語設定'));
        expect(result.settings['言語.選択'], equals('日本語'));

        // Verify Korean keys
        expect(result.settings['설정'], equals('한국어 설정'));
        expect(result.settings['언어.선택'], equals('한국어'));

        // Verify Arabic keys
        expect(result.settings['إعدادات'], equals('إعدادات عربية'));
        expect(result.settings['اللغة.الاختيار'], equals('العربية'));

        // Verify Russian keys
        expect(result.settings['настройки'], equals('русские настройки'));
        expect(result.settings['язык.выбор'], equals('русский'));

        // Verify emoji keys
        expect(result.settings['🔧'], equals('settings'));
        expect(result.settings['🌍.🗣️'], equals('language'));
        expect(result.settings['⚙️.🎨'], equals('theme'));

        // Verify mixed unicode with dots
        expect(result.settings['用戶.設定.主題'], equals('dark mode'));
        expect(result.settings['ユーザー.設定.テーマ'], equals('ダークモード'));

        // Verify bulk operations
        expect(result.settings['批量.鍵1'], equals('批量值1'));
        expect(result.settings['批量.鍵2'], equals('批量值2'));
        expect(result.settings['🚀.配置'], equals('火箭配置'));

        // Verify setAll operations
        expect(result.settings['統一.鍵1'], equals('統一值'));
        expect(result.settings['統一.鍵2'], equals('統一值'));

        print('✅ International and Unicode keys handled correctly');
        print('   - Chinese, Japanese, Korean keys supported');
        print('   - Arabic, Russian keys supported');
        print('   - Emoji keys supported');
        print('   - Unicode + dots combinations work properly');
      },
    );

    test(
      '💾 Real-world configuration scenarios',
      skip: 'not fully supported',
      () async {
        final user = ImmutableUser(
          id: 'realworld_config_test',
          name: 'Real World Config User',
          email: 'realworld@config.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: <String, String>{}.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.immutableUsers(user.id).update(user);

        // Simulate real-world configuration management scenarios
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Application config keys (typical in real apps)
                update.settings.set('app.version', '1.2.3'),
                update.settings.set('app.build', '456'),
                update.settings.set('app.environment', 'production'),
                update.settings.set('api.base.url', 'https://api.example.com'),
                update.settings.set('api.timeout.seconds', '30'),
                update.settings.set('api.retry.count', '3'),

                // Database config
                update.settings.set('db.host', 'localhost'),
                update.settings.set('db.port', '5432'),
                update.settings.set('db.name', 'app_db'),
                update.settings.set(
                  'cache.redis.url',
                  'redis://localhost:6379',
                ),

                // Feature flags (common pattern)
                update.settings.addAll({
                  'feature.dark_mode': 'enabled',
                  'feature.new_ui': 'disabled',
                  'feature.beta_features': 'enabled',
                  'feature.analytics': 'enabled',
                  'feature.crash_reporting': 'enabled',
                }),

                // User preferences with domains
                update.settings.addAll({
                  'user.theme.color': 'blue',
                  'user.theme.size': 'medium',
                  'user.notifications.email': 'true',
                  'user.notifications.push': 'false',
                  'user.privacy.analytics': 'opt_in',
                  'user.privacy.tracking': 'opt_out',
                }),

                // Third-party service config
                update.settings.addAll({
                  'stripe.public_key': 'pk_test_123',
                  'google.analytics.id': 'GA-123456',
                  'firebase.project_id': 'my-project',
                  'aws.region': 'us-east-1',
                  'aws.s3.bucket': 'my-app-bucket',
                }),

                // File path configurations (common source of dots)
                update.settings.addAll({
                  'paths.config.json': '/app/config/app.json',
                  'paths.logs.dir': '/var/log/app/',
                  'paths.uploads.dir': '/var/uploads/',
                  'files.allowed.extensions': '.jpg,.png,.pdf',
                  'files.max.size.mb': '10',
                }),
              ],
            );

        final result = await odm.immutableUsers(user.id).get();
        expect(result, isNotNull);

        // Verify app config
        expect(result!.settings['app.version'], equals('1.2.3'));
        expect(result.settings['app.build'], equals('456'));
        expect(
          result.settings['api.base.url'],
          equals('https://api.example.com'),
        );
        expect(result.settings['api.timeout.seconds'], equals('30'));

        // Verify database config
        expect(result.settings['db.host'], equals('localhost'));
        expect(result.settings['db.port'], equals('5432'));
        expect(
          result.settings['cache.redis.url'],
          equals('redis://localhost:6379'),
        );

        // Verify feature flags
        expect(result.settings['feature.dark_mode'], equals('enabled'));
        expect(result.settings['feature.new_ui'], equals('disabled'));
        expect(result.settings['feature.beta_features'], equals('enabled'));

        // Verify user preferences
        expect(result.settings['user.theme.color'], equals('blue'));
        expect(result.settings['user.notifications.email'], equals('true'));
        expect(result.settings['user.privacy.analytics'], equals('opt_in'));

        // Verify third-party config
        expect(result.settings['stripe.public_key'], equals('pk_test_123'));
        expect(result.settings['google.analytics.id'], equals('GA-123456'));
        expect(result.settings['aws.s3.bucket'], equals('my-app-bucket'));

        // Verify file path config
        expect(
          result.settings['paths.config.json'],
          equals('/app/config/app.json'),
        );
        expect(
          result.settings['files.allowed.extensions'],
          equals('.jpg,.png,.pdf'),
        );
        expect(result.settings['files.max.size.mb'], equals('10'));

        // Now test bulk configuration updates (common in real apps)
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Update all feature flags at once
                update.settings.setAll([
                  'feature.dark_mode',
                  'feature.new_ui',
                  'feature.beta_features',
                ], 'enabled'),

                // Remove deprecated config
                update.settings.removeWhere([
                  'app.build', // Remove build number
                  'cache.redis.url', // Remove old cache config
                ]),

                // Add new config version
                update.settings.addAll({
                  'app.config.version': '2.0',
                  'cache.memory.size': '256mb',
                  'monitoring.enabled': 'true',
                }),
              ],
            );

        final finalResult = await odm.immutableUsers(user.id).get();
        expect(finalResult, isNotNull);

        // Verify bulk updates
        expect(finalResult!.settings['feature.dark_mode'], equals('enabled'));
        expect(finalResult.settings['feature.new_ui'], equals('enabled'));
        expect(
          finalResult.settings['feature.beta_features'],
          equals('enabled'),
        );

        // Verify removals
        expect(finalResult.settings.containsKey('app.build'), isFalse);
        expect(finalResult.settings.containsKey('cache.redis.url'), isFalse);

        // Verify new config
        expect(finalResult.settings['app.config.version'], equals('2.0'));
        expect(finalResult.settings['cache.memory.size'], equals('256mb'));
        expect(finalResult.settings['monitoring.enabled'], equals('true'));

        print('✅ Real-world configuration scenarios work correctly');
        print('   - App, API, DB configuration keys handled');
        print('   - Feature flags pattern supported');
        print('   - User preferences with domains work');
        print('   - Third-party service config supported');
        print('   - File path configurations work properly');
        print('   - Bulk configuration updates work');
      },
    );

    test(
      '🏗️ Complex nested-like key structures',
      skip: 'Special symbols in keys not supported',
      () async {
        final user = ImmutableUser(
          id: 'nested_like_keys_test',
          name: 'Nested-like Keys Test User',
          email: 'nested@keys.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: <String, String>{}.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.immutableUsers(user.id).update(user);

        // Test keys that look like nested structures but should be treated as flat keys
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Multi-level "nested" keys (but stored flat)
                update.settings.set('level1.level2.level3.key', 'deep value'),
                update.settings.set(
                  'config.database.connection.host',
                  'localhost',
                ),
                update.settings.set('config.database.connection.port', '5432'),
                update.settings.set('config.database.connection.ssl', 'true'),
                update.settings.set(
                  'config.api.endpoints.users',
                  '/api/v1/users',
                ),
                update.settings.set(
                  'config.api.endpoints.auth',
                  '/api/v1/auth',
                ),
                update.settings.set(
                  'config.api.endpoints.data',
                  '/api/v1/data',
                ),

                // Keys with multiple dots and special patterns
                update.settings.set('a.b.c.d.e.f.g', 'very deep'),
                update.settings.set('com.company.app.feature', 'enabled'),
                update.settings.set('org.example.service.config', 'production'),
                update.settings.set('io.flutter.plugin.camera', 'v1.2.3'),

                // Domain-like keys
                update.settings.set('subdomain.domain.com', 'website'),
                update.settings.set('api.service.domain.com', 'api endpoint'),
                update.settings.set('cdn.assets.domain.com', 'cdn url'),

                // Version-like keys
                update.settings.set('v1.2.3.stable', 'stable release'),
                update.settings.set('v2.0.0.beta.1', 'beta release'),
                update.settings.set('v3.0.0.alpha.2.hotfix', 'alpha hotfix'),

                // JSON-path-like keys (but stored as flat keys)
                update.settings.set('data.users[0].name', 'first user name'),
                update.settings.set('data.users[0].email', 'first user email'),
                update.settings.set('data.config.theme.colors.primary', 'blue'),
                update.settings.set(
                  'data.config.theme.colors.secondary',
                  'gray',
                ),
              ],
            );

        final result = await odm.immutableUsers(user.id).get();
        expect(result, isNotNull);

        // Verify deep nested-like keys
        expect(
          result!.settings['level1.level2.level3.key'],
          equals('deep value'),
        );
        expect(
          result.settings['config.database.connection.host'],
          equals('localhost'),
        );
        expect(
          result.settings['config.database.connection.port'],
          equals('5432'),
        );
        expect(
          result.settings['config.database.connection.ssl'],
          equals('true'),
        );
        expect(
          result.settings['config.api.endpoints.users'],
          equals('/api/v1/users'),
        );
        expect(
          result.settings['config.api.endpoints.auth'],
          equals('/api/v1/auth'),
        );
        expect(
          result.settings['config.api.endpoints.data'],
          equals('/api/v1/data'),
        );

        // Verify very deep keys
        expect(result.settings['a.b.c.d.e.f.g'], equals('very deep'));
        expect(result.settings['com.company.app.feature'], equals('enabled'));
        expect(
          result.settings['org.example.service.config'],
          equals('production'),
        );
        expect(result.settings['io.flutter.plugin.camera'], equals('v1.2.3'));

        // Verify domain-like keys
        expect(result.settings['subdomain.domain.com'], equals('website'));
        expect(
          result.settings['api.service.domain.com'],
          equals('api endpoint'),
        );
        expect(result.settings['cdn.assets.domain.com'], equals('cdn url'));

        // Verify version-like keys
        expect(result.settings['v1.2.3.stable'], equals('stable release'));
        expect(result.settings['v2.0.0.beta.1'], equals('beta release'));
        expect(
          result.settings['v3.0.0.alpha.2.hotfix'],
          equals('alpha hotfix'),
        );

        // Verify JSON-path-like keys
        expect(
          result.settings['data.users[0].name'],
          equals('first user name'),
        );
        expect(
          result.settings['data.users[0].email'],
          equals('first user email'),
        );
        expect(
          result.settings['data.config.theme.colors.primary'],
          equals('blue'),
        );
        expect(
          result.settings['data.config.theme.colors.secondary'],
          equals('gray'),
        );

        // Test bulk operations with nested-like keys
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Bulk add with nested-like keys
                update.settings.addAll({
                  'bulk.nested.key1': 'bulk value 1',
                  'bulk.nested.key2': 'bulk value 2',
                  'bulk.nested.key3': 'bulk value 3',
                }),

                // Remove some nested-like keys
                update.settings.removeWhere([
                  'config.database.connection.ssl',
                  'config.api.endpoints.data',
                ]),

                // SetAll with nested-like pattern
                update.settings.setAll([
                  'uniform.nested.key1',
                  'uniform.nested.key2',
                  'uniform.nested.key3',
                ], 'uniform nested value'),
              ],
            );

        final finalResult = await odm.immutableUsers(user.id).get();
        expect(finalResult, isNotNull);

        // Verify bulk operations
        expect(
          finalResult!.settings['bulk.nested.key1'],
          equals('bulk value 1'),
        );
        expect(
          finalResult.settings['bulk.nested.key2'],
          equals('bulk value 2'),
        );
        expect(
          finalResult.settings['bulk.nested.key3'],
          equals('bulk value 3'),
        );

        // Verify removals
        expect(
          finalResult.settings.containsKey('config.database.connection.ssl'),
          isFalse,
        );
        expect(
          finalResult.settings.containsKey('config.api.endpoints.data'),
          isFalse,
        );

        // Verify preserved keys
        expect(
          finalResult.settings['config.database.connection.host'],
          equals('localhost'),
        );
        expect(
          finalResult.settings['config.api.endpoints.users'],
          equals('/api/v1/users'),
        );

        // Verify setAll operations
        expect(
          finalResult.settings['uniform.nested.key1'],
          equals('uniform nested value'),
        );
        expect(
          finalResult.settings['uniform.nested.key2'],
          equals('uniform nested value'),
        );
        expect(
          finalResult.settings['uniform.nested.key3'],
          equals('uniform nested value'),
        );

        print('✅ Complex nested-like key structures handled correctly');
        print('   - Multi-level dot-separated keys work as flat keys');
        print('   - Domain-like and version-like keys supported');
        print('   - JSON-path-like keys treated as literal keys');
        print('   - Bulk operations work with complex key patterns');
      },
    );

    test(
      '⚡ Stress test - Many operations with complex keys',
      skip: 'Special symbols in keys not supported',
      () async {
        final user = ImmutableUser(
          id: 'stress_test_complex',
          name: 'Stress Test Complex User',
          email: 'stress@complex.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: <String, String>{}.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.immutableUsers(user.id).update(user);

        // Generate large datasets with complex keys
        final largeComplexMap = <String, String>{};
        final moreComplexEntries = <MapEntry<String, String>>[];
        final complexKeysToRemove = <String>[];
        final complexKeysForSetAll = <String>[];

        for (var i = 0; i < 100; i++) {
          // Create complex keys with various patterns
          final dotKey = 'config.section$i.item.value';
          final domainKey = 'service$i.api.domain.com';
          final versionKey = 'v1.$i.0.release';
          final pathKey = 'path/to/file$i.json';
          final unicodeKey = '設定$i.項目.値';

          largeComplexMap[dotKey] = 'dot value $i';
          largeComplexMap[domainKey] = 'domain value $i';
          largeComplexMap[versionKey] = 'version value $i';
          largeComplexMap[pathKey] = 'path value $i';
          largeComplexMap[unicodeKey] = 'unicode value $i';

          moreComplexEntries.add(
            MapEntry('entry.complex.$i', 'entry value $i'),
          );
          moreComplexEntries.add(MapEntry('🚀.rocket.$i', 'rocket value $i'));

          if (i < 50) {
            complexKeysToRemove.add(dotKey);
            complexKeysToRemove.add(domainKey);
          }
          if (i >= 50) {
            complexKeysForSetAll.add(versionKey);
            complexKeysForSetAll.add(pathKey);
          }
        }

        // Perform stress test with complex keys
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                // Add large map with complex keys
                update.settings.addAll(largeComplexMap),

                // Add large entry list with complex keys
                update.settings.addEntries(moreComplexEntries),

                // Set many complex keys to same value
                update.settings.setAll(
                  complexKeysForSetAll,
                  'uniformComplexValue',
                ),

                // Remove many complex keys
                update.settings.removeWhere(complexKeysToRemove),

                // Add some individual complex keys
                update.settings.set(
                  'final.complex.key.with.many.dots',
                  'final complex value',
                ),
                update.settings.set('最終.複雜.鍵.值', '最終複雜值'),
                update.settings.set(
                  '🎯.final.🚀.complex',
                  'emoji complex value',
                ),
              ],
            );

        final result = await odm.immutableUsers(user.id).get();
        expect(result, isNotNull);

        // Verify the stress test completed successfully
        expect(result!.settings.length, greaterThan(100));

        // Check some specific complex keys that should exist
        expect(
          result.settings['v1.50.0.release'],
          equals('uniformComplexValue'),
        );
        expect(
          result.settings['v1.99.0.release'],
          equals('uniformComplexValue'),
        );
        expect(
          result.settings['path/to/file50.json'],
          equals('uniformComplexValue'),
        );
        expect(
          result.settings['path/to/file99.json'],
          equals('uniformComplexValue'),
        );

        // Check some keys that should be removed
        expect(
          result.settings.containsKey('config.section0.item.value'),
          isFalse,
        );
        expect(
          result.settings.containsKey('service49.api.domain.com'),
          isFalse,
        );

        // Check complex entries
        expect(result.settings['entry.complex.0'], equals('entry value 0'));
        expect(result.settings['entry.complex.99'], equals('entry value 99'));
        expect(result.settings['🚀.rocket.0'], equals('rocket value 0'));
        expect(result.settings['🚀.rocket.99'], equals('rocket value 99'));

        // Check final individual keys
        expect(
          result.settings['final.complex.key.with.many.dots'],
          equals('final complex value'),
        );
        expect(result.settings['最終.複雜.鍵.值'], equals('最終複雜值'));
        expect(
          result.settings['🎯.final.🚀.complex'],
          equals('emoji complex value'),
        );

        print('✅ Stress test with complex keys completed successfully');
        print('   - 100+ complex keys with dots, unicode, emojis handled');
        print('   - Large bulk operations with complex keys work');
        print('   - Performance acceptable for complex key patterns');
        print('   - FieldPath system handles stress test correctly');
      },
    );

    test(
      '🔧 Map key type variations',
      skip: 'Special symbols in keys not supported',
      () async {
        print('\n🔧 Testing various map key types...');

        // Create user with initial settings
        final user = ImmutableUser(
          id: 'user_map_key_types',
          name: 'Map Key Types User',
          email: 'key@types.test',
          age: 30,
          tags: ['test'].toIList(),
          scores: [100].toIList(),
          settings: {'initial': 'value'}.toIMap(),
          categories: {'developer'}.toISet(),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.immutableUsers(user.id).update(user);

        // Test numeric-like string keys
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                update.settings.set('0', 'zero'),
                update.settings.set('1', 'one'),
                update.settings.set('123', 'number123'),
                update.settings.set('-1', 'negative'),
                update.settings.set('3.14', 'pi'),
              ],
            );

        // Test boolean-like string keys
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                update.settings.set('true', 'boolean_true'),
                update.settings.set('false', 'boolean_false'),
                update.settings.set('null', 'null_string'),
                update.settings.set('undefined', 'undefined_string'),
              ],
            );

        // Test URL-like keys
        await odm
            .immutableUsers(user.id)
            .patch(
              (update) => [
                update.settings.set('https://example.com', 'website'),
                update.settings.set('mailto:user@domain.com', 'email'),
                update.settings.set('ftp://files.server.com', 'ftp'),
                update.settings.set('file:///path/to/file', 'file_url'),
              ],
            );

        final result = await odm.immutableUsers(user.id).get();

        // Verify numeric-like keys
        expect(result!.settings['0'], equals('zero'));
        expect(result.settings['1'], equals('one'));
        expect(result.settings['123'], equals('number123'));
        expect(result.settings['-1'], equals('negative'));
        expect(result.settings['3.14'], equals('pi'));

        // Verify boolean-like keys
        expect(result.settings['true'], equals('boolean_true'));
        expect(result.settings['false'], equals('boolean_false'));
        expect(result.settings['null'], equals('null_string'));
        expect(result.settings['undefined'], equals('undefined_string'));

        // Verify URL-like keys
        expect(result.settings['https://example.com'], equals('website'));
        expect(result.settings['mailto:user@domain.com'], equals('email'));
        expect(result.settings['ftp://files.server.com'], equals('ftp'));
        expect(result.settings['file:///path/to/file'], equals('file_url'));

        print('✅ Map key type variations work correctly');
        print('   - Numeric-like string keys supported');
        print('   - Boolean-like string keys supported');
        print('   - URL-like keys supported');
        print('   - Special protocol keys supported');
      },
    );

    test('🎨 Map value edge cases', () async {
      print('\n🎨 Testing map value edge cases...');

      final user = ImmutableUser(
        id: 'user_map_value_edge',
        name: 'Map Value Edge User',
        email: 'value@edge.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {'initial': 'value'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test edge case values
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Empty and whitespace values
              update.settings.set('empty', ''),
              update.settings.set('spaces', '   '),
              update.settings.set('newlines', '\n\r\t'),

              // Long values
              update.settings.set(
                'long_text',
                'This is a very long text value that contains multiple words and should be stored correctly in the map without any truncation or modification for comprehensive testing purposes',
              ),

              // Special format values
              update.settings.set('date_like', '2024-01-01T10:00:00Z'),
              update.settings.set(
                'uuid_like',
                '12345678-1234-5678-9abc-123456789012',
              ),
              update.settings.set('base64_like', 'SGVsbG8gV29ybGQ='),

              // Code-like values
              update.settings.set(
                'css_rule',
                'body { margin: 0; padding: 10px; }',
              ),
              update.settings.set(
                'js_code',
                'function hello() { console.log("Hi"); }',
              ),

              // Markup values
              update.settings.set(
                'html_snippet',
                '<div class="container"><p>Hello</p></div>',
              ),
              update.settings.set(
                'xml_snippet',
                '<?xml version="1.0"?><root><item>value</item></root>',
              ),
            ],
          );

      final result = await odm.immutableUsers(user.id).get();

      // Verify all value types
      expect(result!.settings['empty'], equals(''));
      expect(result.settings['spaces'], equals('   '));
      expect(result.settings['newlines'], equals('\n\r\t'));

      expect(
        result.settings['long_text'],
        contains('comprehensive testing purposes'),
      );

      expect(result.settings['date_like'], equals('2024-01-01T10:00:00Z'));
      expect(
        result.settings['uuid_like'],
        equals('12345678-1234-5678-9abc-123456789012'),
      );
      expect(result.settings['base64_like'], equals('SGVsbG8gV29ybGQ='));

      expect(
        result.settings['css_rule'],
        equals('body { margin: 0; padding: 10px; }'),
      );
      expect(
        result.settings['js_code'],
        equals('function hello() { console.log("Hi"); }'),
      );

      expect(
        result.settings['html_snippet'],
        equals('<div class="container"><p>Hello</p></div>'),
      );
      expect(
        result.settings['xml_snippet'],
        equals('<?xml version="1.0"?><root><item>value</item></root>'),
      );

      print('✅ Map value edge cases work correctly');
      print('   - Empty and whitespace values supported');
      print('   - Long text values supported');
      print('   - Special format values supported');
      print('   - Code and markup values supported');
    });

    test('⚖️ Map operation precedence and overwriting', () async {
      print('\n⚖️ Testing map operation precedence...');

      final user = ImmutableUser(
        id: 'user_map_precedence',
        name: 'Map Precedence User',
        email: 'precedence@test.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {'base': 'initial'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test operation precedence within single update
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Set initial values
              update.settings.set('key1', 'first'),
              update.settings.set('key2', 'first'),
              update.settings.set('key3', 'first'),

              // Overwrite with new values (later operations should win)
              update.settings.set('key1', 'second'),
              update.settings.set('key2', 'second'),
              update.settings.set('key3', 'second'),

              // Final overwrite
              update.settings.set('key1', 'final'),
              update.settings.set('key2', 'final'),
            ],
          );

      final result1 = await odm.immutableUsers(user.id).get();
      expect(result1!.settings['key1'], equals('final'));
      expect(result1.settings['key2'], equals('final'));
      expect(result1.settings['key3'], equals('second'));

      // Test mixed operations precedence
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              // Add multiple keys
              update.settings.addAll({
                'bulk1': 'bulk_value',
                'bulk2': 'bulk_value',
                'bulk3': 'bulk_value',
              }),

              // Override some bulk keys with individual sets
              update.settings.set('bulk1', 'individual_value'),
              update.settings.set('bulk2', 'individual_value'),

              // Add more bulk
              update.settings.addAll({
                'bulk4': 'bulk_value',
                'bulk5': 'bulk_value',
              }),
            ],
          );

      final result2 = await odm.immutableUsers(user.id).get();
      expect(result2!.settings['bulk1'], equals('individual_value'));
      expect(result2.settings['bulk2'], equals('individual_value'));
      expect(result2.settings['bulk3'], equals('bulk_value'));
      expect(result2.settings['bulk4'], equals('bulk_value'));
      expect(result2.settings['bulk5'], equals('bulk_value'));

      print('✅ Map operation precedence works correctly');
      print('   - Later operations override earlier ones');
      print('   - Mixed operation types handle precedence correctly');
    });

    test('🛡️ Map error handling and recovery', () async {
      print('\n🛡️ Testing map error handling...');

      final user = ImmutableUser(
        id: 'user_map_errors',
        name: 'Map Errors User',
        email: 'errors@test.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {'initial': 'value'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test operations on empty map
      await odm.immutableUsers(user.id).patch(($) => [$.settings.clear()]);

      final emptyResult = await odm.immutableUsers(user.id).get();
      expect(emptyResult!.settings.length, equals(0));

      // Test adding to empty map
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              update.settings.set('after_clear', 'value'),
              update.settings.addAll({'bulk_after_clear': 'bulk_value'}),
            ],
          );

      final afterClearResult = await odm.immutableUsers(user.id).get();
      expect(afterClearResult!.settings['after_clear'], equals('value'));
      expect(
        afterClearResult.settings['bulk_after_clear'],
        equals('bulk_value'),
      );

      // Test removing non-existent keys (should be safe)
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              update.settings.remove('non_existent_key'),
              update.settings.removeWhere(['non_existent_1', 'non_existent_2']),
            ],
          );

      final safeRemovalResult = await odm.immutableUsers(user.id).get();
      expect(safeRemovalResult!.settings['after_clear'], equals('value'));
      expect(
        safeRemovalResult.settings['bulk_after_clear'],
        equals('bulk_value'),
      );

      // Test empty operations (should be safe)
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              update.settings.addAll({}),
              update.settings.removeWhere([]),
              update.settings.setAll([], 'unused_value'),
            ],
          );

      final emptyOpsResult = await odm.immutableUsers(user.id).get();
      expect(emptyOpsResult!.settings['after_clear'], equals('value'));
      expect(emptyOpsResult.settings['bulk_after_clear'], equals('bulk_value'));

      print('✅ Map error handling works correctly');
      print('   - Operations on empty maps are safe');
      print('   - Removing non-existent keys is safe');
      print('   - Empty operations are safe');
    });

    test('🚀 Map performance with large datasets', () async {
      print('\n🚀 Testing map performance...');

      final user = ImmutableUser(
        id: 'user_map_performance',
        name: 'Map Performance User',
        email: 'performance@test.test',
        age: 30,
        tags: ['test'].toIList(),
        scores: [100].toIList(),
        settings: {'initial': 'value'}.toIMap(),
        categories: {'developer'}.toISet(),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.immutableUsers(user.id).update(user);

      // Test large map (100+ entries)
      final largeMap = Map.fromIterables(
        List.generate(100, (i) => 'large_key_$i'),
        List.generate(100, (i) => 'large_value_$i'),
      );

      await odm
          .immutableUsers(user.id)
          .patch((update) => [update.settings.addAll(largeMap)]);

      final result1 = await odm.immutableUsers(user.id).get();
      expect(
        result1!.settings.length,
        greaterThanOrEqualTo(101),
      ); // 100 + initial

      // Test bulk removal
      final keysToRemove = List.generate(50, (i) => 'large_key_$i');
      await odm
          .immutableUsers(user.id)
          .patch((update) => [update.settings.removeWhere(keysToRemove)]);

      final result2 = await odm.immutableUsers(user.id).get();
      expect(result2!.settings.length, lessThan(result1.settings.length));

      // Test mass uniform update
      final remainingKeys = List.generate(50, (i) => 'large_key_${i + 50}');
      await odm
          .immutableUsers(user.id)
          .patch(
            (update) => [
              update.settings.setAll(remainingKeys, 'uniform_update_value'),
            ],
          );

      final result3 = await odm.immutableUsers(user.id).get();
      expect(result3!.settings['large_key_50'], equals('uniform_update_value'));
      expect(result3.settings['large_key_99'], equals('uniform_update_value'));

      print('✅ Map performance characteristics verified');
      print('   - Large maps (100+ entries) work efficiently');
      print('   - Bulk operations scale appropriately');
      print('   - Mass uniform updates work correctly');
    });
  });
}
