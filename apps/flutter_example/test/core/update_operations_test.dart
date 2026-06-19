import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 Core Update Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📝 Array-Style Updates', () {
      test('should perform basic field updates', () async {
        final user = User(
          id: 'array_update_user',
          name: 'Original Name',
          email: 'original@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Original bio',
            avatar: 'original.jpg',
            socialLinks: {'github': 'original'},
            interests: ['original'],
            followers: 100,
          ),
          rating: 3,
          tags: ['original'],
          scores: [80, 85],
          settings: {'theme': 'light'},
          metadata: {'version': 1},
          createdAt: DateTime.now(),
        );

        await odm.users('array_update_user').update(user);

        await odm
            .users('array_update_user')
            .patch(
              ($) => [
                $.name('Updated Name'),
                $.age.increment(1),
                $.rating.increment(0.5),
                $.isActive(true),
                $.tags.add('updated'),
                $.profile.followers.increment(50),
              ],
            );

        final updated = await odm.users('array_update_user').get();

        expect(updated, isNotNull);
        expect(updated!.name, equals('Updated Name'));
        expect(updated.age, equals(26));
        expect(updated.rating, equals(3.5));
        expect(updated.isActive, isTrue);
        expect(updated.tags, contains('updated'));
        expect(updated.profile.followers, equals(150));
      });

      test('should handle server timestamps in array updates', () async {
        final user = User(
          id: 'timestamp_user',
          name: 'Timestamp User',
          email: 'timestamp@example.com',
          age: 30,
          profile: const Profile(
            bio: 'Timestamp test',
            avatar: 'timestamp.jpg',
            socialLinks: {},
            interests: ['timestamps'],
            followers: 100,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users('timestamp_user').update(user);

        await odm
            .users('timestamp_user')
            .patch(
              ($) => [
                $.lastLogin.serverTimestamp(),
                $.updatedAt.serverTimestamp(),
              ],
            );

        final updated = await odm.users('timestamp_user').get();

        expect(updated, isNotNull);
        expect(updated!.lastLogin, isNotNull);
        expect(updated.updatedAt, isNotNull);
      });
    });

    group('🔄 Modify Operations', () {
      test('should perform diff-based updates', () async {
        final user = User(
          id: 'modify_user',
          name: 'Modify User',
          email: 'modify@example.com',
          age: 28,
          profile: const Profile(
            bio: 'Original bio',
            avatar: 'modify.jpg',
            socialLinks: {},
            interests: ['modify'],
            followers: 200,
          ),
          rating: 3.5,
          createdAt: DateTime.now(),
        );

        await odm.users('modify_user').update(user);

        await odm
            .users('modify_user')
            .modify(
              (user) => user.copyWith(
                name: 'Modified Name',
                isActive: true,
                profile: user.profile.copyWith(
                  bio: 'Modified bio',
                  followers: 250,
                ),
                lastLogin: FirestoreODM.serverTimestamp,
              ),
            );

        final updated = await odm.users('modify_user').get();

        expect(updated, isNotNull);
        expect(updated!.name, equals('Modified Name'));
        expect(updated.isActive, isTrue);
        expect(updated.profile.bio, equals('Modified bio'));
        expect(updated.profile.followers, equals(250));
        expect(updated.lastLogin, isNotNull);
      });
    });

    group('⚡ Incremental Modify Operations', () {
      test('should auto-detect atomic operations', () async {
        final user = User(
          id: 'incremental_user',
          name: 'Incremental User',
          email: 'incremental@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Incremental test',
            avatar: 'incremental.jpg',
            socialLinks: {},
            interests: ['incremental'],
            followers: 100,
          ),
          rating: 3,
          isActive: true,
          tags: ['original'],
          scores: [90, 85],
          createdAt: DateTime.now(),
        );

        await odm.users('incremental_user').update(user);

        await odm
            .users('incremental_user')
            .modify(
              (user) => user.copyWith(
                age: user.age + 1, // Auto-increment
                rating: user.rating + 0.5, // Auto-increment
                profile: user.profile.copyWith(
                  followers: user.profile.followers + 25, // Auto-increment
                  interests: [
                    ...user.profile.interests,
                    'atomic',
                  ], // Auto-arrayUnion
                ),
                tags: [...user.tags, 'incremented'], // Auto-arrayUnion
                lastLogin: FirestoreODM.serverTimestamp, // Server timestamp
              ),
            );

        final updated = await odm.users('incremental_user').get();

        expect(updated, isNotNull);
        expect(updated!.age, equals(26));
        expect(updated.rating, equals(3.5));
        expect(updated.profile.followers, equals(125));
        expect(updated.profile.interests, contains('atomic'));
        expect(updated.tags, contains('incremented'));
        expect(updated.lastLogin, isNotNull);
      });

      test('should handle array removals in incremental modify', () async {
        final user = User(
          id: 'array_removal_user',
          name: 'Array Removal User',
          email: 'removal@example.com',
          age: 30,
          profile: const Profile(
            bio: 'Array removal test',
            avatar: 'removal.jpg',
            socialLinks: {},
            interests: ['keep', 'remove', 'also_keep'],
            followers: 150,
          ),
          rating: 4,
          isActive: true,
          tags: ['tag1', 'tag2', 'tag3'],
          scores: [95, 88, 92],
          createdAt: DateTime.now(),
        );

        await odm.users('array_removal_user').update(user);

        await odm
            .users('array_removal_user')
            .modify(
              (user) => user.copyWith(
                profile: user.profile.copyWith(
                  interests: user.profile.interests
                      .where((interest) => interest != 'remove')
                      .toList(),
                ),
                tags: user.tags.where((tag) => tag != 'tag2').toList(),
                scores: user.scores.where((score) => score >= 90).toList(),
              ),
            );

        final updated = await odm.users('array_removal_user').get();

        expect(updated, isNotNull);
        expect(updated!.profile.interests, isNot(contains('remove')));
        expect(updated.profile.interests, contains('keep'));
        expect(updated.profile.interests, contains('also_keep'));
        expect(updated.tags, isNot(contains('tag2')));
        expect(updated.tags, contains('tag1'));
        expect(updated.tags, contains('tag3'));
        expect(updated.scores, equals([95, 92]));
      });
    });

    group('🔗 Nested Object Updates', () {
      test('should update nested profile fields', () async {
        final user = User(
          id: 'nested_update_user',
          name: 'Nested Update User',
          email: 'nested@example.com',
          age: 32,
          profile: const Profile(
            bio: 'Original nested bio',
            avatar: 'nested.jpg',
            socialLinks: {
              'github': 'https://github.com/original',
              'twitter': 'https://twitter.com/original',
            },
            interests: ['nested', 'updates'],
            followers: 300,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users('nested_update_user').update(user);

        await odm
            .users('nested_update_user')
            .patch(
              ($) => [
                $.profile.bio('Updated nested bio'),
                $.profile.avatar('updated_nested.jpg'),
                $.profile.followers.increment(100),
              ],
            );

        final updated = await odm.users('nested_update_user').get();

        expect(updated, isNotNull);
        expect(updated!.profile.bio, equals('Updated nested bio'));
        expect(updated.profile.avatar, equals('updated_nested.jpg'));
        expect(updated.profile.followers, equals(400));
        // Other fields should remain unchanged
        expect(
          updated.profile.socialLinks['github'],
          equals('https://github.com/original'),
        );
      });

      test('should handle complex nested updates with modify', () async {
        final user = User(
          id: 'complex_nested_user',
          name: 'Complex Nested User',
          email: 'complex@example.com',
          age: 35,
          profile: const Profile(
            bio: 'Complex nested test',
            avatar: 'complex.jpg',
            socialLinks: {
              'github': 'https://github.com/complex',
              'linkedin': 'https://linkedin.com/in/complex',
            },
            interests: ['complex', 'nested'],
            followers: 500,
          ),
          rating: 4.8,
          isActive: true,
          isPremium: true,
          settings: {'theme': 'dark', 'notifications': 'enabled'},
          metadata: {'level': 'expert', 'badge_count': 15},
          createdAt: DateTime.now(),
        );

        await odm.users('complex_nested_user').update(user);

        await odm
            .users('complex_nested_user')
            .modify(
              (user) => user.copyWith(
                profile: user.profile.copyWith(
                  socialLinks: {
                    ...user.profile.socialLinks,
                    'youtube': 'https://youtube.com/complex',
                    'github':
                        'https://github.com/updated_complex', // Update existing
                  },
                  interests: [...user.profile.interests, 'youtube'],
                ),
                settings: {...user.settings, 'new_feature': 'enabled'},
                metadata: {...user.metadata, 'badge_count': 20},
              ),
            );

        final updated = await odm.users('complex_nested_user').get();

        expect(updated, isNotNull);
        expect(
          updated!.profile.socialLinks['youtube'],
          equals('https://youtube.com/complex'),
        );
        expect(
          updated.profile.socialLinks['github'],
          equals('https://github.com/updated_complex'),
        );
        expect(
          updated.profile.socialLinks['linkedin'],
          equals('https://linkedin.com/in/complex'),
        );
        expect(updated.profile.interests, contains('youtube'));
        expect(updated.settings['new_feature'], equals('enabled'));
        expect(updated.metadata['badge_count'], equals(20));
      });
    });

    group('🕐 Server Timestamp Support', () {
      test(
        'should use FirestoreODM.serverTimestamp in patch operations',
        () async {
          final user = User(
            id: 'server_timestamp_user',
            name: 'Server Timestamp User',
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
            createdAt: DateTime(2024),
          );

          await odm.users(user.id).update(user);

          // Use server timestamp in patch
          await odm
              .users(user.id)
              .patch(
                ($) => [
                  $.lastLogin(FirestoreODM.serverTimestamp),
                  $.updatedAt(FirestoreODM.serverTimestamp),
                  $.name('Updated with Server Timestamp'),
                ],
              );

          final updated = await odm.users(user.id).get();
          expect(updated!.name, equals('Updated with Server Timestamp'));
          expect(updated.lastLogin, isNotNull);
          expect(updated.updatedAt, isNotNull);

          // Server timestamps should be recent
          final now = DateTime.now();
          expect(
            now.difference(updated.lastLogin!).abs().inMinutes,
            lessThan(1),
          );
          expect(
            now.difference(updated.updatedAt!).abs().inMinutes,
            lessThan(1),
          );

          print('✅ Server timestamps work in patch operations');
        },
      );

      test(
        'should use FirestoreODM.serverTimestamp in modify operations',
        () async {
          final post = Post(
            id: 'server_timestamp_post',
            title: 'Server Timestamp Post',
            content: 'Testing server timestamps in modify',
            authorId: 'test_author',
            tags: ['timestamp', 'test'],
            metadata: {},
            createdAt: DateTime(2024),
          );

          await odm.posts(post.id).update(post);

          // Use server timestamp in modify
          await odm
              .posts(post.id)
              .modify(
                (post) => post.copyWith(
                  title: 'Updated with Server Timestamp',
                  published: true,
                  publishedAt: FirestoreODM.serverTimestamp,
                  updatedAt: FirestoreODM.serverTimestamp,
                ),
              );

          final updated = await odm.posts(post.id).get();
          expect(updated!.title, equals('Updated with Server Timestamp'));
          expect(updated.published, isTrue);
          expect(updated.publishedAt, isNotNull);
          expect(updated.updatedAt, isNotNull);

          // Server timestamps should be recent
          final now = DateTime.now();
          expect(
            now.difference(updated.publishedAt!).abs().inMinutes,
            lessThan(1),
          );
          expect(
            now.difference(updated.updatedAt!).abs().inMinutes,
            lessThan(1),
          );

          print('✅ Server timestamps work in modify operations');
        },
      );
    });
  });
}
