import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔧 Modify with Atomic Parameter', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test('should use atomic operations by default (atomic: true)', () async {
      // Create a test user
      const user = User(
        id: 'atomic_default_user',
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

      // Test modify with default atomic behavior (should be true)
      await odm
          .users('atomic_default_user')
          .modify(
            (user) => user.copyWith(
              age: user.age + 5, // Should use FieldValue.increment(5)
              tags: [
                ...user.tags,
                'new',
              ], // Should use FieldValue.arrayUnion(['new'])
              profile: user.profile.copyWith(
                followers:
                    user.profile.followers + 10, // Should use atomic increment
              ),
            ),
          );

      // Verify the changes
      final updatedUser = await odm.users('atomic_default_user').get();
      expect(updatedUser!.age, 30);
      expect(updatedUser.tags, contains('new'));
      expect(updatedUser.profile.followers, 110);

      print('✅ modify() with default atomic behavior works correctly');
    });

    test('should use atomic operations when atomic: true', () async {
      // Create a test user
      const user = User(
        id: 'atomic_true_user',
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

      // Test modify with explicit atomic: true
      await odm
          .users('atomic_true_user')
          .modify(
            (user) => user.copyWith(
              age: user.age + 5, // Should use FieldValue.increment(5)
              tags: [
                ...user.tags,
                'explicit',
              ], // Should use FieldValue.arrayUnion(['explicit'])
              profile: user.profile.copyWith(
                followers:
                    user.profile.followers + 15, // Should use atomic increment
              ),
            ),
            atomic: true,
          );

      // Verify the changes
      final updatedUser = await odm.users('atomic_true_user').get();
      expect(updatedUser!.age, 30);
      expect(updatedUser.tags, contains('explicit'));
      expect(updatedUser.profile.followers, 115);

      print('✅ modify(atomic: true) works correctly');
    });

    test('should not use atomic operations when atomic: false', () async {
      // Create a test user
      const user = User(
        id: 'atomic_false_user',
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

      // Test modify with atomic: false
      await odm
          .users('atomic_false_user')
          .modify(
            (user) => user.copyWith(
              age:
                  user.age +
                  5, // Should use simple field update, not FieldValue.increment
              tags: [
                ...user.tags,
                'non_atomic',
              ], // Should use simple field update, not FieldValue.arrayUnion
              name: 'Updated Name', // Simple field update
            ),
            atomic: false,
          );

      // Verify the changes
      final updatedUser = await odm.users('atomic_false_user').get();
      expect(updatedUser!.age, 30);
      expect(updatedUser.tags, contains('non_atomic'));
      expect(updatedUser.name, 'Updated Name');

      print('✅ modify(atomic: false) works correctly');
    });

    test('should work with bulk operations on queries', () async {
      // Create multiple test users
      final users = [
        const User(
          id: 'bulk_user_1',
          name: 'User 1',
          email: 'user1@example.com',
          age: 20,
          scores: [10],
          tags: ['bulk'],
          isActive: true,
          profile: Profile(
            bio: 'Bio 1',
            avatar: 'avatar1.jpg',
            socialLinks: {'twitter': '@user1'},
            interests: ['tech'],
            followers: 50,
          ),
        ),
        const User(
          id: 'bulk_user_2',
          name: 'User 2',
          email: 'user2@example.com',
          age: 25,
          scores: [20],
          tags: ['bulk'],
          isActive: true,
          profile: Profile(
            bio: 'Bio 2',
            avatar: 'avatar2.jpg',
            socialLinks: {'twitter': '@user2'},
            interests: ['tech'],
            followers: 75,
          ),
        ),
      ];

      for (final user in users) {
        await odm.users.insert(user);
      }

      // Test bulk modify with atomic operations
      await odm.users
          .where(($) => $.tags(arrayContains: 'bulk'))
          .modify(
            (user) => user.copyWith(
              age: user.age + 1, // Should use atomic increment
              tags: [...user.tags, 'updated'], // Should use atomic array union
            ),
            atomic: true,
          );

      // Verify the changes
      final updatedUsers = await odm.users
          .where(($) => $.tags(arrayContains: 'bulk'))
          .get();

      for (final user in updatedUsers) {
        expect(user.tags, contains('updated'));
        expect(user.age, greaterThan(20)); // Should be incremented
      }

      print('✅ Bulk modify with atomic parameter works correctly');
    });

    test('should maintain backward compatibility with modify', () async {
      // Create a test user
      const user = User(
        id: 'backward_compat_user',
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

      // Test that modify still works (deprecated but functional)
      await odm
          .users('backward_compat_user')
          .modify(
            (user) => user.copyWith(
              age: user.age + 5, // Should use FieldValue.increment(5)
              tags: [
                ...user.tags,
                'backward',
              ], // Should use FieldValue.arrayUnion(['backward'])
            ),
          );

      // Verify the changes
      final updatedUser = await odm.users('backward_compat_user').get();
      expect(updatedUser!.age, 30);
      expect(updatedUser.tags, contains('backward'));

      print('✅ modify backward compatibility maintained');
    });

    test('should work in transactions with atomic parameter', () async {
      // Create a test user
      const user = User(
        id: 'tx_atomic_user',
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

      // Test modify in transaction with atomic parameter
      await odm.runTransaction((tx) async {
        await tx
            .users('tx_atomic_user')
            .modify(
              (user) => user.copyWith(
                age: user.age + 10, // Should use atomic increment
                tags: [
                  ...user.tags,
                  'transaction',
                ], // Should use atomic array union
              ),
              atomic: true,
            );
      });

      // Verify the changes
      final updatedUser = await odm.users('tx_atomic_user').get();
      expect(updatedUser!.age, 35);
      expect(updatedUser.tags, contains('transaction'));

      print('✅ Transaction modify with atomic parameter works correctly');
    });
  });
}
