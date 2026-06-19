import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/list_length_model.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 ODM JsonConverter Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test(
      'should convert IList to int and back with JsonConverter in ODM',
      () async {
        // Create model with IList data
        final model = ListLengthModel(
          id: 'converter_test',
          name: 'JsonConverter Test',
          description: 'Testing IList to int conversion in ODM',
          items: ['flutter', 'dart', 'firestore'].toIList(), // Length = 3
          numbers: [10, 20, 30].toIList(), // Sum = 60
          tags: ['test', 'converter'].toIList(), // No converter
          priority: 1,
          isActive: true,
        );

        // Save to Firestore using ODM
        await odm.listLengthModels(model.id).update(model);

        // Check raw Firestore data to verify conversion
        final rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        final rawData = rawDoc.data()!;

        // Verify JsonConverter worked: IList -> int
        expect(rawData['items'], equals(3)); // Length stored as int
        expect(rawData['numbers'], equals(60)); // Sum stored as int
        expect(rawData['tags'], equals(['test', 'converter'])); // No conversion

        // Retrieve through ODM to verify back conversion
        final retrieved = await odm.listLengthModels(model.id).get();
        expect(retrieved, isNotNull);

        // Verify JsonConverter worked: int -> IList
        expect(retrieved!.items.length, equals(3));
        expect(
          retrieved.items,
          equals(['item_0', 'item_1', 'item_2'].toIList()),
        );
        expect(retrieved.numbers.length, equals(1));
        expect(retrieved.numbers.first, equals(60));
        expect(retrieved.tags, equals(['test', 'converter'].toIList()));

        print('✅ ODM JsonConverter working: List ↔ int conversion successful');
      },
    );

    test('should patch IList fields using chain syntax in ODM', () async {
      final model = ListLengthModel(
        id: 'patch_test',
        name: 'Patch Test',
        description: 'Testing patch operations in ODM',
        items: ['initial'].toIList(),
        numbers: [50].toIList(),
        tags: ['tag1'].toIList(),
        priority: 1,
      );

      await odm.listLengthModels(model.id).update(model);

      // Patch using chain syntax
      await odm
          .listLengthModels(model.id)
          .patch(
            ($) => [
              $.items(['new', 'items', 'list'].toIList()),
              $.numbers([25, 25, 50].toIList()),
              $.tags(['updated', 'tags'].toIList()),
              $.priority.increment(1),
              $.isActive(true),
            ],
          );

      // Verify patch worked
      final patched = await odm.listLengthModels(model.id).get();
      expect(patched, isNotNull);
      expect(patched!.priority, equals(2)); // Incremented
      expect(patched.isActive, isTrue);

      // Check raw data to verify JsonConverter during patch
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['items'], equals(3)); // New length
      expect(rawData['numbers'], equals(100)); // New sum (25+25+50)
      expect(rawData['tags'], equals(['updated', 'tags'])); // No conversion

      print('✅ ODM Patch operations with JsonConverter working correctly');
    });

    test('should demonstrate back and forth conversion in ODM', () async {
      // Create initial model
      final model = ListLengthModel(
        id: 'back_forth_test',
        name: 'Back and Forth Test',
        description: 'Testing bidirectional conversion in ODM',
        items: ['one', 'two', 'three', 'four'].toIList(),
        numbers: [10, 20, 30].toIList(),
        tags: ['demo'].toIList(),
        priority: 1,
        isActive: true,
      );

      // Save to Firestore (List -> int conversion)
      await odm.listLengthModels(model.id).update(model);

      // Verify raw storage
      var rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      var rawData = rawDoc.data()!;

      expect(rawData['items'], equals(4)); // Length stored
      expect(rawData['numbers'], equals(60)); // Sum stored

      // Retrieve from Firestore (int -> List conversion)
      final retrieved = await odm.listLengthModels(model.id).get();
      expect(retrieved, isNotNull);

      // Verify reconstruction
      expect(retrieved!.items.length, equals(4));
      expect(
        retrieved.items,
        equals(['item_0', 'item_1', 'item_2', 'item_3'].toIList()),
      );
      expect(retrieved.numbers.length, equals(1));
      expect(retrieved.numbers.first, equals(60));

      // Modify and save again (demonstrating round trip)
      final updatedModel = retrieved.copyWith(
        items: retrieved.items.add('fifth'),
        numbers: retrieved.numbers.add(40),
      );

      await odm.listLengthModels(updatedModel.id).update(updatedModel);

      // Verify updated raw storage
      rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      rawData = rawDoc.data()!;

      expect(rawData['items'], equals(5)); // Updated length
      expect(rawData['numbers'], equals(100)); // Updated sum (60 + 40)

      print('✅ ODM Back and forth conversion successful');
      print('✅ Final items length: ${rawData['items']}');
      print('✅ Final numbers sum: ${rawData['numbers']}');
    });

    test('should handle edge cases in ODM operations', () async {
      // Test with empty lists
      final emptyModel = ListLengthModel(
        id: 'empty_test',
        name: 'Empty Test',
        description: 'Testing empty lists in ODM',
        items: <String>[].toIList(),
        numbers: <int>[].toIList(),
        tags: ['empty'].toIList(),
      );

      await odm.listLengthModels(emptyModel.id).update(emptyModel);

      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(emptyModel.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['items'], equals(0)); // Empty length
      expect(rawData['numbers'], equals(0)); // Empty sum

      final retrieved = await odm.listLengthModels(emptyModel.id).get();
      expect(retrieved!.items.isEmpty, isTrue);
      expect(retrieved.numbers.length, equals(1));
      expect(retrieved.numbers.first, equals(0));

      print('✅ ODM handles empty lists correctly');
    });

    test('should handle large numbers in ODM operations', () async {
      final largeModel = ListLengthModel(
        id: 'large_test',
        name: 'Large Numbers Test',
        description: 'Testing large numbers in ODM',
        items: List.generate(100, (i) => 'item_$i').toIList(),
        numbers: [1000000, 2000000, 3000000].toIList(),
        tags: ['large'].toIList(),
        priority: 999,
        isActive: true,
      );

      await odm.listLengthModels(largeModel.id).update(largeModel);

      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(largeModel.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['items'], equals(100)); // Large length
      expect(rawData['numbers'], equals(6000000)); // Large sum

      final retrieved = await odm.listLengthModels(largeModel.id).get();
      expect(retrieved!.items.length, equals(100));
      expect(retrieved.numbers.first, equals(6000000));

      print('✅ ODM handles large numbers correctly');
    });
  });
}
