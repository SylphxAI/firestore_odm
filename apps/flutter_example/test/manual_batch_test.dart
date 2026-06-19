import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Manual Batch Operations Test', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(const TestSchema(), firestore: firestore);
    });

    test('should support manual batch creation and commit', () async {
      // Create batch manually
      final batch = odm.batch();

      // Create test data
      final user1 = User(
        id: 'manual_user_1',
        name: 'Manual User 1',
        email: 'manual1@example.com',
        age: 25,
        profile: const Profile(
          bio: 'Manual batch test user 1',
          avatar: 'avatar1.jpg',
          socialLinks: {'twitter': '@manual1'},
          interests: ['testing', 'batch'],
          followers: 100,
        ),
        rating: 4.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final user2 = User(
        id: 'manual_user_2',
        name: 'Manual User 2',
        email: 'manual2@example.com',
        age: 30,
        profile: const Profile(
          bio: 'Manual batch test user 2',
          avatar: 'avatar2.jpg',
          socialLinks: {'github': '@manual2'},
          interests: ['development', 'testing'],
          followers: 200,
        ),
        rating: 4.8,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
      );

      final post = Post(
        id: 'manual_post_1',
        title: 'Manual Batch Post',
        content: 'This post was created using manual batch',
        authorId: 'manual_user_1',
        likes: 50,
        published: true,
        createdAt: DateTime.now(),
        tags: ['manual', 'batch', 'test'],
        metadata: {'source': 'manual_batch_test'},
      );

      // Add operations to batch
      batch.users.insert(user1);
      batch.users.insert(user2);
      batch.posts.insert(post);

      // Update user1
      final updatedUser1 = user1.copyWith(
        name: 'Updated Manual User 1',
        age: 26,
      );
      batch.users.update(updatedUser1);

      // Commit the batch manually
      await batch.commit();

      // Verify the operations were successful
      final retrievedUser1 = await odm.users('manual_user_1').get();
      final retrievedUser2 = await odm.users('manual_user_2').get();
      final retrievedPost = await odm.posts('manual_post_1').get();

      expect(retrievedUser1, isNotNull);
      expect(retrievedUser1!.name, equals('Updated Manual User 1'));
      expect(retrievedUser1.age, equals(26));

      expect(retrievedUser2, isNotNull);
      expect(retrievedUser2!.name, equals('Manual User 2'));
      expect(retrievedUser2.isPremium, isTrue);

      expect(retrievedPost, isNotNull);
      expect(retrievedPost!.title, equals('Manual Batch Post'));
      expect(retrievedPost.authorId, equals('manual_user_1'));
    });

    test('should support manual batch with subcollections', () async {
      // Create batch manually
      final batch = odm.batch();

      // Create test user
      final user = User(
        id: 'manual_subcol_user',
        name: 'Manual Subcol User',
        email: 'subcol@example.com',
        age: 28,
        profile: const Profile(
          bio: 'Manual subcollection test',
          avatar: 'subcol.jpg',
          socialLinks: {},
          interests: ['subcollections'],
          followers: 150,
        ),
        rating: 4.2,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final userPost1 = Post(
        id: 'manual_user_post_1',
        title: 'Manual User Post 1',
        content: 'First post in user subcollection',
        authorId: 'manual_subcol_user',
        likes: 25,
        published: true,
        createdAt: DateTime.now(),
        tags: ['user', 'subcollection'],
        metadata: {'type': 'user_post', 'order': 1},
      );

      final userPost2 = Post(
        id: 'manual_user_post_2',
        title: 'Manual User Post 2',
        content: 'Second post in user subcollection',
        authorId: 'manual_subcol_user',
        likes: 35,
        published: true,
        createdAt: DateTime.now(),
        tags: ['user', 'subcollection', 'manual'],
        metadata: {'type': 'user_post', 'order': 2},
      );

      // Add operations to batch
      batch.users.insert(user);
      batch.users('manual_subcol_user').posts.insert(userPost1);
      batch.users('manual_subcol_user').posts.insert(userPost2);

      // Update one of the user posts
      final updatedUserPost1 = userPost1.copyWith(
        title: 'Updated Manual User Post 1',
        likes: 30,
      );
      batch.users('manual_subcol_user').posts.update(updatedUserPost1);

      // Commit the batch manually
      await batch.commit();

      // Verify the operations were successful
      final retrievedUser = await odm.users('manual_subcol_user').get();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.name, equals('Manual Subcol User'));

      final userPosts = await odm.users('manual_subcol_user').posts.get();
      expect(userPosts.length, equals(2));

      final retrievedPost1 = userPosts.firstWhere(
        (p) => p.id == 'manual_user_post_1',
      );
      expect(retrievedPost1.title, equals('Updated Manual User Post 1'));
      expect(retrievedPost1.likes, equals(30));

      final retrievedPost2 = userPosts.firstWhere(
        (p) => p.id == 'manual_user_post_2',
      );
      expect(retrievedPost2.title, equals('Manual User Post 2'));
      expect(retrievedPost2.likes, equals(35));
    });

    test('should support manual batch with patch operations', () async {
      // Create batch manually
      final batch = odm.batch();

      // Create test user
      final user = User(
        id: 'manual_patch_user',
        name: 'Manual Patch User',
        email: 'patch@example.com',
        age: 32,
        profile: const Profile(
          bio: 'Original bio',
          avatar: 'patch.jpg',
          socialLinks: {'twitter': '@original'},
          interests: ['patching'],
          followers: 75,
        ),
        rating: 3.8,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Insert user first
      batch.users.insert(user);

      // Apply patch operations
      batch
          .users('manual_patch_user')
          .patch(
            ($) => [
              $.name('Patched Manual User'),
              $.age(33),
              $.profile.bio('Patched bio using manual batch'),
              $.profile.followers(100),
              $.profile.socialLinks.set('github', '@patched'),
              $.isPremium(true),
            ],
          );

      // Commit the batch manually
      await batch.commit();

      // Verify the patch operations were successful
      final retrievedUser = await odm.users('manual_patch_user').get();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.name, equals('Patched Manual User'));
      expect(retrievedUser.age, equals(33));
      expect(
        retrievedUser.profile.bio,
        equals('Patched bio using manual batch'),
      );
      expect(retrievedUser.profile.followers, equals(100));
      expect(retrievedUser.profile.socialLinks['github'], equals('@patched'));
      expect(retrievedUser.isPremium, isTrue);
    });

    test('should support both manual and runBatch approaches', () async {
      // Test that both approaches work and produce the same results

      // Approach 1: Manual batch
      final manualBatch = odm.batch();
      final user1 = User(
        id: 'approach_test_1',
        name: 'Manual Approach',
        email: 'manual@approach.com',
        age: 25,
        profile: const Profile(
          bio: 'Manual approach test',
          avatar: 'manual.jpg',
          socialLinks: {},
          interests: ['manual'],
          followers: 50,
        ),
        rating: 4,
        isActive: true,
        createdAt: DateTime.now(),
      );
      manualBatch.users.insert(user1);
      await manualBatch.commit();

      // Approach 2: runBatch
      final user2 = User(
        id: 'approach_test_2',
        name: 'RunBatch Approach',
        email: 'runbatch@approach.com',
        age: 27,
        profile: const Profile(
          bio: 'RunBatch approach test',
          avatar: 'runbatch.jpg',
          socialLinks: {},
          interests: ['runbatch'],
          followers: 75,
        ),
        rating: 4.2,
        isActive: true,
        isPremium: true,
        createdAt: DateTime.now(),
      );
      await odm.runBatch((batch) {
        batch.users.insert(user2);
      });

      // Verify both approaches worked
      final retrievedUser1 = await odm.users('approach_test_1').get();
      final retrievedUser2 = await odm.users('approach_test_2').get();

      expect(retrievedUser1, isNotNull);
      expect(retrievedUser1!.name, equals('Manual Approach'));

      expect(retrievedUser2, isNotNull);
      expect(retrievedUser2!.name, equals('RunBatch Approach'));
    });
  });
}
