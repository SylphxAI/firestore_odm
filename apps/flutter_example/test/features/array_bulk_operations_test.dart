import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔧 Array Bulk Operations', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test('should add multiple elements to array using addAll', () async {
      // Create a test user with initial tags
      const user = User(
        id: 'addall_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20],
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

      // Test addAll operation
      await odm
          .users('addall_user')
          .patch(
            ($) => [
              $.tags.addAll(['new1', 'new2', 'new3']),
              $.scores.addAll([30, 40, 50]),
              $.profile.interests.addAll(['music', 'sports']),
            ],
          );

      // Verify the changes
      final updatedUser = await odm.users('addall_user').get();
      expect(updatedUser, isNotNull);
      expect(
        updatedUser!.tags,
        containsAll(['initial', 'existing', 'new1', 'new2', 'new3']),
      );
      expect(updatedUser.scores, containsAll([10, 20, 30, 40, 50]));
      expect(
        updatedUser.profile.interests,
        containsAll(['tech', 'music', 'sports']),
      );

      print('✅ addAll() operations work correctly');
    });

    test(
      'should remove multiple elements from array using removeAll',
      () async {
        // Create a test user with multiple tags and scores
        const user = User(
          id: 'removeall_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          scores: [10, 20, 30, 40, 50, 60],
          tags: ['tag1', 'tag2', 'tag3', 'tag4', 'tag5'],
          isActive: true,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'avatar.jpg',
            socialLinks: {'twitter': '@test'},
            interests: ['tech', 'music', 'sports', 'reading'],
            followers: 100,
          ),
        );

        await odm.users.insert(user);

        // Test removeAll operation
        await odm
            .users('removeall_user')
            .patch(
              ($) => [
                $.tags.removeAll(['tag2', 'tag4']),
                $.scores.removeAll([20, 40, 60]),
                $.profile.interests.removeAll(['music', 'reading']),
              ],
            );

        // Verify the changes
        final updatedUser = await odm.users('removeall_user').get();
        expect(updatedUser, isNotNull);
        expect(updatedUser!.tags, equals(['tag1', 'tag3', 'tag5']));
        expect(updatedUser.scores, equals([10, 30, 50]));
        expect(updatedUser.profile.interests, equals(['tech', 'sports']));

        print('✅ removeAll() operations work correctly');
      },
    );

    test(
      'should handle mixed addAll and removeAll operations on different fields',
      () async {
        // Create a test user
        const user = User(
          id: 'mixed_operations_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          scores: [10, 20, 30],
          tags: ['old1', 'old2', 'keep'],
          isActive: true,
          profile: Profile(
            bio: 'Test bio',
            avatar: 'avatar.jpg',
            socialLinks: {'twitter': '@test'},
            interests: ['tech', 'remove_me'],
            followers: 100,
          ),
        );

        await odm.users.insert(user);

        // Test mixed operations - first remove, then add (separate operations)
        await odm
            .users('mixed_operations_user')
            .patch(
              ($) => [
                $.tags.removeAll(['old1', 'old2']),
                $.scores.addAll([40, 50]),
                $.profile.interests.removeAll(['remove_me']),
              ],
            );

        await odm
            .users('mixed_operations_user')
            .patch(
              ($) => [
                $.tags.addAll(['new1', 'new2']),
                $.profile.interests.addAll(['music', 'sports']),
              ],
            );

        // Verify the changes
        final updatedUser = await odm.users('mixed_operations_user').get();
        expect(updatedUser, isNotNull);
        expect(updatedUser!.tags, containsAll(['keep', 'new1', 'new2']));
        expect(updatedUser.tags, isNot(contains('old1')));
        expect(updatedUser.tags, isNot(contains('old2')));
        expect(updatedUser.scores, containsAll([10, 20, 30, 40, 50]));
        expect(
          updatedUser.profile.interests,
          containsAll(['tech', 'music', 'sports']),
        );
        expect(updatedUser.profile.interests, isNot(contains('remove_me')));

        print('✅ Mixed addAll/removeAll operations work correctly');
      },
    );

    test(
      'should handle sequential addAll and removeAll on same field',
      () async {
        // Create a test user
        const user = User(
          id: 'sequential_operations_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          scores: [10, 20, 30],
          tags: ['keep1', 'remove1', 'remove2', 'keep2'],
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

        // Test sequential operations on same field (remove first, then add)
        await odm
            .users('sequential_operations_user')
            .patch(
              ($) => [
                $.tags.removeAll(['remove1', 'remove2']),
              ],
            );

        await odm
            .users('sequential_operations_user')
            .patch(
              ($) => [
                $.tags.addAll(['add1', 'add2']),
              ],
            );

        // Verify the changes
        final updatedUser = await odm.users('sequential_operations_user').get();
        expect(updatedUser, isNotNull);
        expect(
          updatedUser!.tags,
          containsAll(['keep1', 'keep2', 'add1', 'add2']),
        );
        expect(updatedUser.tags, isNot(contains('remove1')));
        expect(updatedUser.tags, isNot(contains('remove2')));

        print('✅ Sequential operations work correctly');
      },
    );

    test('should work with empty arrays', () async {
      // Create a test user with empty arrays
      const user = User(
        id: 'empty_arrays_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        tags: [],
        isActive: true,
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: [],
          followers: 100,
        ),
      );

      await odm.users.insert(user);

      // Test addAll on empty arrays
      await odm
          .users('empty_arrays_user')
          .patch(
            ($) => [
              $.tags.addAll(['first', 'second']),
              $.scores.addAll([100, 200]),
              $.profile.interests.addAll(['reading']),
            ],
          );

      // Verify the changes
      final updatedUser = await odm.users('empty_arrays_user').get();
      expect(updatedUser, isNotNull);
      expect(updatedUser!.tags, equals(['first', 'second']));
      expect(updatedUser.scores, equals([100, 200]));
      expect(updatedUser.profile.interests, equals(['reading']));

      print('✅ addAll() works correctly with empty arrays');
    });

    test('should handle addAll and removeAll with empty lists', () async {
      // Create a test user
      const user = User(
        id: 'empty_lists_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10, 20],
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

      // Test operations with empty lists (should be no-ops)
      await odm
          .users('empty_lists_user')
          .patch(($) => [$.tags.addAll([]), $.scores.removeAll([])]);

      // Verify no changes occurred
      final updatedUser = await odm.users('empty_lists_user').get();
      expect(updatedUser, isNotNull);
      expect(updatedUser!.tags, equals(['existing']));
      expect(updatedUser.scores, equals([10, 20]));

      print('✅ addAll/removeAll with empty lists work correctly');
    });

    test('should work in transactions', () async {
      // Create a test user
      const user = User(
        id: 'transaction_bulk_user',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        scores: [10],
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

      // Test bulk operations in transaction
      await odm.runTransaction((tx) async {
        tx
            .users('transaction_bulk_user')
            .patch(
              ($) => [
                $.tags.addAll(['tx1', 'tx2']),
                $.scores.addAll([20, 30]),
                $.profile.interests.addAll(['music']),
              ],
            );
      });

      // Verify the changes
      final updatedUser = await odm.users('transaction_bulk_user').get();
      expect(updatedUser, isNotNull);
      expect(updatedUser!.tags, containsAll(['initial', 'tx1', 'tx2']));
      expect(updatedUser.scores, containsAll([10, 20, 30]));
      expect(updatedUser.profile.interests, containsAll(['tech', 'music']));

      print('✅ Bulk operations work correctly in transactions');
    });

    test('should work in batch operations', () async {
      // Create test users
      const user1 = User(
        id: 'batch_bulk_user1',
        name: 'User 1',
        email: 'user1@example.com',
        age: 25,
        scores: [10],
        tags: ['user1'],
        isActive: true,
        profile: Profile(
          bio: 'Bio 1',
          avatar: 'avatar1.jpg',
          socialLinks: {'twitter': '@user1'},
          interests: ['tech'],
          followers: 50,
        ),
      );

      const user2 = User(
        id: 'batch_bulk_user2',
        name: 'User 2',
        email: 'user2@example.com',
        age: 30,
        scores: [20],
        tags: ['user2'],
        isActive: true,
        profile: Profile(
          bio: 'Bio 2',
          avatar: 'avatar2.jpg',
          socialLinks: {'twitter': '@user2'},
          interests: ['music'],
          followers: 75,
        ),
      );

      await odm.users.insert(user1);
      await odm.users.insert(user2);

      // Test bulk operations in batch
      await odm.runBatch((batch) {
        batch
            .users('batch_bulk_user1')
            .patch(
              ($) => [
                $.tags.addAll(['batch1', 'batch2']),
                $.scores.addAll([30, 40]),
              ],
            );

        batch
            .users('batch_bulk_user2')
            .patch(
              ($) => [
                $.tags.addAll(['batch3', 'batch4']),
                $.scores.addAll([50, 60]),
              ],
            );
      });

      // Verify the changes
      final updatedUser1 = await odm.users('batch_bulk_user1').get();
      final updatedUser2 = await odm.users('batch_bulk_user2').get();

      expect(updatedUser1, isNotNull);
      expect(updatedUser1!.tags, containsAll(['user1', 'batch1', 'batch2']));
      expect(updatedUser1.scores, containsAll([10, 30, 40]));

      expect(updatedUser2, isNotNull);
      expect(updatedUser2!.tags, containsAll(['user2', 'batch3', 'batch4']));
      expect(updatedUser2.scores, containsAll([20, 50, 60]));

      print('✅ Bulk operations work correctly in batch operations');
    });

    test('should work with query bulk operations', () async {
      // Create multiple test users
      final users = [
        const User(
          id: 'query_bulk_user1',
          name: 'User 1',
          email: 'user1@example.com',
          age: 25,
          scores: [10],
          tags: ['bulk_test'],
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
          id: 'query_bulk_user2',
          name: 'User 2',
          email: 'user2@example.com',
          age: 30,
          scores: [20],
          tags: ['bulk_test'],
          isActive: true,
          profile: Profile(
            bio: 'Bio 2',
            avatar: 'avatar2.jpg',
            socialLinks: {'twitter': '@user2'},
            interests: ['music'],
            followers: 75,
          ),
        ),
      ];

      for (final user in users) {
        await odm.users.insert(user);
      }

      // Test bulk operations on query results
      await odm.users
          .where(($) => $.tags(arrayContains: 'bulk_test'))
          .patch(
            ($) => [
              $.tags.addAll(['query_added1', 'query_added2']),
              $.scores.addAll([100, 200]),
            ],
          );

      // Verify the changes
      final updatedUsers = await odm.users
          .where(($) => $.tags(arrayContains: 'bulk_test'))
          .get();

      for (final user in updatedUsers) {
        expect(
          user.tags,
          containsAll(['bulk_test', 'query_added1', 'query_added2']),
        );
        expect(user.scores, contains(100));
        expect(user.scores, contains(200));
      }

      print('✅ Bulk operations work correctly with query operations');
    });
  });
}
