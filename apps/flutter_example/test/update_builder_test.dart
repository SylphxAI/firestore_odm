import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/manual_user3.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:test/test.dart';

void main() {
  group('🔧 UpdateBuilder Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test(
      'should use ManualUser3UpdateBuilder for complex generic types',
      () async {
        // Create initial user
        const user = ManualUser3<ManualUser3Profile<Book>>(
          id: 'update_test_001',
          name: 'Original Name',
          customField: ManualUser3Profile<Book>(
            email: 'original@test.com',
            age: 25,
            rating: 3,
            tags: ['original'],
            preferences: {'status': 'active'},
            customList: [
              Book(title: 'Original Book', author: 'Original Author'),
            ],
          ),
        );

        await odm.manualUsers3('update_test_001').update(user);

        // Test UpdateBuilder functionality - this should use ManualUser3UpdateBuilder
        // Try to update using the patch method which uses update builder pattern
        await odm.manualUsers3('update_test_001').patch((updateBuilder) {
          // This should expose the ManualUser3UpdateBuilder methods
          // updateBuilder.name should be DefaultUpdateBuilder<String>
          // updateBuilder.customField should be DefaultUpdateBuilder<T>

          return [
            updateBuilder.name('Updated Name'),
            updateBuilder.customField(
              const ManualUser3Profile<Book>(
                email: 'updated@test.com',
                age: 30,
                isPremium: true,
                rating: 4.5,
                tags: ['updated'],
                preferences: {'status': 'premium'},
                customList: [
                  Book(title: 'Updated Book', author: 'Updated Author'),
                ],
              ),
            ),
          ];
        });

        // Verify the update worked
        final updated = await odm.manualUsers3('update_test_001').get();
        expect(updated, isNotNull);
        expect(updated!.name, equals('Updated Name'));
        expect(updated.customField.email, equals('updated@test.com'));
        expect(updated.customField.isPremium, isTrue);
        expect(
          updated.customField.customList.first.title,
          equals('Updated Book'),
        );

        print('✅ UpdateBuilder functionality works correctly');
      },
    );

    test('should properly handle type parameters in UpdateBuilder', () async {
      // Test with String collection
      const stringUser = ManualUser3<ManualUser3Profile<String>>(
        id: 'string_update_001',
        name: 'String User',
        customField: ManualUser3Profile<String>(
          email: 'string@test.com',
          age: 20,
          rating: 2.5,
          tags: ['string'],
          preferences: {'type': 'string'},
          customList: ['item1', 'item2'],
        ),
      );

      await odm.manualUsers3Strings('string_update_001').update(stringUser);

      // Test UpdateBuilder with String generic type
      await odm.manualUsers3Strings('string_update_001').patch((updateBuilder) {
        return [
          updateBuilder.name('Updated String User'),
          updateBuilder.customField(
            const ManualUser3Profile<String>(
              email: 'updated.string@test.com',
              age: 25,
              isPremium: true,
              rating: 4,
              tags: ['string', 'updated'],
              preferences: {'type': 'updated_string'},
              customList: ['updated1', 'updated2', 'updated3'],
            ),
          ),
        ];
      });

      final updated = await odm.manualUsers3Strings('string_update_001').get();
      expect(updated, isNotNull);
      expect(updated!.name, equals('Updated String User'));
      expect(updated.customField.customList.length, equals(3));
      expect(updated.customField.customList, contains('updated3'));

      print('✅ String collection UpdateBuilder works correctly');
    });
  });
}
