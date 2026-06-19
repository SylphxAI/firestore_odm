import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 Bulk Operations Features', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📝 Bulk Modify Operations', () {
      test('should perform bulk modify on query results', () async {
        final users = [
          User(
            id: 'bulk_modify_1',
            name: 'Bulk User 1',
            email: 'bulk1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'First bulk user',
              avatar: 'bulk1.jpg',
              socialLinks: {},
              interests: ['coding'],
              followers: 100,
            ),
            rating: 3,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bulk_modify_2',
            name: 'Bulk User 2',
            email: 'bulk2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Second bulk user',
              avatar: 'bulk2.jpg',
              socialLinks: {},
              interests: ['design'],
              followers: 150,
            ),
            rating: 3.5,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bulk_modify_3',
            name: 'Bulk User 3',
            email: 'bulk3@example.com',
            age: 28,
            profile: const Profile(
              bio: 'Third bulk user',
              avatar: 'bulk3.jpg',
              socialLinks: {},
              interests: ['marketing'],
              followers: 120,
            ),
            rating: 4,
            isActive: true, // This one is already active
            createdAt: DateTime.now(),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Bulk modify all inactive users to active
        await odm.users
            .where(($) => $.isActive(isEqualTo: false))
            .modify((user) => user.copyWith(isActive: true));

        // Verify all users are now active
        final allUsers = await odm.users
            .where(
              ($) => $.id(
                whereIn: ['bulk_modify_1', 'bulk_modify_2', 'bulk_modify_3'],
              ),
            )
            .get();

        expect(allUsers.length, equals(3));
        for (final user in allUsers) {
          expect(user.isActive, isTrue);
        }
      });

      test('should handle complex bulk modifications', () async {
        final users = List.generate(
          5,
          (index) => User(
            id: 'complex_bulk_$index',
            name: 'Complex User $index',
            email: 'complex$index@example.com',
            age: 20 + index * 2,
            profile: Profile(
              bio: 'Complex user $index',
              avatar: 'complex$index.jpg',
              socialLinks: {},
              interests: ['complexity'],
              followers: 50 + index * 25,
            ),
            rating: 2.0 + index * 0.4,
            isActive: true,
            isPremium: index % 2 == 0, // Alternate premium status
            createdAt: DateTime.now(),
          ),
        );

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Complex bulk modification: update non-premium users
        await odm.users
            .where(
              ($) =>
                  $.and($.isPremium(isEqualTo: false), $.rating(isLessThan: 4)),
            )
            .modify(
              (user) => user.copyWith(
                isPremium: true,
                profile: user.profile.copyWith(
                  bio: '${user.profile.bio} - Upgraded to Premium',
                ),
              ),
            );

        final updatedUsers = await odm.users
            .where(($) => $.id(whereIn: users.map((u) => u.id).toList()))
            .get();

        // Check that the right users were updated
        for (final user in updatedUsers) {
          final originalIndex = int.parse(user.id.split('_').last);
          if (originalIndex % 2 == 1 && (2.0 + originalIndex * 0.4) < 4.0) {
            expect(user.isPremium, isTrue);
            expect(user.profile.bio, contains('Upgraded to Premium'));
          }
        }
      });
    });

    group('⚡ Bulk Incremental Modify Operations', () {
      test(
        'should perform bulk incremental modify with atomic operations',
        () async {
          final users = [
            User(
              id: 'atomic_bulk_1',
              name: 'Atomic User 1',
              email: 'atomic1@example.com',
              age: 25,
              profile: const Profile(
                bio: 'First atomic user',
                avatar: 'atomic1.jpg',
                socialLinks: {},
                interests: ['coding'],
                followers: 100,
              ),
              rating: 3,
              isActive: true,
              tags: ['developer'],
              scores: [85, 90],
              createdAt: DateTime.now(),
            ),
            User(
              id: 'atomic_bulk_2',
              name: 'Atomic User 2',
              email: 'atomic2@example.com',
              age: 28,
              profile: const Profile(
                bio: 'Second atomic user',
                avatar: 'atomic2.jpg',
                socialLinks: {},
                interests: ['design'],
                followers: 150,
              ),
              rating: 4,
              isActive: true,
              tags: ['designer'],
              scores: [88, 92],
              createdAt: DateTime.now(),
            ),
          ];

          for (final user in users) {
            await odm.users(user.id).update(user);
          }

          // Bulk incremental modify with atomic operations
          await odm.users
              .where(($) => $.id(whereIn: ['atomic_bulk_1', 'atomic_bulk_2']))
              .modify(
                (user) => user.copyWith(
                  rating:
                      user.rating + 0.5, // Should use FieldValue.increment(0.5)
                  profile: user.profile.copyWith(
                    followers:
                        user.profile.followers +
                        25, // Should use FieldValue.increment(25)
                    interests: [
                      ...user.profile.interests,
                      'firebase',
                    ], // Should use FieldValue.arrayUnion(['firebase'])
                  ),
                  tags: [
                    ...user.tags,
                    'firebase_expert',
                  ], // Should use FieldValue.arrayUnion(['firebase_expert'])
                  lastLogin: FirestoreODM.serverTimestamp, // Server timestamp
                ),
              );

          final updatedUsers = await odm.users
              .where(($) => $.id(whereIn: ['atomic_bulk_1', 'atomic_bulk_2']))
              .get();

          expect(updatedUsers.length, equals(2));
          for (final user in updatedUsers) {
            expect(user.profile.interests, contains('firebase'));
            expect(user.tags, contains('firebase_expert'));
            expect(user.lastLogin, isNotNull);

            if (user.id == 'atomic_bulk_1') {
              expect(user.rating, equals(3.5));
              expect(user.profile.followers, equals(125));
            } else if (user.id == 'atomic_bulk_2') {
              expect(user.rating, equals(4.5));
              expect(user.profile.followers, equals(175));
            }
          }
        },
      );

      test('should handle mixed atomic and regular updates in bulk', () async {
        final users = List.generate(
          4,
          (index) => User(
            id: 'mixed_bulk_$index',
            name: 'Mixed User $index',
            email: 'mixed$index@example.com',
            age: 25 + index,
            profile: Profile(
              bio: 'Mixed user $index',
              avatar: 'mixed$index.jpg',
              socialLinks: {},
              interests: ['mixed_operations'],
              followers: 100 + index * 20,
            ),
            rating: 3.0 + index * 0.2,
            isActive: true,
            tags: ['mixed'],
            scores: [80 + index * 5],
            createdAt: DateTime.now(),
          ),
        );

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Mixed bulk operations
        await odm.users
            .where(
              ($) => $.profile.interests(arrayContains: 'mixed_operations'),
            )
            .modify(
              (user) => user.copyWith(
                // Atomic operations
                age: user.age + 1, // Increment
                rating: user.rating + 0.3, // Increment
                profile: user.profile.copyWith(
                  followers: user.profile.followers + 50, // Increment
                  interests: [
                    ...user.profile.interests,
                    'advanced',
                  ], // Array union
                ),
                tags: [...user.tags, 'updated'], // Array union
                scores: [
                  ...user.scores,
                  user.scores.length + 90,
                ], // Array union
                // Regular updates
                isPremium: true,
                lastLogin: FirestoreODM.serverTimestamp,
              ),
            );

        final updatedUsers = await odm.users
            .where(
              ($) => $.profile.interests(arrayContains: 'mixed_operations'),
            )
            .get();

        expect(updatedUsers.length, equals(4));
        for (final user in updatedUsers) {
          final originalIndex = int.parse(user.id.split('_').last);

          // Check atomic operations
          expect(user.age, equals(25 + originalIndex + 1));
          expect(user.rating, closeTo(3.0 + originalIndex * 0.2 + 0.3, 0.01));
          expect(user.profile.followers, equals(100 + originalIndex * 20 + 50));
          expect(user.profile.interests, contains('advanced'));
          expect(user.tags, contains('updated'));
          expect(user.scores.length, equals(2)); // Original + new score

          // Check regular updates
          expect(user.isPremium, isTrue);
          expect(user.lastLogin, isNotNull);
        }
      });
    });

    group('🎯 Targeted Bulk Operations', () {
      test('should perform bulk operations on filtered results', () async {
        // Create users with different characteristics
        final users = [
          // Young, inactive users
          ...List.generate(
            3,
            (index) => User(
              id: 'young_inactive_$index',
              name: 'Young Inactive $index',
              email: 'young_inactive$index@example.com',
              age: 18 + index,
              profile: Profile(
                bio: 'Young inactive user',
                avatar: 'young$index.jpg',
                socialLinks: {},
                interests: ['youth'],
                followers: 20 + index * 10,
              ),
              rating: 2.0 + index * 0.3,
              createdAt: DateTime.now(),
            ),
          ),
          // Older, active users
          ...List.generate(
            3,
            (index) => User(
              id: 'older_active_$index',
              name: 'Older Active $index',
              email: 'older_active$index@example.com',
              age: 30 + index * 2,
              profile: Profile(
                bio: 'Older active user',
                avatar: 'older$index.jpg',
                socialLinks: {},
                interests: ['experience'],
                followers: 200 + index * 50,
              ),
              rating: 4.0 + index * 0.2,
              isActive: true,
              isPremium: true,
              createdAt: DateTime.now(),
            ),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Activate all young users and give them a bonus
        await odm.users
            .where(
              ($) => $.and($.age(isLessThan: 25), $.isActive(isEqualTo: false)),
            )
            .modify(
              (user) => user.copyWith(
                isActive: true,
                rating: user.rating + 1.0, // Bonus rating
                profile: user.profile.copyWith(
                  followers: user.profile.followers + 100, // Bonus followers
                  interests: [...user.profile.interests, 'activated'],
                ),
              ),
            );

        // Update older users' premium features
        await odm.users
            .where(
              ($) => $.and(
                $.age(isGreaterThanOrEqualTo: 30),
                $.isPremium(isEqualTo: true),
              ),
            )
            .modify(
              (user) => user.copyWith(
                profile: user.profile.copyWith(
                  bio: '${user.profile.bio} - Premium Member',
                ),
              ),
            );

        // Verify young users were activated
        final activatedYoungUsers = await odm.users
            .where(
              ($) => $.and($.age(isLessThan: 25), $.isActive(isEqualTo: true)),
            )
            .get();

        expect(activatedYoungUsers.length, equals(3));
        for (final user in activatedYoungUsers) {
          expect(user.profile.interests, contains('activated'));
          expect(
            user.profile.followers,
            greaterThanOrEqualTo(120),
          ); // Original + bonus
        }

        // Verify older users' premium features
        final premiumOlderUsers = await odm.users
            .where(($) => $.age(isGreaterThanOrEqualTo: 30))
            .get();

        expect(premiumOlderUsers.length, equals(3));
        for (final user in premiumOlderUsers) {
          expect(user.profile.bio, contains('Premium Member'));
        }
      });

      test('should handle empty bulk operation results gracefully', () async {
        // Try to perform bulk operation on non-existent users
        await odm.users
            .where(($) => $.name(isEqualTo: 'NonExistentUser'))
            .modify((user) => user.copyWith(isActive: true));

        // Should complete without error even though no documents match
        final results = await odm.users
            .where(($) => $.name(isEqualTo: 'NonExistentUser'))
            .get();

        expect(results, isEmpty);
      });
    });

    group('📊 Performance and Scale', () {
      test('should handle large bulk operations efficiently', () async {
        // Create many users for bulk testing
        final users = List.generate(
          50,
          (index) => User(
            id: 'perf_user_$index',
            name: 'Performance User $index',
            email: 'perf$index@example.com',
            age: 20 + (index % 30),
            profile: Profile(
              bio: 'Performance test user $index',
              avatar: 'perf$index.jpg',
              socialLinks: {},
              interests: ['performance'],
              followers: index * 5,
            ),
            rating: 1.0 + (index % 5),
            isActive: index % 2 == 0,
            createdAt: DateTime.now(),
          ),
        );

        // Bulk create all users
        final createFutures = users.map(
          (user) => odm.users(user.id).update(user),
        );
        await Future.wait(createFutures);

        final stopwatch = Stopwatch()..start();

        // Perform bulk operation
        await odm.users
            .where(($) => $.profile.interests(arrayContains: 'performance'))
            .modify(
              (user) => user.copyWith(
                isPremium: true,
                rating: user.rating + 1.0,
                profile: user.profile.copyWith(
                  followers: user.profile.followers + 100,
                ),
              ),
            );

        stopwatch.stop();

        // Verify all users were updated
        final updatedUsers = await odm.users
            .where(($) => $.isPremium(isEqualTo: true))
            .get();

        expect(updatedUsers.length, equals(50));
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(10000),
        ); // Should complete within 10 seconds

        // Verify updates were applied correctly
        for (final user in updatedUsers) {
          expect(user.isPremium, isTrue);
          expect(user.profile.followers, greaterThanOrEqualTo(100));
        }
      });
    });
  });
}
