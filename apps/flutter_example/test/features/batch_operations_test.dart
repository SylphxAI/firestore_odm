import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 Batch Operations Features', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📝 Basic Batch Operations', () {
      test('should perform batch insert operations', () async {
        final users = [
          User(
            id: 'batch_user_1',
            name: 'Batch User 1',
            email: 'batch1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'First batch user',
              avatar: 'batch1.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'batch_user_2',
            name: 'Batch User 2',
            email: 'batch2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Second batch user',
              avatar: 'batch2.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 150,
            ),
            rating: 3.5,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Perform batch insert
        await odm.runBatch((batch) {
          for (final user in users) {
            batch.users.insert(user);
          }
        });

        // Verify all users were created
        final allUsers = await odm.users
            .where(($) => $.id(whereIn: ['batch_user_1', 'batch_user_2']))
            .get();

        expect(allUsers.length, equals(2));
        expect(
          allUsers.map((u) => u.name),
          containsAll(['Batch User 1', 'Batch User 2']),
        );
      });

      test('should perform batch update operations', () async {
        // First create some users
        final users = [
          User(
            id: 'batch_update_1',
            name: 'Update User 1',
            email: 'update1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Original bio 1',
              avatar: 'update1.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 3,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'batch_update_2',
            name: 'Update User 2',
            email: 'update2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Original bio 2',
              avatar: 'update2.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 150,
            ),
            rating: 3.5,
            createdAt: DateTime.now(),
          ),
        ];

        // Create users first
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Batch update users
        await odm.runBatch((batch) {
          batch.users.update(
            users[0].copyWith(isActive: true, isPremium: true),
          );
          batch.users.update(
            users[1].copyWith(isActive: true, isPremium: true),
          );
        });

        // Verify updates
        final updatedUsers = await odm.users
            .where(($) => $.id(whereIn: ['batch_update_1', 'batch_update_2']))
            .get();

        expect(updatedUsers.length, equals(2));
        for (final user in updatedUsers) {
          expect(user.isActive, isTrue);
          expect(user.isPremium, isTrue);
        }
      });

      test('should perform batch upsert operations', () async {
        final users = [
          User(
            id: 'batch_upsert_1',
            name: 'Upsert User 1',
            email: 'upsert1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Upsert bio 1',
              avatar: 'upsert1.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'batch_upsert_2',
            name: 'Upsert User 2',
            email: 'upsert2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Upsert bio 2',
              avatar: 'upsert2.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 150,
            ),
            rating: 3.5,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Batch upsert (should create new documents)
        await odm.runBatch((batch) {
          for (final user in users) {
            batch.users.upsert(user);
          }
        });

        // Verify users were created
        final createdUsers = await odm.users
            .where(($) => $.id(whereIn: ['batch_upsert_1', 'batch_upsert_2']))
            .get();

        expect(createdUsers.length, equals(2));

        // Batch upsert again with updates (should update existing documents)
        await odm.runBatch((batch) {
          batch.users.upsert(users[0].copyWith(isPremium: true));
          batch.users.upsert(users[1].copyWith(isPremium: true));
        });

        // Verify updates
        final updatedUsers = await odm.users
            .where(($) => $.id(whereIn: ['batch_upsert_1', 'batch_upsert_2']))
            .get();

        expect(updatedUsers.length, equals(2));
        for (final user in updatedUsers) {
          expect(user.isPremium, isTrue);
        }
      });

      test('should perform batch delete operations', () async {
        // First create some users
        final users = [
          User(
            id: 'batch_delete_1',
            name: 'Delete User 1',
            email: 'delete1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Delete bio 1',
              avatar: 'delete1.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'batch_delete_2',
            name: 'Delete User 2',
            email: 'delete2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Delete bio 2',
              avatar: 'delete2.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 150,
            ),
            rating: 3.5,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Create users first
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Verify users exist
        final existingUsers = await odm.users
            .where(($) => $.id(whereIn: ['batch_delete_1', 'batch_delete_2']))
            .get();
        expect(existingUsers.length, equals(2));

        // Batch delete users
        await odm.runBatch((batch) {
          batch.users('batch_delete_1').delete();
          batch.users('batch_delete_2').delete();
        });

        // Verify users were deleted
        final remainingUsers = await odm.users
            .where(($) => $.id(whereIn: ['batch_delete_1', 'batch_delete_2']))
            .get();

        expect(remainingUsers.length, equals(0));
      });

      test('should perform batch patch operations', () async {
        // First create a user
        final user = User(
          id: 'batch_patch_user',
          name: 'Patch User',
          email: 'patch@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Original patch bio',
            avatar: 'patch.jpg',
            socialLinks: {},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 3,
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        // Batch patch user
        await odm.runBatch((batch) {
          batch
              .users('batch_patch_user')
              .patch(
                ($) => [
                  $.isActive(true),
                  $.isPremium(true),
                  $.rating.increment(1),
                  $.profile.followers.increment(50),
                ],
              );
        });

        // Verify patch
        final patchedUser = await odm.users('batch_patch_user').get();
        expect(patchedUser, isNotNull);
        expect(patchedUser!.isActive, isTrue);
        expect(patchedUser.isPremium, isTrue);
        expect(patchedUser.rating, equals(4.0));
        expect(patchedUser.profile.followers, equals(150));
      });
    });

    group('🔄 Mixed Batch Operations', () {
      test('should perform mixed batch operations in single batch', () async {
        // Create initial user
        final existingUser = User(
          id: 'mixed_existing',
          name: 'Existing User',
          email: 'existing@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Existing user',
            avatar: 'existing.jpg',
            socialLinks: {},
            interests: ['coding'],
            followers: 100,
          ),
          rating: 3,
          createdAt: DateTime.now(),
        );

        await odm.users(existingUser.id).update(existingUser);

        final newUser = User(
          id: 'mixed_new',
          name: 'New User',
          email: 'new@example.com',
          age: 30,
          profile: const Profile(
            bio: 'New user',
            avatar: 'new.jpg',
            socialLinks: {},
            interests: ['design'],
            followers: 150,
          ),
          rating: 3.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Mixed batch operations
        await odm.runBatch((batch) {
          // Insert new user
          batch.users.insert(newUser);

          // Update existing user
          batch.users.update(existingUser.copyWith(isActive: true));

          // Patch existing user
          batch
              .users('mixed_existing')
              .patch(($) => [$.isPremium(true), $.rating.increment(0.5)]);

          // Upsert another user
          batch.users.upsert(
            User(
              id: 'mixed_upsert',
              name: 'Upsert User',
              email: 'upsert@example.com',
              age: 28,
              profile: const Profile(
                bio: 'Upsert user',
                avatar: 'upsert.jpg',
                socialLinks: {},
                interests: ['mixed'],
                followers: 120,
              ),
              rating: 4,
              isActive: true,
              isPremium: true,
              createdAt: DateTime.now(),
            ),
          );
        });

        // Verify all operations
        final allUsers = await odm.users
            .where(
              ($) => $.id(
                whereIn: ['mixed_existing', 'mixed_new', 'mixed_upsert'],
              ),
            )
            .get();

        expect(allUsers.length, equals(3));

        final existingUpdated = allUsers.firstWhere(
          (u) => u.id == 'mixed_existing',
        );
        expect(existingUpdated.isActive, isTrue);
        expect(existingUpdated.isPremium, isTrue);
        expect(existingUpdated.rating, equals(3.5));

        final newCreated = allUsers.firstWhere((u) => u.id == 'mixed_new');
        expect(newCreated.name, equals('New User'));

        final upserted = allUsers.firstWhere((u) => u.id == 'mixed_upsert');
        expect(upserted.name, equals('Upsert User'));
        expect(upserted.isPremium, isTrue);
      });
    });

    group('🚨 Batch Error Handling', () {
      test('should handle batch operation limit', () async {
        // This test would be more meaningful with real Firestore
        // but we can still test the limit checking logic
        expect(() async {
          await odm.runBatch((batch) {
            // Try to add more than 500 operations
            for (var i = 0; i < 501; i++) {
              batch.users.insert(
                User(
                  id: 'limit_test_$i',
                  name: 'Limit Test $i',
                  email: 'limit$i@example.com',
                  age: 25,
                  profile: const Profile(
                    bio: 'Limit test',
                    avatar: 'limit.jpg',
                    socialLinks: {},
                    interests: ['limit'],
                    followers: 100,
                  ),
                  rating: 3,
                  isActive: true,
                  createdAt: DateTime.now(),
                ),
              );
            }
          });
        }, throwsA(isA<Exception>()));
      });

      test('should handle empty batch gracefully', () async {
        // Empty batch should complete without error
        await odm.runBatch((batch) {
          // No operations
        });

        // Should complete successfully
        expect(true, isTrue);
      });
    });
  });
}
