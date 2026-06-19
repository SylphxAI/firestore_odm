import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔀 Mixed Operations Priority Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test(
      'should demonstrate operation priority: set vs array operations',
      () async {
        // Create a test user with initial data
        const user = User(
          id: 'priority_test_user',
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

        print('🧪 Test: Array operations accumulate, set() would override');

        // Test array operations - they accumulate with existing values
        await odm
            .users('priority_test_user')
            .patch(
              ($) => [
                $.tags.add('from_add'), // Array operation
                $.tags.addAll([
                  'from_addAll1',
                  'from_addAll2',
                ]), // Array operation
                // Note: If we used $.tags(['completely', 'new', 'array']) here,
                // it would override all array operations and set the field directly
              ],
            );

        final result1 = await odm.users('priority_test_user').get();
        print('📊 Result after array operations:');
        print(
          '   Expected: [initial, existing, from_add, from_addAll1, from_addAll2]',
        );
        print('   Actual: ${result1!.tags}');

        // Array operations accumulate with existing values
        expect(
          result1.tags,
          containsAll([
            'initial',
            'existing',
            'from_add',
            'from_addAll1',
            'from_addAll2',
          ]),
        );

        print('✅ Array operations accumulate with existing values');

        // Now test set operation override
        await odm
            .users('priority_test_user')
            .patch(
              ($) => [
                $.tags([
                  'completely',
                  'new',
                  'array',
                ]), // Set operation - this overrides everything
              ],
            );

        final result2 = await odm.users('priority_test_user').get();
        print('📊 Result after set() operation:');
        print(
          '   Expected: [completely, new, array] (set overrides everything)',
        );
        print('   Actual: ${result2!.tags}');

        expect(result2.tags, equals(['completely', 'new', 'array']));

        print('✅ set() operation overrides all previous values');
      },
    );

    test('should demonstrate array operations accumulation', () async {
      // Create a test user
      const user = User(
        id: 'accumulation_test_user',
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

      print('🧪 Test: Multiple array operations accumulation');

      // Test multiple array operations on same field
      await odm
          .users('accumulation_test_user')
          .patch(
            ($) => [
              $.tags.add('single1'),
              $.tags.add('single2'),
              $.tags.addAll(['bulk1', 'bulk2']),
              $.tags.addAll(['bulk3', 'bulk4']),
              $.scores.add(40),
              $.scores.addAll([50, 60]),
            ],
          );

      final result2 = await odm.users('accumulation_test_user').get();
      print('📊 Result after multiple array operations:');
      print(
        '   Tags expected: [initial, single1, single2, bulk1, bulk2, bulk3, bulk4]',
      );
      print('   Tags actual: ${result2!.tags}');
      print('   Scores expected: [10, 20, 30, 40, 50, 60]');
      print('   Scores actual: ${result2.scores}');

      // All array operations should accumulate
      expect(
        result2.tags,
        containsAll([
          'initial',
          'single1',
          'single2',
          'bulk1',
          'bulk2',
          'bulk3',
          'bulk4',
        ]),
      );
      expect(result2.scores, containsAll([10, 20, 30, 40, 50, 60]));

      print('✅ Array operations accumulate correctly');
    });

    test('should demonstrate add/remove operations on different fields', () async {
      // Create a test user
      const user = User(
        id: 'different_fields_test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20, 30, 40, 50],
        tags: ['keep', 'existing'],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech', 'remove_this'],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      print('🧪 Test: Add/Remove operations on different fields');

      // Test add/remove operations on different fields (this works fine)
      await odm
          .users('different_fields_test_user')
          .patch(
            ($) => [
              $.tags.addAll(['new1', 'new2']), // Add to tags
              $.scores.removeAll([20, 40]), // Remove from scores
              $.profile.interests.add('music'), // Add to interests only
            ],
          );

      // Remove from interests in a separate patch operation
      await odm
          .users('different_fields_test_user')
          .patch(
            ($) => [
              $.profile.interests.remove(
                'remove_this',
              ), // Remove from interests in separate operation
            ],
          );

      final result3 = await odm.users('different_fields_test_user').get();
      print('📊 Result after add/remove on different fields:');
      print('   Tags: ${result3!.tags} (should have new1, new2 added)');
      print('   Scores: ${result3.scores} (should have 20, 40 removed)');
      print(
        '   Interests: ${result3.profile.interests} (should have music added, remove_this removed)',
      );

      expect(result3.tags, containsAll(['keep', 'existing', 'new1', 'new2']));
      expect(result3.scores, equals([10, 30, 50]));
      expect(result3.profile.interests, containsAll(['tech', 'music']));
      expect(result3.profile.interests, isNot(contains('remove_this')));

      print('✅ Add/Remove operations work correctly on different fields');

      print(
        '⚠️ Note: Cannot do both add and remove on SAME field in SAME patch operation',
      );
      print(
        '   This is a Firestore limitation - use separate patch() calls for same field',
      );
    });

    test('should demonstrate operation processing order', () async {
      // Create a test user
      const user = User(
        id: 'order_test_user',
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

      print('🧪 Test: Operation processing order');

      // Test the order of different operation types
      await odm
          .users('order_test_user')
          .patch(
            ($) => [
              $.age.increment(5), // Increment operation
              $.tags.add('array_op'), // Array operation
              $.name('Updated Name'), // Set operation
              $.profile.followers.increment(50), // Nested increment
              $.scores.addAll([200, 300]), // Array bulk operation
            ],
          );

      final result4 = await odm.users('order_test_user').get();
      print('📊 Result after mixed operation types:');
      print('   Age: ${result4!.age} (should be 30)');
      print('   Name: ${result4.name} (should be "Updated Name")');
      print('   Tags: ${result4.tags} (should contain "array_op")');
      print('   Followers: ${result4.profile.followers} (should be 150)');
      print('   Scores: ${result4.scores} (should contain 200, 300)');

      expect(result4.age, equals(30));
      expect(result4.name, equals('Updated Name'));
      expect(result4.tags, contains('array_op'));
      expect(result4.profile.followers, equals(150));
      expect(result4.scores, containsAll([100, 200, 300]));

      print('✅ All operation types work together correctly');
    });

    test('should show what happens with conflicting operations', () async {
      // Create a test user
      const user = User(
        id: 'conflict_test_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20, 30],
        tags: ['existing'],
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

      print('🧪 Test: Conflicting operations priority');

      // Test what happens with conflicting operations
      await odm
          .users('conflict_test_user')
          .patch(
            ($) => [
              $.age.increment(10), // Increment by 10
              $.age.increment(
                5,
              ), // Increment by 5 more (should accumulate to +15)
              $.tags.add('first'), // Add operations
              $.tags.addAll(['second', 'third']),
              // Note: We can't do $.age(50) here because that would override the increments
              // Note: We can't do $.tags(['override']) here because that would override the adds
            ],
          );

      final result5 = await odm.users('conflict_test_user').get();
      print('📊 Result after accumulating operations:');
      print('   Age: ${result5!.age} (should be 40: 25 + 10 + 5)');
      print(
        '   Tags: ${result5.tags} (should contain existing, first, second, third)',
      );

      expect(result5.age, equals(40)); // 25 + 10 + 5
      expect(
        result5.tags,
        containsAll(['existing', 'first', 'second', 'third']),
      );

      print('✅ Same operation types accumulate correctly');
    });
  });
}
