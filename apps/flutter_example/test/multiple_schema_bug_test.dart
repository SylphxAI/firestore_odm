import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/secondary_schema.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🐛 Multiple Schema Bug Reproduction Tests', () {
    late FakeFirebaseFirestore mainFirestore;
    late FakeFirebaseFirestore secondaryFirestore;
    late FirestoreODM<TestSchema> mainODM;
    late FirestoreODM<SecondarySchema> secondaryODM;

    setUp(() {
      mainFirestore = FakeFirebaseFirestore();
      secondaryFirestore = FakeFirebaseFirestore();

      // Create ODM instances with different schemas
      mainODM = FirestoreODM(testSchema, firestore: mainFirestore);
      secondaryODM = FirestoreODM(
        secondarySchema,
        firestore: secondaryFirestore,
      );
    });

    group('🔥 Schema Conflict Issues', () {
      test(
        'should reproduce filter selector conflicts between schemas',
        () async {
          // Create test data
          final user = User(
            id: 'conflict_user',
            name: 'Conflict User',
            email: 'conflict@test.com',
            age: 25,
            profile: const Profile(
              bio: 'Testing conflicts',
              avatar: 'conflict.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 100,
            ),
            rating: 3,
            isActive: true,
            createdAt: DateTime.now(),
          );

          final post = Post(
            id: 'conflict_post',
            title: 'Conflict Post',
            content: 'Testing schema conflicts',
            authorId: 'conflict_user',
            likes: 10,
            tags: ['conflict', 'test'],
            published: true,
            metadata: {'schema': 'conflict'},
            createdAt: DateTime.now(),
          );

          // Store data in both schemas using same models
          await mainODM.users(user.id).update(user);
          await secondaryODM.secondaryUsers(user.id).update(user);

          await mainODM.posts(post.id).update(post);
          await secondaryODM.secondaryPosts(post.id).update(post);

          // Test filter queries on both schemas - this might expose conflicts
          try {
            final mainResults = await mainODM.users
                .where(($) => $.name(isEqualTo: 'Conflict User'))
                .get();

            final secondaryResults = await secondaryODM.secondaryUsers
                .where(($) => $.name(isEqualTo: 'Conflict User'))
                .get();

            expect(mainResults.length, equals(1));
            expect(secondaryResults.length, equals(1));

            // Test complex filters that might expose internal conflicts
            final mainPostResults = await mainODM.posts
                .where(
                  ($) => $
                      .tags(arrayContains: 'conflict')
                      .and($.published(isEqualTo: true)),
                )
                .get();

            final secondaryPostResults = await secondaryODM.secondaryPosts
                .where(
                  ($) =>
                      $.tags(arrayContains: 'conflict') &
                      $.published(isEqualTo: true),
                )
                .get();

            expect(mainPostResults.length, equals(1));
            expect(secondaryPostResults.length, equals(1));

            print('✅ Filter selectors working correctly across schemas');
          } catch (e) {
            print('❌ Filter selector conflict detected: $e');
            rethrow;
          }
        },
      );

      test('should reproduce converter conflicts between schemas', () async {
        final user = User(
          id: 'converter_test',
          name: 'Converter Test',
          email: 'converter@test.com',
          age: 30,
          tags: ['converter', 'test', 'multiple'],
          scores: [100, 200, 300],
          settings: {'theme': 'dark', 'lang': 'en'},
          metadata: {'type': 'test', 'version': 1},
          profile: const Profile(
            bio: 'Testing converter conflicts',
            avatar: 'converter.jpg',
            socialLinks: {'github': 'convertertest'},
            interests: ['development', 'testing'],
            followers: 150,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        try {
          // Store and retrieve in main schema
          await mainODM.users(user.id).update(user);
          final mainRetrieved = await mainODM.users(user.id).get();

          // Store and retrieve in secondary schema
          await secondaryODM.secondaryUsers(user.id).update(user);
          final secondaryRetrieved = await secondaryODM
              .secondaryUsers(user.id)
              .get();

          // Verify both retrieved correctly (converter working)
          expect(mainRetrieved, isNotNull);
          expect(secondaryRetrieved, isNotNull);

          expect(mainRetrieved!.name, equals('Converter Test'));
          expect(secondaryRetrieved!.name, equals('Converter Test'));

          expect(mainRetrieved.tags.length, equals(3));
          expect(secondaryRetrieved.tags.length, equals(3));

          expect(mainRetrieved.metadata['version'], equals(1));
          expect(secondaryRetrieved.metadata['version'], equals(1));

          print('✅ Converters working correctly across schemas');
        } catch (e) {
          print('❌ Converter conflict detected: $e');
          rethrow;
        }
      });

      test(
        'should reproduce subcollection conflicts between schemas',
        () async {
          final user = User(
            id: 'subcol_conflict_user',
            name: 'Subcol Conflict User',
            email: 'subcolconflict@test.com',
            age: 28,
            profile: const Profile(
              bio: 'Testing subcollection conflicts',
              avatar: 'subcolconflict.jpg',
              socialLinks: {},
              interests: ['subcol'],
              followers: 120,
            ),
            rating: 3.5,
            isActive: true,
            createdAt: DateTime.now(),
          );

          final userPost = Post(
            id: 'subcol_conflict_post',
            title: 'Subcollection Conflict Post',
            content: 'Testing subcollection conflicts between schemas',
            authorId: user.id,
            likes: 15,
            tags: ['subcol', 'conflict'],
            published: true,
            metadata: {},
            createdAt: DateTime.now(),
          );

          try {
            // Create users in both schemas
            await mainODM.users(user.id).update(user);
            await secondaryODM.secondaryUsers(user.id).update(user);

            // Add posts to user subcollections in both schemas
            await mainODM.users(user.id).posts(userPost.id).update(userPost);
            await secondaryODM
                .secondaryUsers(user.id)
                .userPosts(userPost.id)
                .update(userPost);

            // Retrieve subcollection documents
            final mainSubPost = await mainODM
                .users(user.id)
                .posts(userPost.id)
                .get();
            final secondarySubPost = await secondaryODM
                .secondaryUsers(user.id)
                .userPosts(userPost.id)
                .get();

            expect(mainSubPost, isNotNull);
            expect(secondarySubPost, isNotNull);
            expect(mainSubPost!.title, equals('Subcollection Conflict Post'));
            expect(
              secondarySubPost!.title,
              equals('Subcollection Conflict Post'),
            );

            print('✅ Subcollections working correctly across schemas');
          } catch (e) {
            print('❌ Subcollection conflict detected: $e');
            rethrow;
          }
        },
      );

      test('should reproduce transaction conflicts between schemas', () async {
        final user = User(
          id: 'tx_conflict_user',
          name: 'TX Conflict User',
          email: 'txconflict@test.com',
          age: 32,
          profile: const Profile(
            bio: 'Testing transaction conflicts',
            avatar: 'txconflict.jpg',
            socialLinks: {},
            interests: ['transactions'],
            followers: 180,
          ),
          rating: 4,
          isActive: true,
          isPremium: true,
          scores: [1000],
          createdAt: DateTime.now(),
        );

        try {
          // Set initial data in both schemas
          await mainODM.users(user.id).update(user);
          await secondaryODM.secondaryUsers(user.id).update(user);

          // Run transactions on both schemas simultaneously
          await Future.wait([
            mainODM.runTransaction((tx) async {
              final currentUser = await tx.users(user.id).get();
              tx
                  .users(user.id)
                  .patch(
                    ($) => [$.name('Main TX Updated'), $.rating.increment(0.5)],
                  );
            }),
            secondaryODM.runTransaction((tx) async {
              final currentUser = await tx.secondaryUsers(user.id).get();
              await tx
                  .secondaryUsers(user.id)
                  .modify(
                    (user) => user.copyWith(
                      name: 'Secondary TX Updated',
                      scores: [user.scores.first + 500],
                    ),
                  );
            }),
          ]);

          // Verify transaction results
          final mainResult = await mainODM.users(user.id).get();
          final secondaryResult = await secondaryODM
              .secondaryUsers(user.id)
              .get();

          expect(mainResult!.name, equals('Main TX Updated'));
          expect(mainResult.rating, equals(4.5));

          expect(secondaryResult!.name, equals('Secondary TX Updated'));
          expect(secondaryResult.scores.first, equals(1500));

          print('✅ Transactions working correctly across schemas');
        } catch (e) {
          print('❌ Transaction conflict detected: $e');
          rethrow;
        }
      });

      test('should test simultaneous queries across both schemas', () async {
        // Create test data for both schemas
        final users = List.generate(
          5,
          (i) => User(
            id: 'multi_query_user_$i',
            name: 'Multi Query User $i',
            email: 'multiquery$i@test.com',
            age: 20 + i,
            profile: Profile(
              bio: 'Multi query test $i',
              avatar: 'multi$i.jpg',
              socialLinks: {},
              interests: ['query', 'test'],
              followers: 100 + i * 10,
            ),
            rating: 2.0 + i * 0.5,
            isActive: i % 2 == 0,
            isPremium: i > 2,
            createdAt: DateTime.now(),
          ),
        );

        try {
          // Add all users to both schemas
          for (final user in users) {
            await mainODM.users(user.id).update(user);
            await secondaryODM.secondaryUsers(user.id).update(user);
          }

          // Run simultaneous complex queries on both schemas
          final results = await Future.wait([
            mainODM.users
                .where(
                  ($) => $
                      .isActive(isEqualTo: true)
                      .and($.rating(isGreaterThan: 3)),
                )
                .orderBy(($) => ($.age(),))
                .get(),
            secondaryODM.secondaryUsers
                .where(($) => $.isPremium(isEqualTo: true))
                .orderBy(($) => ($.rating(descending: true),))
                .get(),
            mainODM.users
                .where(($) => $.profile.interests(arrayContains: 'query'))
                .limit(3)
                .get(),
            secondaryODM.secondaryUsers
                .where(($) => $.age(isGreaterThanOrEqualTo: 22))
                .get(),
          ]);

          final mainActiveResults = results[0];
          final secondaryPremiumResults = results[1];
          final mainInterestResults = results[2];
          final secondaryAgeResults = results[3];

          expect(mainActiveResults.length, greaterThan(0));
          expect(secondaryPremiumResults.length, greaterThan(0));
          expect(mainInterestResults.length, greaterThan(0));
          expect(secondaryAgeResults.length, greaterThan(0));

          print('✅ Simultaneous queries working correctly across schemas');
          print('Main active results: ${mainActiveResults.length}');
          print('Secondary premium results: ${secondaryPremiumResults.length}');
          print('Main interest results: ${mainInterestResults.length}');
          print('Secondary age results: ${secondaryAgeResults.length}');
        } catch (e) {
          print('❌ Simultaneous query conflict detected: $e');
          rethrow;
        }
      });
    });

    group('🔍 Code Generation Analysis', () {
      test('should verify no class name conflicts in generated code', () {
        // This test checks for potential naming conflicts in generated classes
        try {
          // Try to access collection classes from both schemas
          final mainUsersType = mainODM.users.runtimeType.toString();
          final secondaryUsersType = secondaryODM.secondaryUsers.runtimeType
              .toString();

          print('Main users collection type: $mainUsersType');
          print('Secondary users collection type: $secondaryUsersType');

          // Verify they're different types (no conflicts)
          expect(mainUsersType, isNot(equals(secondaryUsersType)));

          // Test that both can be used simultaneously
          expect(() => mainODM.users, returnsNormally);
          expect(() => secondaryODM.secondaryUsers, returnsNormally);
          expect(() => mainODM.posts, returnsNormally);
          expect(() => secondaryODM.secondaryPosts, returnsNormally);

          print('✅ No class name conflicts detected');
        } catch (e) {
          print('❌ Class name conflict detected: $e');
          rethrow;
        }
      });
    });
  });
}
