import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🕐 FirestoreODM.serverTimestamp Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📝 Basic Server Timestamp Operations', () {
      test('should use serverTimestamp in patch operations', () async {
        // Create initial user
        final user = User(
          id: 'timestamp_user_1',
          name: 'Timestamp User',
          email: 'timestamp@test.com',
          age: 30,
          profile: const Profile(
            bio: 'Testing server timestamps',
            avatar: 'timestamp.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 100,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime(2024), // Fixed timestamp for testing
        );

        await odm.users(user.id).update(user);

        // Test patch with server timestamps
        await odm
            .users(user.id)
            .patch(
              ($) => [
                $.lastLogin(FirestoreODM.serverTimestamp),
                $.updatedAt(FirestoreODM.serverTimestamp),
                $.name('Updated via Patch'),
              ],
            );

        final updated = await odm.users(user.id).get();
        expect(updated, isNotNull);
        expect(updated!.name, equals('Updated via Patch'));
        expect(updated.lastLogin, isNotNull);
        expect(updated.updatedAt, isNotNull);

        print('lastLogin: ${updated.lastLogin}');

        // Server timestamps should be recent (within last few seconds)
        final now = DateTime.now();
        final lastLoginDiff = now.difference(updated.lastLogin!).abs();
        final updatedAtDiff = now.difference(updated.updatedAt!).abs();

        expect(lastLoginDiff.inMinutes, lessThan(1));
        expect(updatedAtDiff.inMinutes, lessThan(1));

        print('✅ Server timestamps work correctly in patch operations');
        print('   lastLogin: ${updated.lastLogin}');
        print('   updatedAt: ${updated.updatedAt}');
      });

      test('should use serverTimestamp in modify operations', () async {
        // Create initial post
        final post = Post(
          id: 'timestamp_post_1',
          title: 'Server Timestamp Post',
          content: 'Testing server timestamps in modify operations',
          authorId: 'timestamp_user_1',
          tags: ['timestamp', 'test'],
          metadata: {'type': 'test'},
          likes: 5,
          createdAt: DateTime(2024), // Fixed timestamp
        );

        await odm.posts(post.id).update(post);

        // Test modify with server timestamps
        await odm
            .posts(post.id)
            .modify(
              (post) => post.copyWith(
                title: 'Updated via Modify',
                published: true,
                publishedAt: FirestoreODM.serverTimestamp,
                updatedAt: FirestoreODM.serverTimestamp,
              ),
            );

        final updated = await odm.posts(post.id).get();
        expect(updated, isNotNull);
        expect(updated!.title, equals('Updated via Modify'));
        expect(updated.published, isTrue);
        expect(updated.publishedAt, isNotNull);
        expect(updated.updatedAt, isNotNull);

        // Server timestamps should be recent
        final now = DateTime.now();
        final publishedAtDiff = now.difference(updated.publishedAt!).abs();
        final updatedAtDiff = now.difference(updated.updatedAt!).abs();

        expect(publishedAtDiff.inMinutes, lessThan(1));
        expect(updatedAtDiff.inMinutes, lessThan(1));

        print('✅ Server timestamps work correctly in modify operations');
        print('   publishedAt: ${updated.publishedAt}');
        print('   updatedAt: ${updated.updatedAt}');
      });

      test(
        'should handle multiple server timestamps in single operation',
        () async {
          final user = User(
            id: 'multi_timestamp_user',
            name: 'Multi Timestamp User',
            email: 'multi@test.com',
            age: 25,
            profile: const Profile(
              bio: 'Multiple timestamps test',
              avatar: 'multi.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 50,
            ),
            rating: 3.5,
            isActive: true,
            createdAt: DateTime(2024),
          );

          await odm.users(user.id).update(user);

          // Set multiple server timestamps at once
          await odm
              .users(user.id)
              .patch(
                ($) => [
                  $.lastLogin(FirestoreODM.serverTimestamp),
                  $.updatedAt(FirestoreODM.serverTimestamp),
                  $.createdAt(
                    FirestoreODM.serverTimestamp,
                  ), // Override original
                  $.age.increment(1),
                ],
              );

          final updated = await odm.users(user.id).get();
          expect(updated, isNotNull);
          expect(updated!.age, equals(26)); // Incremented
          expect(updated.lastLogin, isNotNull);
          expect(updated.updatedAt, isNotNull);
          expect(updated.createdAt, isNotNull);

          // All server timestamps should be very close to each other
          final lastLogin = updated.lastLogin!;
          final updatedAt = updated.updatedAt!;
          final createdAt = updated.createdAt!;

          final diff1 = lastLogin.difference(updatedAt).abs();
          final diff2 = lastLogin.difference(createdAt).abs();

          expect(diff1.inSeconds, lessThan(2)); // Should be nearly identical
          expect(diff2.inSeconds, lessThan(2)); // Should be nearly identical

          print('✅ Multiple server timestamps work correctly');
          print('   All timestamps within 2 seconds of each other');
        },
      );
    });

    group('⚠️ Server Timestamp Limitations & Edge Cases', () {
      test(
        'should demonstrate arithmetic operations create regular DateTime',
        () async {
          final user = User(
            id: 'arithmetic_test_user',
            name: 'Arithmetic Test User',
            email: 'arithmetic@test.com',
            age: 30,
            profile: const Profile(
              bio: 'Testing arithmetic limitations',
              avatar: 'arithmetic.jpg',
              socialLinks: {},
              interests: ['testing'],
              followers: 100,
            ),
            rating: 4,
            isActive: true,
            createdAt: DateTime(2024),
          );

          await odm.users(user.id).update(user);

          // This creates a regular DateTime, NOT a server timestamp
          final futureDate = FirestoreODM.serverTimestamp.add(
            const Duration(days: 30),
          );

          await odm
              .users(user.id)
              .modify(
                (user) => user.copyWith(
                  lastLogin: FirestoreODM
                      .serverTimestamp, // This IS a server timestamp
                  updatedAt: futureDate, // This is NOT a server timestamp
                ),
              );

          final updated = await odm.users(user.id).get();
          expect(updated, isNotNull);

          // lastLogin should be recent (server timestamp)
          final now = DateTime.now();
          final lastLoginDiff = now.difference(updated!.lastLogin!).abs();
          expect(lastLoginDiff.inMinutes, lessThan(1));

          // updatedAt should be the calculated future date (regular DateTime)
          // The calculated date is based on the impossible timestamp value
          expect(updated.updatedAt, equals(futureDate));
          expect(
            updated.updatedAt!.isBefore(DateTime(1970)),
            isTrue,
          ); // Way in the past

          print('✅ Arithmetic operations create regular DateTime as expected');
          print('   lastLogin (server): ${updated.lastLogin}');
          print('   updatedAt (calculated): ${updated.updatedAt}');
          print('⚠️  updatedAt is NOT a server timestamp due to arithmetic');
        },
      );

      test('should verify serverTimestamp constant value', () {
        // The server timestamp constant should be an impossible date
        final serverTimestamp = FirestoreODM.serverTimestamp;

        // Should be the specific impossible timestamp value
        expect(
          serverTimestamp.millisecondsSinceEpoch,
          equals(-8640000000000000),
        );

        // Should be way before epoch
        expect(serverTimestamp.isBefore(DateTime(1970)), isTrue);

        // Should be way before any reasonable date
        expect(serverTimestamp.isBefore(DateTime(1900)), isTrue);

        print('✅ Server timestamp constant has expected impossible value');
        print('   Value: ${serverTimestamp.millisecondsSinceEpoch}');
        print('   Date: $serverTimestamp');
      });

      test('should handle null to serverTimestamp transitions', () async {
        final post = Post(
          id: 'null_transition_post',
          title: 'Null Transition Post',
          content: 'Testing null to server timestamp',
          authorId: 'test_author',
          tags: ['null', 'test'],
          metadata: {},
          createdAt: DateTime(2024),
          // publishedAt and updatedAt are null initially
        );

        await odm.posts(post.id).update(post);

        // Verify initial nulls
        final initial = await odm.posts(post.id).get();
        expect(initial!.publishedAt, isNull);
        expect(initial.updatedAt, isNull);

        // Set server timestamps on null fields
        await odm
            .posts(post.id)
            .patch(
              ($) => [
                $.publishedAt(FirestoreODM.serverTimestamp),
                $.updatedAt(FirestoreODM.serverTimestamp),
                $.published(true),
              ],
            );

        final updated = await odm.posts(post.id).get();
        expect(updated!.publishedAt, isNotNull);
        expect(updated.updatedAt, isNotNull);
        expect(updated.published, isTrue);

        // Should be recent timestamps
        final now = DateTime.now();
        expect(
          now.difference(updated.publishedAt!).abs().inMinutes,
          lessThan(1),
        );
        expect(now.difference(updated.updatedAt!).abs().inMinutes, lessThan(1));

        print('✅ Null to server timestamp transitions work correctly');
      });

      test('should handle serverTimestamp to null transitions', () async {
        final user = User(
          id: 'timestamp_to_null_user',
          name: 'Timestamp to Null User',
          email: 'tonull@test.com',
          age: 30,
          profile: const Profile(
            bio: 'Testing timestamp to null',
            avatar: 'tonull.jpg',
            socialLinks: {},
            interests: ['testing'],
            followers: 100,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime(2024),
          lastLogin:
              FirestoreODM.serverTimestamp, // Set server timestamp initially
        );

        await odm.users(user.id).update(user);

        // Verify server timestamp was set
        final initial = await odm.users(user.id).get();
        expect(initial!.lastLogin, isNotNull);

        // Set timestamp field back to null
        await odm
            .users(user.id)
            .patch(($) => [$.lastLogin(null), $.name('Timestamp Cleared')]);

        final updated = await odm.users(user.id).get();
        expect(updated!.lastLogin, isNull);
        expect(updated.name, equals('Timestamp Cleared'));

        print('✅ Server timestamp to null transitions work correctly');
      });
    });

    group('🔄 Server Timestamp in Complex Operations', () {
      test('should use serverTimestamp in transaction operations', () async {
        final user = User(
          id: 'transaction_timestamp_user',
          name: 'Transaction User',
          email: 'transaction@test.com',
          age: 30,
          profile: const Profile(
            bio: 'Transaction timestamp test',
            avatar: 'transaction.jpg',
            socialLinks: {},
            interests: ['transactions'],
            followers: 100,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime(2024),
        );

        await odm.users(user.id).update(user);

        // Use server timestamp in transaction
        await odm.runTransaction((tx) async {
          tx
              .users(user.id)
              .patch(
                ($) => [
                  $.lastLogin(FirestoreODM.serverTimestamp),
                  $.updatedAt(FirestoreODM.serverTimestamp),
                  $.isPremium(true),
                ],
              );
        });

        final updated = await odm.users(user.id).get();
        expect(updated!.isPremium, isTrue);
        expect(updated.lastLogin, isNotNull);
        expect(updated.updatedAt, isNotNull);

        final now = DateTime.now();
        expect(now.difference(updated.lastLogin!).abs().inMinutes, lessThan(1));
        expect(now.difference(updated.updatedAt!).abs().inMinutes, lessThan(1));

        print('✅ Server timestamps work correctly in transactions');
      });

      test('should use serverTimestamp in batch operations', () async {
        final user1 = User(
          id: 'batch_user_1',
          name: 'Batch User 1',
          email: 'batch1@test.com',
          age: 25,
          profile: const Profile(
            bio: 'Batch test 1',
            avatar: 'batch1.jpg',
            socialLinks: {},
            interests: ['batch'],
            followers: 50,
          ),
          rating: 3.5,
          isActive: true,
          createdAt: DateTime(2024),
        );

        final user2 = User(
          id: 'batch_user_2',
          name: 'Batch User 2',
          email: 'batch2@test.com',
          age: 35,
          profile: const Profile(
            bio: 'Batch test 2',
            avatar: 'batch2.jpg',
            socialLinks: {},
            interests: ['batch'],
            followers: 150,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime(2024),
        );

        // Create initial users
        await odm.users(user1.id).update(user1);
        await odm.users(user2.id).update(user2);

        // Use server timestamps in batch operations
        await odm.runBatch((batch) {
          batch
              .users(user1.id)
              .patch(
                ($) => [
                  $.lastLogin(FirestoreODM.serverTimestamp),
                  $.updatedAt(FirestoreODM.serverTimestamp),
                  $.isPremium(true),
                ],
              );

          batch
              .users(user2.id)
              .patch(
                ($) => [
                  $.lastLogin(FirestoreODM.serverTimestamp),
                  $.updatedAt(FirestoreODM.serverTimestamp),
                  $.age.increment(1),
                ],
              );
        });

        final updated1 = await odm.users(user1.id).get();
        final updated2 = await odm.users(user2.id).get();

        expect(updated1!.isPremium, isTrue);
        expect(updated1.lastLogin, isNotNull);
        expect(updated1.updatedAt, isNotNull);

        expect(updated2!.age, equals(36));
        expect(updated2.lastLogin, isNotNull);
        expect(updated2.updatedAt, isNotNull);

        // Both should have recent timestamps
        final now = DateTime.now();
        expect(
          now.difference(updated1.lastLogin!).abs().inMinutes,
          lessThan(1),
        );
        expect(
          now.difference(updated2.lastLogin!).abs().inMinutes,
          lessThan(1),
        );

        // Batch timestamps should be very close to each other
        final timeDiff = updated1.lastLogin!
            .difference(updated2.lastLogin!)
            .abs();
        expect(timeDiff.inSeconds, lessThan(5)); // Should be nearly identical

        print('✅ Server timestamps work correctly in batch operations');
        print('   Both users updated with synchronized timestamps');
      });

      test('should handle serverTimestamp with nested field updates', () async {
        final user = User(
          id: 'nested_timestamp_user',
          name: 'Nested Test User',
          email: 'nested@test.com',
          age: 28,
          profile: const Profile(
            bio: 'Original bio',
            avatar: 'nested.jpg',
            socialLinks: {'twitter': '@nested'},
            interests: ['nested'],
            followers: 75,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime(2024),
        );

        await odm.users(user.id).update(user);

        // Update both server timestamp and nested fields
        await odm
            .users(user.id)
            .patch(
              ($) => [
                $.lastLogin(FirestoreODM.serverTimestamp),
                $.updatedAt(FirestoreODM.serverTimestamp),
                $.profile.bio('Updated bio with timestamp'),
                $.profile.followers.increment(25),
                $.profile.socialLinks.set('github', '@nested_user'),
              ],
            );

        final updated = await odm.users(user.id).get();
        expect(updated!.lastLogin, isNotNull);
        expect(updated.updatedAt, isNotNull);
        expect(updated.profile.bio, equals('Updated bio with timestamp'));
        expect(updated.profile.followers, equals(100));
        expect(updated.profile.socialLinks['github'], equals('@nested_user'));

        final now = DateTime.now();
        expect(now.difference(updated.lastLogin!).abs().inMinutes, lessThan(1));
        expect(now.difference(updated.updatedAt!).abs().inMinutes, lessThan(1));

        print('✅ Server timestamps work with nested field updates');
      });
    });

    group('🧪 Server Timestamp Edge Cases & Validation', () {
      test('should demonstrate that serverTimestamp is a special constant', () {
        // Verify the constant properties
        final timestamp1 = FirestoreODM.serverTimestamp;
        final timestamp2 = FirestoreODM.serverTimestamp;

        // Should be the same reference/value
        expect(timestamp1, equals(timestamp2));
        expect(identical(timestamp1, timestamp2), isTrue);

        // Should have the impossible timestamp value
        expect(timestamp1.millisecondsSinceEpoch, equals(-8640000000000000));

        // Should be recognizable as the special value. Use UTC so the
        // assertion is timezone-independent — the local-time rendering of the
        // sentinel shifts by the runner's offset (e.g. 00:00 on UTC CI vs
        // 01:00 elsewhere).
        expect(
          timestamp1.toUtc().toString(),
          contains('-271821-04-20 00:00:00.000'),
        );

        print('✅ Server timestamp constant behaves correctly');
        print('   Consistent reference: ${identical(timestamp1, timestamp2)}');
        print('   Special value: ${timestamp1.millisecondsSinceEpoch}');
      });

      test('should verify serverTimestamp works with copyWith', () async {
        final originalPost = Post(
          id: 'copywith_test_post',
          title: 'CopyWith Test',
          content: 'Testing copyWith with server timestamp',
          authorId: 'test_author',
          tags: ['copywith', 'test'],
          metadata: {'type': 'test'},
          createdAt: DateTime(2024),
        );

        await odm.posts(originalPost.id).update(originalPost);

        // Use copyWith with server timestamp
        await odm
            .posts(originalPost.id)
            .modify(
              (post) => post.copyWith(
                title: 'Updated with CopyWith',
                published: true,
                publishedAt: FirestoreODM.serverTimestamp,
                updatedAt: FirestoreODM.serverTimestamp,
                likes: 10,
              ),
            );

        final updated = await odm.posts(originalPost.id).get();
        expect(updated!.title, equals('Updated with CopyWith'));
        expect(updated.published, isTrue);
        expect(updated.likes, equals(10));
        expect(updated.publishedAt, isNotNull);
        expect(updated.updatedAt, isNotNull);

        final now = DateTime.now();
        expect(
          now.difference(updated.publishedAt!).abs().inMinutes,
          lessThan(1),
        );
        expect(now.difference(updated.updatedAt!).abs().inMinutes, lessThan(1));

        print('✅ Server timestamps work correctly with copyWith');
      });

      test('should handle rapid successive server timestamp updates', () async {
        final user = User(
          id: 'rapid_updates_user',
          name: 'Rapid Updates User',
          email: 'rapid@test.com',
          age: 30,
          profile: const Profile(
            bio: 'Rapid updates test',
            avatar: 'rapid.jpg',
            socialLinks: {},
            interests: ['speed'],
            followers: 100,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime(2024),
        );

        await odm.users(user.id).update(user);

        // Perform rapid successive updates with server timestamps
        final futures = List.generate(5, (i) async {
          await odm
              .users(user.id)
              .patch(
                ($) => [
                  $.lastLogin(FirestoreODM.serverTimestamp),
                  $.updatedAt(FirestoreODM.serverTimestamp),
                  $.age.increment(1),
                ],
              );
        });

        await Future.wait(futures);

        final updated = await odm.users(user.id).get();
        expect(updated!.age, equals(35)); // Should be incremented 5 times
        expect(updated.lastLogin, isNotNull);
        expect(updated.updatedAt, isNotNull);

        // Should have recent server timestamps
        final now = DateTime.now();
        expect(now.difference(updated.lastLogin!).abs().inMinutes, lessThan(1));
        expect(now.difference(updated.updatedAt!).abs().inMinutes, lessThan(1));

        print('✅ Rapid successive server timestamp updates work correctly');
        print('   Final age after 5 increments: ${updated.age}');
      });
    });
  });
}
