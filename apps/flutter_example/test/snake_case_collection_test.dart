import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🐍 Snake case collection name tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('snake_case collection should generate camelCase getter', () {
      // This test verifies that snake_case collection names
      // are properly converted to camelCase property names

      // Verify that the snake_case_users collection path
      // generates a snakeCaseUsers getter (camelCase)
      expect(() => odm.snakeCaseUsers, returnsNormally);

      // Verify other existing collections still work
      expect(() => odm.users, returnsNormally);
      expect(() => odm.simpleStories, returnsNormally);
      expect(() => odm.listLengthModels, returnsNormally);
      expect(() => odm.stringGenerics, returnsNormally);

      // Verify the collection has the correct Firestore path
      expect(odm.snakeCaseUsers.query.path, equals('snake_case_users'));
      expect(odm.simpleStories.query.path, equals('simpleStories'));
    });

    test('all camelCase conversions work correctly', () {
      // Test various naming conventions to ensure proper conversion

      // snake_case -> camelCase
      expect(() => odm.snakeCaseUsers, returnsNormally);

      // camelCase stays camelCase
      expect(() => odm.simpleStories, returnsNormally);

      // compound words with numbers
      expect(() => odm.users2, returnsNormally);

      // mixed case compound words
      expect(() => odm.listLengthModels, returnsNormally);
      expect(() => odm.stringGenerics, returnsNormally);
      expect(() => odm.intGenerics, returnsNormally);
    });

    test('collection paths remain unchanged in Firestore queries', () {
      // Verify that while property names are camelCase,
      // the actual Firestore collection paths are preserved

      expect(odm.snakeCaseUsers.query.path, equals('snake_case_users'));
      expect(odm.simpleStories.query.path, equals('simpleStories'));
      expect(odm.listLengthModels.query.path, equals('listLengthModels'));
      expect(odm.users2.query.path, equals('users2'));
    });

    test('snake_case subcollections work correctly', () async {
      // Test that snake_case subcollection names are also converted to camelCase

      // Get a document reference for testing subcollections
      final userDocRef = odm.snakeCaseUsers('test_user_id');

      // Test nested subcollection access
      expect(() => userDocRef.userPosts, returnsNormally);
      expect(
        () => userDocRef.userPosts('test_post_id').postComments,
        returnsNormally,
      );

      // Verify the subcollection paths are correct
      expect(
        userDocRef.userPosts.query.path,
        equals('snake_case_users/test_user_id/user_posts'),
      );
      expect(
        userDocRef.userPosts('test_post_id').postComments.query.path,
        equals(
          'snake_case_users/test_user_id/user_posts/test_post_id/post_comments',
        ),
      );
    });

    test('snake_case subcollections work in transaction context', () async {
      // Test subcollections in transaction context
      await odm.runTransaction((transaction) async {
        final userDoc = transaction.snakeCaseUsers('test_user_id');

        // Verify subcollection getters work in transaction
        expect(() => userDoc.userPosts, returnsNormally);
        expect(
          () => userDoc.userPosts('test_post_id').postComments,
          returnsNormally,
        );

        return;
      });
    });

    test('snake_case subcollections work in batch context', () {
      // Test subcollections in batch context
      final batch = odm.batch();
      final userDoc = batch.snakeCaseUsers('test_user_id');

      // Verify subcollection getters work in batch
      expect(() => userDoc.userPosts, returnsNormally);
      expect(
        () => userDoc.userPosts('test_post_id').postComments,
        returnsNormally,
      );
    });
  });
}
