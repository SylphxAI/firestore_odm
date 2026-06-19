import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/simple_story.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 Default ID Fallback Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📋 Models Without @DocumentIdField Annotation', () {
      test(
        'SimpleStory model: ODM operations with automatic ID field detection',
        () async {
          // SimpleStory has 'id' field but no @DocumentIdField annotation
          // ODM should automatically detect 'id' field as document ID
          const storyId = 'simple_story_123';

          final story = SimpleStory(
            id: storyId,
            title: 'Default ID Test Story',
            content: 'Testing ODM with automatic ID field detection',
            authorId: 'test_author_123',
            tags: ['testing', 'automatic-id'],
            createdAt: DateTime.now(),
          );

          // Create using our ODM - should work with automatic ID detection
          await odm.simpleStories(storyId).update(story);

          // Retrieve using our ODM
          final retrievedStory = await odm.simpleStories(storyId).get();
          expect(retrievedStory, isNotNull);
          expect(retrievedStory!.id, equals(storyId));
          expect(retrievedStory.title, equals('Default ID Test Story'));
          expect(retrievedStory.authorId, equals('test_author_123'));

          // Update using our ODM
          final updatedStory = story.copyWith(
            title: 'Updated Default ID Story',
          );
          await odm.simpleStories(storyId).update(updatedStory);

          final finalStory = await odm.simpleStories(storyId).get();
          expect(finalStory!.title, equals('Updated Default ID Story'));
          expect(finalStory.id, equals(storyId)); // ID should remain the same

          // Delete using our ODM
          await odm.simpleStories(storyId).delete();

          final deletedStory = await odm.simpleStories(storyId).get();
          expect(deletedStory, isNull);
        },
      );

      test(
        'SimpleStory vs User: Compare ODM behavior with/without @DocumentIdField',
        () async {
          const storyId = 'comparison_story';
          const userId = 'comparison_user';

          // Create SimpleStory (has 'id' field but no @DocumentIdField)
          final story = SimpleStory(
            id: storyId,
            title: 'Comparison Story',
            content: 'Testing behavior differences',
            authorId: 'comparison_author_123',
            tags: ['comparison', 'test'],
            createdAt: DateTime.now(),
          );

          await odm.simpleStories(storyId).update(story);

          // Create User (has @DocumentIdField)
          final user = User(
            id: userId, // Explicit ID field with @DocumentIdField
            name: 'Comparison User',
            email: 'comparison@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Testing annotation differences',
              avatar: 'comparison.jpg',
              socialLinks: {},
              interests: ['comparison'],
              followers: 100,
            ),
            rating: 4,
            isActive: true,
            createdAt: DateTime.now(),
          );

          await odm.users(userId).update(user);

          // Both should work with our ODM
          final retrievedStory = await odm.simpleStories(storyId).get();
          final retrievedUser = await odm.users(userId).get();

          expect(retrievedStory, isNotNull);
          expect(retrievedStory!.id, equals(storyId));
          expect(retrievedStory.title, equals('Comparison Story'));

          expect(retrievedUser, isNotNull);
          expect(retrievedUser!.id, equals(userId));
          expect(retrievedUser.name, equals('Comparison User'));

          // Query by fields (both should work)
          final storyQuery = await odm.simpleStories
              .where(
                (filter) => filter.authorId(isEqualTo: 'comparison_author_123'),
              )
              .get();

          final userQuery = await odm.users
              .where((filter) => filter.name(isEqualTo: 'Comparison User'))
              .get();

          expect(storyQuery.length, equals(1));
          expect(storyQuery[0].title, equals('Comparison Story'));

          expect(userQuery.length, equals(1));
          expect(userQuery[0].id, equals(userId));
        },
      );

      test(
        'SimpleStory ordering and pagination without @DocumentIdField',
        () async {
          // Create multiple stories to test ordering with automatic ID detection
          final now = DateTime.now();
          final stories = [
            SimpleStory(
              id: 'story_c',
              title: 'Story C',
              content: 'Third story by title',
              authorId: 'author_alpha',
              tags: ['test'],
              createdAt: now.subtract(const Duration(days: 1)),
            ),
            SimpleStory(
              id: 'story_a',
              title: 'Story A',
              content: 'First story by title',
              authorId: 'author_beta',
              tags: ['test'],
              createdAt: now.subtract(const Duration(days: 3)),
            ),
            SimpleStory(
              id: 'story_b',
              title: 'Story B',
              content: 'Second story by title',
              authorId: 'author_gamma',
              tags: ['test'],
              createdAt: now.subtract(const Duration(days: 2)),
            ),
          ];

          // Create all stories using our ODM
          for (final story in stories) {
            await odm.simpleStories(story.id).update(story);
          }

          // Test ordering by title
          final orderedByTitle = await odm.simpleStories
              .orderBy(($) => ($.title(),))
              .get();

          expect(orderedByTitle.length, equals(3));
          expect(orderedByTitle[0].title, equals('Story A'));
          expect(orderedByTitle[1].title, equals('Story B'));
          expect(orderedByTitle[2].title, equals('Story C'));

          // Test ordering by createdAt
          final orderedByDate = await odm.simpleStories
              .orderBy(($) => ($.createdAt(descending: true),)) // descending
              .get();

          expect(orderedByDate.length, equals(3));
          // Most recent first (story_c was created most recently)
          expect(orderedByDate[0].id, equals('story_c'));

          // Test ordering by ID field (should work with automatic detection)
          final orderedById = await odm.simpleStories
              .orderBy(($) => ($.id(),))
              .get();

          expect(orderedById.length, equals(3));
          expect(orderedById[0].id, equals('story_a'));
          expect(orderedById[1].id, equals('story_b'));
          expect(orderedById[2].id, equals('story_c'));

          // Test pagination with tuple cursors
          final paginatedQuery = await odm.simpleStories
              .orderBy(($) => ($.title(),))
              .startAt(('Story B',))
              .limit(2)
              .get();

          expect(paginatedQuery.length, equals(2));
          expect(paginatedQuery[0].title, equals('Story B'));
          expect(paginatedQuery[1].title, equals('Story C'));
        },
      );

      test('SimpleStory complex queries with automatic ID detection', () async {
        // Test that complex operations work with automatic ID field detection
        const authorId = 'complex_query_author';
        final now = DateTime.now();

        final stories = [
          SimpleStory(
            id: 'recent_story',
            title: 'Recent Story',
            content: 'This story was created recently',
            authorId: authorId,
            tags: ['recent', 'published'],
            createdAt: now,
          ),
          SimpleStory(
            id: 'draft_story',
            title: 'Draft Story',
            content: 'This story is a draft',
            authorId: authorId,
            tags: ['draft'],
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
          SimpleStory(
            id: 'old_story',
            title: 'Old Story',
            content: 'This story was created long ago',
            authorId: authorId,
            tags: ['old', 'published'],
            createdAt: now.subtract(const Duration(days: 30)),
          ),
        ];

        // Create stories using our ODM
        for (final story in stories) {
          await odm.simpleStories(story.id).update(story);
        }

        // Query by authorId
        final authorStories = await odm.simpleStories
            .where((filter) => filter.authorId(isEqualTo: authorId))
            .get();

        expect(authorStories.length, equals(3));

        // Query published stories only (using tag filtering)
        final publishedStories = await odm.simpleStories
            .where((filter) => filter.authorId(isEqualTo: authorId))
            .where((filter) => filter.tags(arrayContains: 'published'))
            .orderBy(($) => ($.createdAt(descending: true),))
            .get();

        expect(publishedStories.length, equals(2));
        expect(publishedStories[0].id, equals('recent_story')); // Most recent
        expect(publishedStories[1].id, equals('old_story'));

        // Complex multi-field ordering including ID field
        final complexQuery = await odm.simpleStories
            .where((filter) => filter.authorId(isEqualTo: authorId))
            .orderBy(($) => ($.authorId(), $.id()))
            .get();

        expect(complexQuery.length, equals(3));
        // Should be ordered by authorId (same), then by id alphabetically
        expect(complexQuery[0].id, equals('draft_story'));
        expect(complexQuery[1].id, equals('old_story'));
        expect(complexQuery[2].id, equals('recent_story'));

        // Test filtering by ID field (should work with automatic detection)
        final storyById = await odm.simpleStories
            .where((filter) => filter.id(isEqualTo: 'recent_story'))
            .get();

        expect(storyById.length, equals(1));
        expect(storyById[0].title, equals('Recent Story'));
      });
    });

    group('🔍 Mixed Annotation Scenarios', () {
      test('Mixing annotated and non-annotated models in same ODM', () async {
        const userId = 'mixed_user_123';
        const postId = 'mixed_post_456';
        const storyId = 'mixed_story_789';

        // User and Post have @DocumentIdField, SimpleStory has automatic detection
        final user = User(
          id: userId,
          name: 'Mixed Test User',
          email: 'mixed@example.com',
          age: 28,
          profile: const Profile(
            bio: 'Testing mixed scenarios',
            avatar: 'mixed.jpg',
            socialLinks: {},
            interests: ['mixed', 'testing'],
            followers: 150,
          ),
          rating: 4.2,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        final post = Post(
          id: postId,
          title: 'Mixed Test Post',
          content: 'Testing mixed annotation scenarios',
          authorId: userId,
          tags: ['mixed', 'test'],
          metadata: {'test': 'mixed'},
          likes: 25,
          views: 250,
          published: true,
          createdAt: DateTime.now(),
        );

        final story = SimpleStory(
          id: storyId,
          title: 'Mixed Test Story',
          content: 'Testing story with automatic ID detection',
          authorId: userId,
          tags: ['mixed', 'automatic'],
          createdAt: DateTime.now(),
        );

        // All should work with our ODM
        await odm.users(userId).update(user);
        await odm.posts(postId).update(post);
        await odm.simpleStories(storyId).update(story);

        // All should be retrievable
        final retrievedUser = await odm.users(userId).get();
        final retrievedPost = await odm.posts(postId).get();
        final retrievedStory = await odm.simpleStories(storyId).get();

        expect(retrievedUser!.id, equals(userId));
        expect(retrievedPost!.id, equals(postId));
        expect(retrievedStory!.id, equals(storyId));

        // All should support querying, including by ID field
        final userResults = await odm.users
            .where((filter) => filter.id(isEqualTo: userId))
            .get();

        final postResults = await odm.posts
            .where((filter) => filter.id(isEqualTo: postId))
            .get();

        final storyResults = await odm.simpleStories
            .where((filter) => filter.id(isEqualTo: storyId))
            .get();

        expect(userResults.length, equals(1));
        expect(postResults.length, equals(1));
        expect(storyResults.length, equals(1));

        // All should support ordering by ID
        final orderedUsers = await odm.users.orderBy(($) => ($.id(),)).get();
        final orderedPosts = await odm.posts.orderBy(($) => ($.id(),)).get();
        final orderedStories = await odm.simpleStories
            .orderBy(($) => ($.id(),))
            .get();

        expect(orderedUsers.length, greaterThanOrEqualTo(1));
        expect(orderedPosts.length, greaterThanOrEqualTo(1));
        expect(orderedStories.length, greaterThanOrEqualTo(1));
      });

      test('Subcollections with mixed annotation models', () async {
        const userId = 'subcol_mixed_user';
        const postId = 'subcol_mixed_post';

        // User has @DocumentIdField, create in main collection
        final user = User(
          id: userId,
          name: 'Subcollection Mixed User',
          email: 'subcol@example.com',
          age: 32,
          profile: const Profile(
            bio: 'Testing subcollections with mixed annotations',
            avatar: 'subcol.jpg',
            socialLinks: {},
            interests: ['subcollections'],
            followers: 300,
          ),
          rating: 4.5,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users(userId).update(user);

        // Post has @DocumentIdField, create in subcollection
        final post = Post(
          id: postId,
          title: 'Subcollection Mixed Post',
          content: 'Testing post in user subcollection',
          authorId: userId,
          tags: ['subcollection', 'mixed'],
          metadata: {'parent': userId},
          likes: 15,
          views: 150,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.users(userId).posts(postId).update(post);

        // Verify both work correctly
        final retrievedUser = await odm.users(userId).get();
        final retrievedPost = await odm.users(userId).posts(postId).get();

        expect(retrievedUser!.id, equals(userId));
        expect(retrievedPost!.id, equals(postId));
        expect(retrievedPost.authorId, equals(userId));

        // Query subcollection by ID field
        final userPostsById = await odm
            .users(userId)
            .posts
            .where((filter) => filter.id(isEqualTo: postId))
            .get();

        expect(userPostsById.length, equals(1));
        expect(userPostsById[0].id, equals(postId));
      });

      test(
        'Verify document ID field detection priority works correctly',
        skip:
            'Skip this test due to fake_cloud_firestore compatibility issues with FieldPathType',
        () async {
          // This test verifies that our TypeAnalyzer properly detects ID fields
          // User: has @DocumentIdField annotation on 'id' field
          // Post: has @DocumentIdField annotation on 'id' field
          // SimpleStory: has 'id' field but no annotation (should be auto-detected)

          const userId = 'detection_user';
          const postId = 'detection_post';
          const storyId = 'detection_story';

          final user = User(
            id: userId,
            name: 'Detection Test',
            email: 'detection@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Testing ID detection',
              avatar: 'detection.jpg',
              socialLinks: {},
              interests: ['detection'],
              followers: 50,
            ),
            rating: 3.5,
            isActive: true,
            createdAt: DateTime.now(),
          );

          final post = Post(
            id: postId,
            title: 'Detection Test Post',
            content: 'Testing ID field detection',
            authorId: userId,
            tags: ['detection'],
            metadata: {},
            likes: 5,
            views: 50,
            published: true,
            createdAt: DateTime.now(),
          );

          final story = SimpleStory(
            id: storyId,
            title: 'Detection Test Story',
            content: 'Testing story ID detection',
            authorId: 'detection_author',
            tags: ['detection', 'automatic'],
            createdAt: DateTime.now(),
          );

          // All operations should work seamlessly
          await odm.users(userId).update(user);
          await odm.posts(postId).update(post);
          await odm.simpleStories(storyId).update(story);

          // ID field queries should work for all models
          final userById = await odm.users
              .where((filter) => filter.id(isEqualTo: userId))
              .get();

          final postById = await odm.posts
              .where((filter) => filter.id(isEqualTo: postId))
              .get();

          final storyById = await odm.simpleStories
              .where((filter) => filter.id(isEqualTo: storyId))
              .get();

          expect(userById.length, equals(1));
          expect(userById[0].id, equals(userId));
          expect(postById.length, equals(1));
          expect(postById[0].id, equals(postId));
          expect(storyById.length, equals(1));
          expect(storyById[0].id, equals(storyId));

          // All should support pagination with ID cursors
          final paginatedUsers = await odm.users
              .orderBy(($) => ($.id(),))
              .startAt((userId,))
              .limit(1)
              .get();

          final paginatedPosts = await odm.posts
              .orderBy(($) => ($.id(),))
              .startAt((postId,))
              .limit(1)
              .get();

          final paginatedStories = await odm.simpleStories
              .orderBy(($) => ($.id(),))
              .startAt((storyId,))
              .limit(1)
              .get();

          expect(paginatedUsers.length, equals(1));
          expect(paginatedPosts.length, equals(1));
          expect(paginatedStories.length, equals(1));

          print('✅ Document ID field detection working correctly:');
          print('  - @DocumentIdField annotation: User, Post');
          print('  - Automatic detection: SimpleStory');
          print('  - All support ID field queries and ordering');
        },
      );
    });
  });
}
