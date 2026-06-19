import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🏗️ New Collection Bulk Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🔄 Collection Bulk Modify', () {
      test('should perform bulk modify on entire collection', () async {
        // Create test users
        final users = [
          User(
            id: 'bulk_col_1',
            name: 'Collection User 1',
            email: 'col1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Original bio 1',
              avatar: 'col1.jpg',
              socialLinks: {},
              interests: ['bulk'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bulk_col_2',
            name: 'Collection User 2',
            email: 'col2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Original bio 2',
              avatar: 'col2.jpg',
              socialLinks: {},
              interests: ['bulk'],
              followers: 200,
            ),
            rating: 4,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'bulk_col_3',
            name: 'Collection User 3',
            email: 'col3@example.com',
            age: 35,
            profile: const Profile(
              bio: 'Original bio 3',
              avatar: 'col3.jpg',
              socialLinks: {},
              interests: ['bulk'],
              followers: 300,
            ),
            rating: 5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert all users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Bulk modify on entire collection
        await odm.users.modify(
          (user) => user.copyWith(
            isPremium: true, // Upgrade everyone to premium
            profile: user.profile.copyWith(
              bio: '${user.profile.bio} - Bulk Updated!',
            ),
          ),
        );

        // Verify all users were updated
        final updatedUsers = await odm.users.get();
        expect(updatedUsers.length, equals(3));

        for (final user in updatedUsers) {
          expect(user.isPremium, isTrue);
          expect(user.profile.bio, contains('Bulk Updated!'));
        }

        print(
          '✅ FirestoreCollection.modify() - Bulk modify entire collection works',
        );
      });

      test('should handle empty collection in bulk modify', () async {
        // Try to modify empty collection - should not error
        await odm.users.modify((user) => user.copyWith(isPremium: true));

        // Collection should still be empty
        final users = await odm.users.get();
        expect(users.length, equals(0));

        print(
          '✅ FirestoreCollection.modify() on empty collection handled gracefully',
        );
      });
    });

    group('⚡ Collection Bulk Incremental Modify', () {
      test('should perform bulk modify with atomic operations', () async {
        // Create test users
        final users = [
          User(
            id: 'inc_col_1',
            name: 'Inc Collection 1',
            email: 'inc1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Inc bio 1',
              avatar: 'inc1.jpg',
              socialLinks: {},
              interests: ['increment'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'inc_col_2',
            name: 'Inc Collection 2',
            email: 'inc2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Inc bio 2',
              avatar: 'inc2.jpg',
              socialLinks: {},
              interests: ['increment'],
              followers: 150,
            ),
            rating: 4,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'inc_col_3',
            name: 'Inc Collection 3',
            email: 'inc3@example.com',
            age: 40,
            profile: const Profile(
              bio: 'Inc bio 3',
              avatar: 'inc3.jpg',
              socialLinks: {},
              interests: ['increment'],
              followers: 200,
            ),
            rating: 4.5,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert all users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Bulk modify on entire collection
        await odm.users.modify(
          (user) => user.copyWith(
            age: user.age + 1, // Should auto-convert to FieldValue.increment(1)
            rating:
                user.rating +
                0.5, // Should auto-convert to FieldValue.increment(0.5)
            profile: user.profile.copyWith(
              followers:
                  user.profile.followers +
                  50, // Should auto-convert to FieldValue.increment(50)
            ),
          ),
        );

        // Verify atomic increments worked
        final incrementedUsers = await odm.users.get();
        expect(incrementedUsers.length, equals(3));

        for (final user in incrementedUsers) {
          // Ages should be incremented by 1
          expect(user.age, greaterThanOrEqualTo(26)); // 25+1, 30+1, 40+1
          // Ratings should be incremented by 0.5
          expect(
            user.rating,
            greaterThanOrEqualTo(3.5),
          ); // 3.0+0.5, 4.0+0.5, 4.5+0.5
          // Followers should be incremented by 50
          expect(
            user.profile.followers,
            greaterThanOrEqualTo(150),
          ); // 100+50, 150+50, 200+50
        }

        print(
          '✅ FirestoreCollection.modify() - Atomic operations work on entire collection',
        );
      });

      test('should handle complex atomic operations in modify', () async {
        // Create users with arrays and mixed data
        final users = [
          User(
            id: 'complex_1',
            name: 'Complex User 1',
            email: 'complex1@example.com',
            age: 25,
            tags: ['tag1', 'tag2'], // Will add to this array
            scores: [80, 90], // Will add to this array
            profile: const Profile(
              bio: 'Complex bio 1',
              avatar: 'complex1.jpg',
              socialLinks: {'twitter': '@complex1'},
              interests: ['complex'],
              followers: 500,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'complex_2',
            name: 'Complex User 2',
            email: 'complex2@example.com',
            age: 30,
            tags: ['tag3', 'tag4'], // Will add to this array
            scores: [85, 95], // Will add to this array
            profile: const Profile(
              bio: 'Complex bio 2',
              avatar: 'complex2.jpg',
              socialLinks: {'linkedin': 'complex2'},
              interests: ['complex'],
              followers: 750,
            ),
            rating: 4,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Complex modify with array operations
        await odm.users.modify(
          (user) => user.copyWith(
            age: user.age + 2, // Numeric increment
            tags: [...user.tags, 'new_tag'], // Array union (should auto-detect)
            scores: [...user.scores, 100], // Array union with new score
            profile: user.profile.copyWith(
              followers:
                  user.profile.followers + 100, // Nested numeric increment
            ),
          ),
        );

        // Verify complex atomic operations
        final updatedUsers = await odm.users.get();
        expect(updatedUsers.length, equals(2));

        for (final user in updatedUsers) {
          // Age should be incremented
          expect(user.age, greaterThanOrEqualTo(27)); // 25+2 or 30+2
          // Tags should include new_tag
          expect(user.tags, contains('new_tag'));
          // Scores should include 100
          expect(user.scores, contains(100));
          // Followers should be incremented
          expect(
            user.profile.followers,
            greaterThanOrEqualTo(600),
          ); // 500+100 or 750+100
        }

        print(
          '✅ FirestoreCollection.modify() - Complex atomic operations work',
        );
      });

      test('should handle server timestamps in modify', () async {
        // Create a user
        final user = User(
          id: 'timestamp_user',
          name: 'Timestamp User',
          email: 'timestamp@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Timestamp user',
            avatar: 'timestamp.jpg',
            socialLinks: {},
            interests: ['timestamps'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          lastLogin: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        // ✅ NEW: Use server timestamp in modify
        await odm.users.modify(
          (user) => user.copyWith(
            age: user.age + 5, // Regular increment
            lastLogin: FirestoreODM.serverTimestamp, // Server timestamp
            updatedAt: FirestoreODM.serverTimestamp, // Server timestamp
          ),
        );

        // Verify server timestamps were applied
        final updatedUser = await odm.users('timestamp_user').get();
        expect(updatedUser, isNotNull);
        expect(updatedUser!.age, equals(30)); // 25 + 5
        // Server timestamps should be set (we can't verify exact time in tests)
        expect(updatedUser.lastLogin, isNotNull);
        expect(updatedUser.updatedAt, isNotNull);

        print('✅ FirestoreCollection.modify() - Server timestamps work');
      });

      test('should handle empty collection in modify', () async {
        // Try to incrementally modify empty collection - should not error
        await odm.users.modify((user) => user.copyWith(age: user.age + 1));

        // Collection should still be empty
        final users = await odm.users.get();
        expect(users.length, equals(0));

        print(
          '✅ FirestoreCollection.modify() on empty collection handled gracefully',
        );
      });
    });

    group('🔀 Mixed Collection Operations', () {
      test('should combine collection operations with other methods', () async {
        // Create initial users
        final users = [
          User(
            id: 'mixed_1',
            name: 'Mixed User 1',
            email: 'mixed1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Mixed bio 1',
              avatar: 'mixed1.jpg',
              socialLinks: {},
              interests: ['mixed'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'mixed_2',
            name: 'Mixed User 2',
            email: 'mixed2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Mixed bio 2',
              avatar: 'mixed2.jpg',
              socialLinks: {},
              interests: ['mixed'],
              followers: 200,
            ),
            rating: 4,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // 1. Bulk modify entire collection
        await odm.users.modify((user) => user.copyWith(isPremium: true));

        // 2. Then filter and modify specific subset
        await odm.users
            .where(($) => $.isActive(isEqualTo: true))
            .modify(
              (user) => user.copyWith(
                age: user.age + 10, // Only active users get age boost
              ),
            );

        // 3. Verify results
        final finalUsers = await odm.users.get();
        expect(finalUsers.length, equals(2));

        // All should be premium
        for (final user in finalUsers) {
          expect(user.isPremium, isTrue);
        }

        // Only active user should have age boost
        final activeUser = finalUsers.firstWhere((u) => u.isActive);
        final inactiveUser = finalUsers.firstWhere((u) => !u.isActive);

        expect(activeUser.age, equals(35)); // 25 + 10
        expect(inactiveUser.age, equals(30)); // Unchanged

        print('✅ Mixed collection operations work together');
      });

      test('should work with aggregations after bulk operations', () async {
        // Create users for aggregation testing
        final users = List.generate(
          5,
          (i) => User(
            id: 'agg_bulk_$i',
            name: 'Agg Bulk $i',
            email: 'aggbulk$i@example.com',
            age: 20 + i,
            profile: Profile(
              bio: 'Agg bulk $i',
              avatar: 'aggbulk$i.jpg',
              socialLinks: {},
              interests: ['aggregation'],
              followers: 100 * (i + 1),
            ),
            rating: 3.0 + (i * 0.5),
            isActive: true,
            createdAt: DateTime.now(),
          ),
        );

        // Insert users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Bulk modify all users
        await odm.users.modify(
          (user) => user.copyWith(
            age: user.age + 5, // Add 5 years to everyone
            rating: user.rating + 1.0, // Boost everyone's rating
          ),
        );

        // Then run aggregations
        final aggregateResult = await odm.users
            .aggregate(
              ($) => (
                count: $.count(),
                avgAge: $.age.average(), // Should be (25+26+27+28+29)/5 = 27
                avgRating: $.rating
                    .average(), // Should be (4.0+4.5+5.0+5.5+6.0)/5 = 5.0
                totalFollowers: $.profile.followers
                    .sum(), // Should be 100+200+300+400+500 = 1500
              ),
            )
            .get();

        expect(aggregateResult.count, equals(5));
        expect(aggregateResult.avgAge, equals(27.0)); // (25+26+27+28+29)/5
        expect(
          aggregateResult.avgRating,
          equals(5.0),
        ); // (4.0+4.5+5.0+5.5+6.0)/5
        expect(
          aggregateResult.totalFollowers,
          equals(1500),
        ); // 100+200+300+400+500

        print('✅ Aggregations work correctly after bulk operations');
      });
    });
  });
}
