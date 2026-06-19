import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/comment.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🪆 Nested Subcollections Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📁 Collection Path Verification', () {
      test('should have correct paths for all comment collections', () {
        // Root comments collection
        expect(odm.comments.query.path, equals('comments'));

        // Comments on main posts collection
        expect(
          odm.posts('post_id').comments.query.path,
          equals('posts/post_id/comments'),
        );

        // Comments on user posts (deeply nested)
        expect(
          odm.users('user_id').posts('post_id').comments.query.path,
          equals('users/user_id/posts/post_id/comments'),
        );
      });

      test(
        'should access nested collections through proper parent documents',
        () {
          final userDoc = odm.users('test_user');
          final postDoc = userDoc.posts('test_post');
          final commentsCollection = postDoc.comments;

          expect(userDoc.ref.path, equals('users/test_user'));
          expect(postDoc.ref.path, equals('users/test_user/posts/test_post'));
          expect(
            commentsCollection.query.path,
            equals('users/test_user/posts/test_post/comments'),
          );
        },
      );
    });

    group('💬 Root Level Comments', () {
      test('should create and retrieve root level comments', () async {
        final comment = Comment(
          id: 'root_comment_1',
          content: 'This is a root level comment',
          authorId: 'author_1',
          authorName: 'Root Author',
          postId: 'general_post',
          likes: 5,
          createdAt: DateTime.now(),
        );

        await odm.comments('root_comment_1').update(comment);

        final retrieved = await odm.comments('root_comment_1').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.content, equals('This is a root level comment'));
        expect(retrieved.authorName, equals('Root Author'));
      });

      test('should query root level comments', () async {
        final comments = [
          Comment(
            id: 'root_1',
            content: 'Root comment 1',
            authorId: 'author_1',
            authorName: 'Author One',
            postId: 'post_1',
            likes: 10,
            createdAt: DateTime.now(),
          ),
          Comment(
            id: 'root_2',
            content: 'Root comment 2',
            authorId: 'author_2',
            authorName: 'Author Two',
            postId: 'post_1',
            likes: 15,
            createdAt: DateTime.now(),
          ),
        ];

        for (final comment in comments) {
          await odm.comments(comment.id).update(comment);
        }

        final postComments = await odm.comments
            .where(($) => $.postId(isEqualTo: 'post_1'))
            .get();

        expect(postComments.length, equals(2));
        expect(
          postComments.map((c) => c.id).toSet(),
          equals({'root_1', 'root_2'}),
        );
      });
    });

    group('📝 Comments on Main Posts', () {
      test(
        'should create and access comments on main posts collection',
        () async {
          // Create a post in main collection
          final post = Post(
            id: 'main_post_1',
            title: 'Main Post with Comments',
            content: 'This post will have comments',
            authorId: 'post_author',
            tags: ['discussion'],
            metadata: {},
            likes: 20,
            published: true,
            createdAt: DateTime.now(),
          );

          await odm.posts('main_post_1').update(post);

          // Add comment to the post
          final comment = Comment(
            id: 'main_comment_1',
            content: 'Great post!',
            authorId: 'commenter_1',
            authorName: 'Comment Author',
            postId: 'main_post_1',
            likes: 3,
            createdAt: DateTime.now(),
          );

          await odm
              .posts('main_post_1')
              .comments('main_comment_1')
              .update(comment);

          // Retrieve comment
          final retrieved = await odm
              .posts('main_post_1')
              .comments('main_comment_1')
              .get();
          expect(retrieved, isNotNull);
          expect(retrieved!.content, equals('Great post!'));
          expect(retrieved.postId, equals('main_post_1'));
        },
      );

      test('should query comments within a main post', () async {
        final post = Post(
          id: 'main_post_2',
          title: 'Post for Comment Queries',
          content: 'Testing comment queries',
          authorId: 'post_author',
          tags: ['test'],
          metadata: {},
          likes: 5,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.posts('main_post_2').update(post);

        final comments = [
          Comment(
            id: 'query_comment_1',
            content: 'First comment',
            authorId: 'author_1',
            authorName: 'First Author',
            postId: 'main_post_2',
            likes: 1,
            createdAt: DateTime.now(),
          ),
          Comment(
            id: 'query_comment_2',
            content: 'Second comment',
            authorId: 'author_2',
            authorName: 'Second Author',
            postId: 'main_post_2',
            likes: 5,
            createdAt: DateTime.now(),
          ),
        ];

        for (final comment in comments) {
          await odm.posts('main_post_2').comments(comment.id).update(comment);
        }

        // Query comments with likes > 3
        final popularComments = await odm
            .posts('main_post_2')
            .comments
            .where(($) => $.likes(isGreaterThan: 3))
            .get();

        expect(popularComments.length, equals(1));
        expect(popularComments.first.id, equals('query_comment_2'));
      });
    });

    group('👥 Comments on User Posts (Deep Nesting)', () {
      test('should create user, post, and nested comments', () async {
        // Create a user
        final user = User(
          id: 'nested_user',
          name: 'Nested User',
          email: 'nested@example.com',
          age: 30,
          profile: const Profile(
            bio: 'User for nested testing',
            avatar: 'nested.jpg',
            socialLinks: {},
            interests: ['nested_testing'],
            followers: 50,
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users('nested_user').update(user);

        // Create a post in user's subcollection
        final post = Post(
          id: 'nested_post',
          title: 'User Post for Nested Comments',
          content: 'This post is in a user subcollection',
          authorId: 'nested_user',
          tags: ['user_post'],
          metadata: {'type': 'personal'},
          likes: 10,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.users('nested_user').posts('nested_post').update(post);

        // Add comment to the user's post - THIS IS THE CRITICAL TEST
        final comment = Comment(
          id: 'deeply_nested_comment',
          content: 'This is a deeply nested comment!',
          authorId: 'comment_author',
          authorName: 'Deep Commenter',
          postId: 'nested_post',
          likes: 7,
          createdAt: DateTime.now(),
        );

        // This should work: user.posts('id').comments - accessing comments through post document
        await odm
            .users('nested_user')
            .posts('nested_post')
            .comments('deeply_nested_comment')
            .update(comment);

        // Verify the comment was created
        final retrieved = await odm
            .users('nested_user')
            .posts('nested_post')
            .comments('deeply_nested_comment')
            .get();

        expect(retrieved, isNotNull);
        expect(retrieved!.content, equals('This is a deeply nested comment!'));
        expect(retrieved.authorName, equals('Deep Commenter'));
        expect(retrieved.likes, equals(7));
      });

      test('should demonstrate the issue: comments extension location', () {
        // This test demonstrates the architectural issue mentioned in the GitHub issue

        final userDoc = odm.users('test_user');
        final postDoc = userDoc.posts('test_post');

        // Comments should be accessible through the post document
        // This is the CORRECT way according to the issue:
        final commentsViaPost = postDoc.comments;
        expect(
          commentsViaPost.query.path,
          equals('users/test_user/posts/test_post/comments'),
        );

        // The issue is that the generator might create comments extension on User instead of Post
        // If there was a comments extension directly on User document, it would be wrong:
        // userDoc.comments would point to 'users/test_user/comments' which is NOT what we want
        // for the deeply nested collection 'users/*/posts/*/comments'

        // The correct pattern should be: user -> post -> comments
        // NOT: user -> comments (for deeply nested collections)
      });

      test('should query deeply nested comments', () async {
        // Set up user and post
        final user = User(
          id: 'query_user',
          name: 'Query User',
          email: 'query@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Query testing user',
            avatar: 'query.jpg',
            socialLinks: {},
            interests: ['querying'],
            followers: 100,
          ),
          rating: 4.5,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users('query_user').update(user);

        final post = Post(
          id: 'query_post',
          title: 'Post for Query Testing',
          content: 'Testing nested comment queries',
          authorId: 'query_user',
          tags: ['query_test'],
          metadata: {},
          likes: 15,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.users('query_user').posts('query_post').update(post);

        // Create multiple comments
        final comments = [
          Comment(
            id: 'nested_query_1',
            content: 'First nested comment',
            authorId: 'commenter_1',
            authorName: 'Commenter One',
            postId: 'query_post',
            likes: 2,
            createdAt: DateTime.now(),
          ),
          Comment(
            id: 'nested_query_2',
            content: 'Second nested comment',
            authorId: 'commenter_2',
            authorName: 'Commenter Two',
            postId: 'query_post',
            likes: 8,
            createdAt: DateTime.now(),
          ),
          Comment(
            id: 'nested_query_3',
            content: 'Third nested comment',
            authorId: 'commenter_3',
            authorName: 'Commenter Three',
            postId: 'query_post',
            likes: 12,
            createdAt: DateTime.now(),
          ),
        ];

        for (final comment in comments) {
          await odm
              .users('query_user')
              .posts('query_post')
              .comments(comment.id)
              .update(comment);
        }

        // Query comments with various filters
        final allComments = await odm
            .users('query_user')
            .posts('query_post')
            .comments
            .get();

        final popularComments = await odm
            .users('query_user')
            .posts('query_post')
            .comments
            .where(($) => $.likes(isGreaterThanOrEqualTo: 8))
            .get();

        expect(allComments.length, equals(3));
        expect(popularComments.length, equals(2));
        expect(
          popularComments.map((c) => c.id).toSet(),
          equals({'nested_query_2', 'nested_query_3'}),
        );
      });
    });

    group('🔄 Cross-Level Comment Operations', () {
      test('should handle comments across different nesting levels', () async {
        // Create a comment in main posts collection
        final mainComment = Comment(
          id: 'cross_main',
          content: 'Main collection comment',
          authorId: 'cross_author',
          authorName: 'Cross Author',
          postId: 'cross_post_main',
          likes: 5,
          createdAt: DateTime.now(),
        );

        await odm
            .posts('cross_post_main')
            .comments('cross_main')
            .update(mainComment);

        // Create a comment in user posts subcollection
        final user = User(
          id: 'cross_user',
          name: 'Cross User',
          email: 'cross@example.com',
          age: 35,
          profile: const Profile(
            bio: 'Cross-level testing',
            avatar: 'cross.jpg',
            socialLinks: {},
            interests: ['cross_testing'],
            followers: 200,
          ),
          rating: 4.8,
          isActive: true,
          isPremium: true,
          createdAt: DateTime.now(),
        );

        await odm.users('cross_user').update(user);

        final userPost = Post(
          id: 'cross_post_user',
          title: 'User Post for Cross Testing',
          content: 'Cross-level comment testing',
          authorId: 'cross_user',
          tags: ['cross'],
          metadata: {},
          likes: 8,
          published: true,
          createdAt: DateTime.now(),
        );

        await odm.users('cross_user').posts('cross_post_user').update(userPost);

        final userComment = Comment(
          id: 'cross_user',
          content: 'User subcollection comment',
          authorId: 'cross_author',
          authorName: 'Cross Author',
          postId: 'cross_post_user',
          likes: 3,
          createdAt: DateTime.now(),
        );

        await odm
            .users('cross_user')
            .posts('cross_post_user')
            .comments('cross_user')
            .update(userComment);

        // Verify both comments exist in their respective locations
        final mainRetrieved = await odm
            .posts('cross_post_main')
            .comments('cross_main')
            .get();
        final userRetrieved = await odm
            .users('cross_user')
            .posts('cross_post_user')
            .comments('cross_user')
            .get();

        expect(mainRetrieved, isNotNull);
        expect(userRetrieved, isNotNull);
        expect(mainRetrieved!.content, equals('Main collection comment'));
        expect(userRetrieved!.content, equals('User subcollection comment'));
      });
    });

    group('🧪 Type Safety and Extensions', () {
      test('should maintain proper type safety for nested collections', () {
        // Verify type safety at each level
        expect(
          odm.users,
          isA<
            FirestoreCollection<
              TestSchema,
              User,
              dynamic,
              UserPatchBuilder<User>,
              UserFilterBuilderRoot,
              UserOrderByBuilder,
              UserAggregateBuilderRoot
            >
          >(),
        );
        expect(
          odm.posts,
          isA<
            FirestoreCollection<
              TestSchema,
              Post,
              dynamic,
              PostPatchBuilder<Post>,
              PostFilterBuilderRoot,
              PostOrderByBuilder,
              PostAggregateBuilderRoot
            >
          >(),
        );
        expect(
          odm.comments,
          isA<
            FirestoreCollection<
              TestSchema,
              Comment,
              dynamic,
              CommentPatchBuilder<Comment>,
              CommentFilterBuilderRoot,
              CommentOrderByBuilder,
              CommentAggregateBuilderRoot
            >
          >(),
        );

        // Verify subcollection types
        expect(
          odm.users('test').posts,
          isA<
            FirestoreCollection<
              TestSchema,
              Post,
              dynamic,
              PostPatchBuilder<Post>,
              PostFilterBuilderRoot,
              PostOrderByBuilder,
              PostAggregateBuilderRoot
            >
          >(),
        );
        expect(
          odm.posts('test').comments,
          isA<
            FirestoreCollection<
              TestSchema,
              Comment,
              dynamic,
              CommentPatchBuilder<Comment>,
              CommentFilterBuilderRoot,
              CommentOrderByBuilder,
              CommentAggregateBuilderRoot
            >
          >(),
        );
        expect(
          odm.users('test').posts('test').comments,
          isA<
            FirestoreCollection<
              TestSchema,
              Comment,
              dynamic,
              CommentPatchBuilder<Comment>,
              CommentFilterBuilderRoot,
              CommentOrderByBuilder,
              CommentAggregateBuilderRoot
            >
          >(),
        );

        // Verify document types
        expect(
          odm.users('test'),
          isA<
            FirestoreDocument<TestSchema, User, dynamic, UserPatchBuilder<User>>
          >(),
        );
        expect(
          odm.posts('test'),
          isA<
            FirestoreDocument<TestSchema, Post, dynamic, PostPatchBuilder<Post>>
          >(),
        );
        expect(
          odm.users('test').posts('test'),
          isA<
            FirestoreDocument<TestSchema, Post, dynamic, PostPatchBuilder<Post>>
          >(),
        );
      });

      test(
        'should demonstrate correct extension placement for nested collections',
        () {
          // This test verifies that the code generator places extensions correctly

          // For collection "users/*/posts/*/comments":
          // - Comments extension should be on FirestoreDocument<TestSchema, Post>
          // - NOT on FirestoreDocument<TestSchema, User>

          final userDoc = odm.users('extension_user');
          final postDoc = userDoc.posts('extension_post');

          // Comments should be accessible through post document
          final commentsCollection = postDoc.comments;
          expect(
            commentsCollection,
            isA<
              FirestoreCollection<
                TestSchema,
                Comment,
                dynamic,
                CommentPatchBuilder<Comment>,
                CommentFilterBuilderRoot,
                CommentOrderByBuilder,
                CommentAggregateBuilderRoot
              >
            >(),
          );
          expect(
            commentsCollection.query.path,
            equals('users/extension_user/posts/extension_post/comments'),
          );

          // This is the architectural pattern that should work:
          // users('id') -> posts('id') -> comments
          // Each step in the chain should provide access to the next level
        },
      );
    });

    group('🎯 Batch Operations with Nested Collections', () {
      test(
        'should support batch operations across nested comment collections',
        () async {
          // Set up user and post
          final user = User(
            id: 'batch_user',
            name: 'Batch User',
            email: 'batch@example.com',
            age: 40,
            profile: const Profile(
              bio: 'Batch testing user',
              avatar: 'batch.jpg',
              socialLinks: {},
              interests: ['batch_testing'],
              followers: 300,
            ),
            rating: 4.9,
            isActive: true,
            isPremium: true,
            createdAt: DateTime.now(),
          );

          await odm.users('batch_user').update(user);

          final post = Post(
            id: 'batch_post',
            title: 'Batch Operations Post',
            content: 'Testing batch operations with nested comments',
            authorId: 'batch_user',
            tags: ['batch'],
            metadata: {},
            likes: 25,
            published: true,
            createdAt: DateTime.now(),
          );

          await odm.users('batch_user').posts('batch_post').update(post);

          // Perform batch operations with nested comments
          await odm.runBatch((batch) {
            // Add multiple comments in a batch
            batch
                .users('batch_user')
                .posts('batch_post')
                .comments
                .insert(
                  Comment(
                    id: 'batch_comment_1',
                    content: 'First batch comment',
                    authorId: 'batch_commenter_1',
                    authorName: 'Batch Commenter 1',
                    postId: 'batch_post',
                    createdAt: DateTime.now(),
                  ),
                );

            batch
                .users('batch_user')
                .posts('batch_post')
                .comments
                .insert(
                  Comment(
                    id: 'batch_comment_2',
                    content: 'Second batch comment',
                    authorId: 'batch_commenter_2',
                    authorName: 'Batch Commenter 2',
                    postId: 'batch_post',
                    createdAt: DateTime.now(),
                  ),
                );

            // Update a comment's likes using collection update
            batch
                .users('batch_user')
                .posts('batch_post')
                .comments
                .update(
                  Comment(
                    id: 'batch_comment_1',
                    content: 'First batch comment',
                    authorId: 'batch_commenter_1',
                    authorName: 'Batch Commenter 1',
                    postId: 'batch_post',
                    likes: 5, // Updated likes
                    createdAt: DateTime.now(),
                  ),
                );
          });

          // Verify batch operations
          final comments = await odm
              .users('batch_user')
              .posts('batch_post')
              .comments
              .get();

          expect(comments.length, equals(2));

          final firstComment = comments.firstWhere(
            (c) => c.id == 'batch_comment_1',
          );
          expect(firstComment.likes, equals(5)); // Should be updated by patch
        },
      );
    });
  });
}
