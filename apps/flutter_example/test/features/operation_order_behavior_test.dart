import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 Operation Order Behavior Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test('should test set() followed by array operations', () async {
      // Create a test user
      const user = User(
        id: 'set_then_array_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20, 30],
        tags: ['initial', 'existing'],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      print('🧪 Test: set() followed by array operations');
      print(
        r"   Code: $.tags(['completely', 'new']), $.tags.add('from_add'), $.tags.addAll(['from_addAll'])",
      );

      await odm
          .users('set_then_array_user')
          .patch(
            ($) => [
              $.tags(['completely', 'new']), // Set operation first
              $.tags.add('from_add'), // Array operation after
              $.tags.addAll(['from_addAll']), // Array operation after
            ],
          );

      final result = await odm.users('set_then_array_user').get();
      print('📊 Result: ${result!.tags}');
      print('   Actual behavior: Set operation OVERRIDES array operations');

      // Set operation overrides array operations!
      // When both set and array operations are present, set takes precedence
      expect(result.tags, equals(['completely', 'new']));

      print('✅ IMPORTANT: set() operation overrides array operations!');
    });

    test('should test set() with add() and remove() on same field', () async {
      // Create a test user
      const user = User(
        id: 'set_add_remove_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20, 30],
        tags: ['initial', 'existing'],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      print('🧪 Test: set() with add() and remove() on same field');
      print(
        r"   Code: $.tags(['completely', 'new']), $.tags.add('from_add'), $.tags.remove('new')",
      );

      try {
        await odm
            .users('set_add_remove_user')
            .patch(
              ($) => [
                $.tags(['completely', 'new']), // Set operation
                $.tags.add('from_add'), // Add operation
                $.tags.remove('new'), // Remove operation
              ],
            );

        final result = await odm.users('set_add_remove_user').get();
        print('📊 Result: ${result!.tags}');
        print(
          '   Expected: Set operation should override, but this might conflict',
        );

        // If it succeeds, set should win
        expect(result.tags, equals(['completely', 'new']));
        print('✅ set() operation overrides add/remove operations');
      } catch (e) {
        print('❌ Error occurred: $e');
        print(
          '   This is expected due to Firestore limitations with mixed array operations',
        );
        expect(
          e.toString(),
          contains('Cannot perform both arrayUnion and arrayRemove'),
        );
        print('✅ Correctly throws error for mixed array operations');
      }
    });

    test('should test set() with remove() of non-existent value', () async {
      // Create a test user
      const user = User(
        id: 'set_remove_nonexist_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20, 30],
        tags: ['initial', 'existing'],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      print('🧪 Test: set() with add() and remove() of non-existent value');
      print(
        r"   Code: $.tags(['completely', 'new']), $.tags.add('from_add'), $.tags.remove('non-exists')",
      );

      try {
        await odm
            .users('set_remove_nonexist_user')
            .patch(
              ($) => [
                $.tags(['completely', 'new']), // Set operation
                $.tags.add('from_add'), // Add operation
                $.tags.remove('non-exists'), // Remove non-existent value
              ],
            );

        final result = await odm.users('set_remove_nonexist_user').get();
        print('📊 Result: ${result!.tags}');
        print('   Expected: Set operation should override everything');

        // Set should win regardless of what we're trying to add/remove
        expect(result.tags, equals(['completely', 'new']));
        print(
          '✅ set() operation overrides add/remove operations (even with non-existent values)',
        );
      } catch (e) {
        print('❌ Error occurred: $e');
        print(
          '   This is expected due to Firestore limitations with mixed array operations',
        );
        expect(
          e.toString(),
          contains('Cannot perform both arrayUnion and arrayRemove'),
        );
        print('✅ Correctly throws error for mixed array operations');
      }
    });

    test('should test multiple set() operations on same field', () async {
      // Create a test user
      const user = User(
        id: 'multiple_set_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20, 30],
        tags: ['initial', 'existing'],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      print('🧪 Test: Multiple set() operations on same field');
      print(r"   Code: $.tags(['completely']), $.tags(['completely', 'new'])");

      await odm
          .users('multiple_set_user')
          .patch(
            ($) => [
              $.tags(['completely']), // First set operation
              $.tags(['completely', 'new']), // Second set operation
            ],
          );

      final result = await odm.users('multiple_set_user').get();
      print('📊 Result: ${result!.tags}');
      print('   Expected: Last set operation should win');

      // Last set operation should win
      expect(result.tags, equals(['completely', 'new']));

      print('✅ Last set() operation overrides previous set() operations');
    });

    test('should demonstrate the complete operation precedence', () async {
      // Create a test user
      const user = User(
        id: 'precedence_test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20, 30],
        tags: ['initial'],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      print('🧪 Test: Complete operation precedence demonstration');

      // Test 1: Array operations only (should accumulate)
      await odm
          .users('precedence_test_user')
          .patch(
            ($) => [
              $.tags.add('add1'),
              $.tags.addAll(['add2', 'add3']),
            ],
          );

      var result = await odm.users('precedence_test_user').get();
      print('📊 After array operations only: ${result!.tags}');
      expect(result.tags, containsAll(['initial', 'add1', 'add2', 'add3']));

      // Test 2: Array operations followed by set (set should win)
      await odm
          .users('precedence_test_user')
          .patch(
            ($) => [
              $.tags.add('should_be_ignored'),
              $.tags.addAll(['also_ignored']),
              $.tags(['set_wins']),
            ],
          );

      result = await odm.users('precedence_test_user').get();
      print('📊 After array + set operations: ${result!.tags}');
      expect(result.tags, equals(['set_wins']));

      // Test 3: Set followed by array operations (set should still win)
      await odm
          .users('precedence_test_user')
          .patch(
            ($) => [
              $.tags(['set_first']),
              $.tags.add('ignored_add'),
            ],
          );

      result = await odm.users('precedence_test_user').get();
      print('📊 After set + array operations: ${result!.tags}');
      expect(result.tags, equals(['set_first']));

      print('✅ Operation precedence: set() always wins over array operations');
    });

    test('should show processing order within operation types', () async {
      // Create a test user
      const user = User(
        id: 'processing_order_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [100],
        tags: ['start'],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      print('🧪 Test: Processing order within operation types');

      await odm
          .users('processing_order_user')
          .patch(
            ($) => [
              $.age.increment(10), // First increment
              $.tags.add('first_add'), // First array add
              $.age.increment(5), // Second increment (should accumulate)
              $.tags.addAll([
                'second',
                'third',
              ]), // Second array add (should accumulate)
              $.name('Final Name'), // Set operation
            ],
          );

      final result = await odm.users('processing_order_user').get();
      print('📊 Results:');
      print('   Age: ${result!.age} (should be 40: 25 + 10 + 5)');
      print('   Tags: ${result.tags} (should contain all added items)');
      print('   Name: ${result.name} (should be "Final Name")');

      expect(result.age, equals(40)); // 25 + 10 + 5
      expect(
        result.tags,
        containsAll(['start', 'first_add', 'second', 'third']),
      );
      expect(result.name, equals('Final Name'));

      print(
        '✅ Operations of same type accumulate, different types work independently',
      );
    });
  });
}
