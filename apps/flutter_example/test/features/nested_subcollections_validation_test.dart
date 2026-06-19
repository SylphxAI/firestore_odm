import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/comment.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔧 Nested Subcollections Bug Fix Validation', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test(
      '✅ should correctly generate comments extension on Post document, not User',
      () {
        // Test that the bug fix is working correctly
        // For the collection path "users/*/posts/*/comments"
        // The comments extension should be on Post documents, not User documents

        final userDoc = odm.users('test_user');
        final postDoc = odm.posts('test_post');
        final userPostDoc = userDoc.posts('user_post');

        // Comments should be accessible from Post documents
        expect(
          postDoc.comments,
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
          userPostDoc.comments,
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

        // Verify the correct collection paths
        expect(
          postDoc.comments.query.path,
          equals('posts/test_post/comments'),
          reason: 'Comments on main posts should have correct path',
        );

        expect(
          userPostDoc.comments.query.path,
          equals('users/test_user/posts/user_post/comments'),
          reason: 'Comments on user posts should have correct nested path',
        );
      },
    );

    test(
      '✅ should support the expected API pattern for nested collections',
      () async {
        // This validates that the expected API works as described in the GitHub issue
        const profile = Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {},
          interests: ['coding', 'testing'],
        );

        const user = User(
          id: 'user_123',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: profile,
        );

        final post = Post(
          id: 'post_456',
          title: 'Test Post',
          content: 'This is a test post',
          authorId: 'user_123',
          tags: ['test'],
          metadata: {},
          createdAt: DateTime.now(),
        );

        final comment = Comment(
          id: 'comment_789',
          content: 'Great post!',
          authorId: 'user_123',
          authorName: 'Test User',
          postId: 'post_456',
          createdAt: DateTime.now(),
        );

        // Create the data hierarchy
        await odm.users('user_123').update(user);
        await odm.users('user_123').posts('post_456').update(post);
        await odm
            .users('user_123')
            .posts('post_456')
            .comments('comment_789')
            .update(comment);

        // Verify the expected API works:
        // FirestoreODM(appSchema).users('user_id').posts('post_id').comments
        final retrievedComment = await odm
            .users('user_123')
            .posts('post_456')
            .comments('comment_789')
            .get();

        expect(retrievedComment?.content, equals('Great post!'));
        expect(retrievedComment?.authorId, equals('user_123'));
      },
    );

    test('✅ should maintain type safety for all nesting levels', () {
      // Verify type safety is maintained at all levels
      final userDoc = odm.users('user_id');
      final userPostDoc = userDoc.posts('post_id');
      final userPostCommentDoc = userPostDoc.comments('comment_id');

      // Check types are correct
      expect(
        userDoc,
        isA<
          FirestoreDocument<TestSchema, User, dynamic, UserPatchBuilder<User>>
        >(),
      );
      expect(
        userPostDoc,
        isA<
          FirestoreDocument<TestSchema, Post, dynamic, PostPatchBuilder<Post>>
        >(),
      );
      expect(
        userPostCommentDoc,
        isA<
          FirestoreDocument<
            TestSchema,
            Comment,
            dynamic,
            CommentPatchBuilder<Comment>
          >
        >(),
      );

      // Check collection types are correct
      expect(
        userDoc.posts,
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
        userPostDoc.comments,
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
    });

    test(
      '🏗️ should generate correct extensions for multiple subcollection paths',
      () {
        // Validate that different subcollection patterns work correctly

        // 1. Simple subcollection: "posts/*/comments"
        final mainPostComment = odm.posts('main_post').comments;
        expect(mainPostComment.query.path, equals('posts/main_post/comments'));

        // 2. Nested subcollection: "users/*/posts/*/comments"
        final userPostComment = odm.users('user').posts('post').comments;
        expect(
          userPostComment.query.path,
          equals('users/user/posts/post/comments'),
        );

        // 3. User posts subcollection: "users/*/posts"
        final userPosts = odm.users('user').posts;
        expect(userPosts.query.path, equals('users/user/posts'));

        // 4. User shared posts subcollection: "users/*/sharedPosts"
        final userSharedPosts = odm.users('user').sharedPosts;
        expect(userSharedPosts.query.path, equals('users/user/sharedPosts'));
      },
    );

    test('🎯 should demonstrate the fix for the original GitHub issue', () {
      // This test demonstrates that the original issue is now fixed
      // Original issue: comments extension was incorrectly placed on User document
      // Fixed: comments extension is now correctly placed on Post document

      final userDoc = odm.users('user_id');
      final postDoc = userDoc.posts('post_id');

      // Before fix: This would have been incorrectly available on userDoc
      // After fix: comments is only available on postDoc (correct behavior)

      // This should work (correct nested access)
      expect(
        postDoc.comments.query.path,
        equals('users/user_id/posts/post_id/comments'),
        reason: 'Comments should be accessible from the Post document',
      );

      // Verify the collection structure follows Firestore conventions
      expect(userDoc.ref.path, equals('users/user_id'));
      expect(postDoc.ref.path, equals('users/user_id/posts/post_id'));
    });
  });
}
