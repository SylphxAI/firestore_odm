import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🗑️ New Bulk Delete Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📋 Query Delete Operations', () {
      test('should delete all documents matching query filter', () async {
        // Create test users
        final users = [
          User(
            id: 'query_delete_1',
            name: 'Query User 1',
            email: 'query1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Query user 1',
              avatar: 'query1.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 100,
            ),
            rating: 3,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'query_delete_2',
            name: 'Query User 2',
            email: 'query2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Query user 2',
              avatar: 'query2.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 150,
            ),
            rating: 3.5,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'query_keep_1',
            name: 'Keep User 1',
            email: 'keep1@example.com',
            age: 35,
            profile: const Profile(
              bio: 'Keep user 1',
              avatar: 'keep1.jpg',
              socialLinks: {},
              interests: ['keeping'],
              followers: 200,
            ),
            rating: 4,
            isActive: true, // Will be kept
            createdAt: DateTime.now(),
          ),
        ];

        // Insert all users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Verify all users exist
        final allUsers = await odm.users.get();
        expect(allUsers.length, equals(3));

        // ✅ NEW: Delete all inactive users using Query.delete()
        await odm.users.where(($) => $.isActive(isEqualTo: false)).delete();

        // Verify only active users remain
        final remainingUsers = await odm.users.get();
        expect(remainingUsers.length, equals(1));
        expect(remainingUsers.first.name, equals('Keep User 1'));
        expect(remainingUsers.first.isActive, isTrue);

        print('✅ Query.delete() - Successfully deleted 2 inactive users');
      });

      test('should delete documents using complex query filters', () async {
        // Create test users with various criteria
        final users = [
          User(
            id: 'complex_1',
            name: 'Complex User 1',
            email: 'complex1@example.com',
            age: 20, // Young and low rating - will be deleted
            profile: const Profile(
              bio: 'Complex user 1',
              avatar: 'complex1.jpg',
              socialLinks: {},
              interests: ['complex'],
              followers: 50,
            ),
            rating: 2, // Low rating
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'complex_2',
            name: 'Complex User 2',
            email: 'complex2@example.com',
            age: 22, // Young and low rating - will be deleted
            profile: const Profile(
              bio: 'Complex user 2',
              avatar: 'complex2.jpg',
              socialLinks: {},
              interests: ['complex'],
              followers: 60,
            ),
            rating: 1.5, // Low rating
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'complex_keep',
            name: 'Complex Keep',
            email: 'keep@example.com',
            age: 25, // Older with good rating - will be kept
            profile: const Profile(
              bio: 'Keep this user',
              avatar: 'keep.jpg',
              socialLinks: {},
              interests: ['keeping'],
              followers: 300,
            ),
            rating: 4.5, // High rating
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert all users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Delete users using complex AND condition
        await odm.users
            .where(($) => $.and($.age(isLessThan: 25), $.rating(isLessThan: 3)))
            .delete();

        // Verify only the good user remains
        final remainingUsers = await odm.users.get();
        expect(remainingUsers.length, equals(1));
        expect(remainingUsers.first.name, equals('Complex Keep'));

        print('✅ Query.delete() with complex filters - Success');
      });
    });

    group('📑 OrderedQuery Delete Operations', () {
      test('should delete documents from ordered query results', () async {
        // Create users with different ratings
        final users = [
          User(
            id: 'ordered_1',
            name: 'Low Rated User',
            email: 'low@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Low rated user',
              avatar: 'low.jpg',
              socialLinks: {},
              interests: ['low'],
              followers: 50,
            ),
            rating: 1, // Lowest rating
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'ordered_2',
            name: 'Medium Rated User',
            email: 'medium@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Medium rated user',
              avatar: 'medium.jpg',
              socialLinks: {},
              interests: ['medium'],
              followers: 100,
            ),
            rating: 3, // Medium rating
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'ordered_3',
            name: 'High Rated User',
            email: 'high@example.com',
            age: 35,
            profile: const Profile(
              bio: 'High rated user',
              avatar: 'high.jpg',
              socialLinks: {},
              interests: ['high'],
              followers: 200,
            ),
            rating: 5, // Highest rating
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
        ];

        // Insert all users
        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // ✅ NEW: Delete lowest rated users using OrderedQuery.delete()
        await odm.users
            .orderBy(($) => ($.rating(),)) // Order by rating ascending
            .limit(2) // Take bottom 2
            .delete();

        // Verify only the highest rated user remains
        final remainingUsers = await odm.users.get();
        expect(remainingUsers.length, equals(1));
        expect(remainingUsers.first.name, equals('High Rated User'));
        expect(remainingUsers.first.rating, equals(5.0));

        print(
          '✅ OrderedQuery.delete() - Successfully deleted 2 lowest rated users',
        );
      });

      test(
        'should delete using OrderedQuery with additional filtering',
        () async {
          // Create users for complex ordered deletion
          final users = [
            User(
              id: 'ordered_filter_1',
              name: 'Young Active',
              email: 'young@example.com',
              age: 20,
              profile: const Profile(
                bio: 'Young active user',
                avatar: 'young.jpg',
                socialLinks: {},
                interests: ['young'],
                followers: 80,
              ),
              rating: 3.5,
              isActive: true, // Active
              createdAt: DateTime.now(),
            ),
            User(
              id: 'ordered_filter_2',
              name: 'Young Inactive',
              email: 'inactive@example.com',
              age: 22,
              profile: const Profile(
                bio: 'Young inactive user',
                avatar: 'inactive.jpg',
                socialLinks: {},
                interests: ['inactive'],
                followers: 40,
              ),
              rating: 2,
              createdAt: DateTime.now(),
            ),
            User(
              id: 'ordered_filter_3',
              name: 'Old Active',
              email: 'old@example.com',
              age: 40,
              profile: const Profile(
                bio: 'Old active user',
                avatar: 'old.jpg',
                socialLinks: {},
                interests: ['old'],
                followers: 300,
              ),
              rating: 4.5,
              isActive: true, // Active
              isPremium: true,
              createdAt: DateTime.now(),
            ),
          ];

          // Insert all users
          for (final user in users) {
            await odm.users(user.id).update(user);
          }

          // ✅ NEW: Use OrderedQuery with additional where() filtering
          await odm.users
              .orderBy(($) => ($.age(),)) // Order by age
              .where(
                ($) => $.isActive(isEqualTo: false),
              ) // ✅ NEW: Additional filtering on OrderedQuery
              .delete();

          // Verify only active users remain
          final remainingUsers = await odm.users.get();
          expect(remainingUsers.length, equals(2));

          final remainingNames = remainingUsers.map((u) => u.name).toSet();
          expect(remainingNames, contains('Young Active'));
          expect(remainingNames, contains('Old Active'));

          print(
            '✅ OrderedQuery.where().delete() - Successfully deleted inactive users',
          );
        },
      );
    });

    group('🗂️ Collection Delete Operations', () {
      test('should delete all documents in collection', () async {
        // Create several users
        final users = [
          User(
            id: 'collection_1',
            name: 'Collection User 1',
            email: 'col1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Collection user 1',
              avatar: 'col1.jpg',
              socialLinks: {},
              interests: ['collection'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'collection_2',
            name: 'Collection User 2',
            email: 'col2@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Collection user 2',
              avatar: 'col2.jpg',
              socialLinks: {},
              interests: ['collection'],
              followers: 150,
            ),
            rating: 4,
            isPremium: true,
            createdAt: DateTime.now(),
          ),
          User(
            id: 'collection_3',
            name: 'Collection User 3',
            email: 'col3@example.com',
            age: 35,
            profile: const Profile(
              bio: 'Collection user 3',
              avatar: 'col3.jpg',
              socialLinks: {},
              interests: ['collection'],
              followers: 200,
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

        // Verify all users exist
        final allUsers = await odm.users.get();
        expect(allUsers.length, equals(3));

        // ✅ NEW: Delete all documents in collection
        await odm.users.delete();

        // Verify collection is empty
        final remainingUsers = await odm.users.get();
        expect(remainingUsers.length, equals(0));

        print(
          '✅ FirestoreCollection.delete() - Successfully deleted all 3 users',
        );
      });
    });

    group('🔄 Mixed Delete Scenarios', () {
      test('should handle delete with no matching documents', () async {
        // Create a user that won't match the delete criteria
        final user = User(
          id: 'no_match_user',
          name: 'No Match User',
          email: 'nomatch@example.com',
          age: 25,
          profile: const Profile(
            bio: 'This user will not match',
            avatar: 'nomatch.jpg',
            socialLinks: {},
            interests: ['no-match'],
            followers: 100,
          ),
          rating: 4,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        // Try to delete users that don't exist
        await odm.users
            .where(($) => $.isActive(isEqualTo: false)) // No inactive users
            .delete();

        // Verify user still exists
        final remainingUsers = await odm.users.get();
        expect(remainingUsers.length, equals(1));
        expect(remainingUsers.first.name, equals('No Match User'));

        print('✅ Delete with no matches - Handled gracefully');
      });

      test('should handle delete on empty collection', () async {
        // Try to delete from empty collection
        await odm.users.delete();

        // Verify collection is still empty (no error)
        final users = await odm.users.get();
        expect(users.length, equals(0));

        print('✅ Delete on empty collection - Handled gracefully');
      });
    });
  });
}
