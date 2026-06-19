import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:test/test.dart';

void main() {
  group('Batch Nested Operations Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should support nested model updates in batch operations', () async {
      // Create a user with nested profile
      final user = User(
        id: 'nested_user',
        name: 'Nested User',
        email: 'nested@example.com',
        age: 30,
        profile: const Profile(
          bio: 'Original bio',
          avatar: 'original.jpg',
          socialLinks: {'twitter': '@original'},
          interests: ['coding'],
          followers: 100,
        ),
        rating: 4,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Insert user first
      await odm.users.insert(user);

      // Test batch update with nested model changes
      await odm.runBatch((batch) {
        batch.users.update(
          user.copyWith(
            name: 'Updated Name',
            profile: user.profile.copyWith(
              bio: 'Updated bio',
              followers: 200,
              socialLinks: {'twitter': '@updated', 'github': '@newuser'},
            ),
          ),
        );
      });

      // Verify nested changes
      final updatedUser = await odm.users('nested_user').get();
      expect(updatedUser?.name, equals('Updated Name'));
      expect(updatedUser?.profile.bio, equals('Updated bio'));
      expect(updatedUser?.profile.followers, equals(200));
      expect(updatedUser?.profile.socialLinks['twitter'], equals('@updated'));
      expect(updatedUser?.profile.socialLinks['github'], equals('@newuser'));
    });

    test('should support subcollection operations in batch', () async {
      // Create a user first
      final user = User(
        id: 'subcol_user',
        name: 'Subcollection User',
        email: 'subcol@example.com',
        age: 25,
        profile: const Profile(
          bio: 'User with posts',
          avatar: 'user.jpg',
          socialLinks: {},
          interests: ['writing'],
          followers: 50,
        ),
        rating: 3.5,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await odm.users.insert(user);

      // Test subcollection batch operations
      final post1 = Post(
        id: 'post1',
        title: 'First Post',
        content: 'Content of first post',
        authorId: 'subcol_user',
        metadata: {'category': 'tech'},
        likes: 10,
        published: true,
        createdAt: DateTime.now(),
        tags: ['test', 'batch'],
      );

      final post2 = Post(
        id: 'post2',
        title: 'Second Post',
        content: 'Content of second post',
        authorId: 'subcol_user',
        metadata: {'category': 'draft'},
        likes: 5,
        createdAt: DateTime.now(),
        tags: ['draft'],
      );

      // Test batch operations on subcollections
      await odm.runBatch((batch) {
        // Insert posts into user's subcollection
        batch.users('subcol_user').posts.insert(post1);
        batch.users('subcol_user').posts.insert(post2);

        // Update a post in the subcollection
        batch.users('subcol_user').posts.update(post1.copyWith(likes: 15));

        // Delete a post from the subcollection
        batch.users('subcol_user').posts('post2').delete();
      });

      // Verify the batch operations worked
      final userPosts = await odm.users('subcol_user').posts.get();
      expect(userPosts.length, equals(1));
      expect(userPosts.first.id, equals('post1'));
      expect(userPosts.first.likes, equals(15)); // Should be updated value
    });

    test(
      'should support patch operations with nested fields in batch',
      () async {
        // Create a user
        final user = User(
          id: 'patch_user',
          name: 'Patch User',
          email: 'patch@example.com',
          age: 28,
          profile: const Profile(
            bio: 'Original patch bio',
            avatar: 'patch.jpg',
            socialLinks: {'linkedin': '@patch'},
            interests: ['testing'],
            followers: 75,
          ),
          rating: 4.2,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users.insert(user);

        // Test batch patch with nested field updates
        await odm.runBatch((batch) {
          batch
              .users('patch_user')
              .patch(
                ($) => [
                  $.name('Patched Name'),
                  $.age(29),
                  $.profile.bio('Patched bio'),
                  $.profile.followers(100),
                  $.profile.socialLinks.set('github', '@patched'),
                ],
              );
        });

        // Verify patch changes
        final patchedUser = await odm.users('patch_user').get();
        expect(patchedUser?.name, equals('Patched Name'));
        expect(patchedUser?.age, equals(29));
        expect(patchedUser?.profile.bio, equals('Patched bio'));
        expect(patchedUser?.profile.followers, equals(100));
        expect(patchedUser?.profile.socialLinks['github'], equals('@patched'));
        expect(
          patchedUser?.profile.socialLinks['linkedin'],
          equals('@patch'),
        ); // Should be preserved
      },
    );
  });
}
