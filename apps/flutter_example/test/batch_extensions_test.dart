import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:test/test.dart';

void main() {
  group('Batch Extensions Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should generate batch context extensions', () async {
      // Test that batch context has the generated extensions
      await odm.runBatch((batch) {
        // This should compile if the extensions are generated correctly
        final usersCollection = batch.users;
        expect(usersCollection, isNotNull);

        // Test insert operation
        final user = User(
          id: 'test_user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Test bio',
            avatar: 'test.jpg',
            socialLinks: {},
            interests: ['testing'],
          ),
          rating: 4,
          isActive: true,
          createdAt: DateTime.now(),
        );

        batch.users.insert(user);
      });

      // Verify the user was inserted
      final users = await odm.users.get();
      expect(users.length, equals(1));
      expect(users.first.name, equals('Test User'));
    });
  });
}
