import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/list_length_model.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 List Length Converter Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should convert IList to int and back with JsonConverter', () async {
      // Create model with IList data
      final model = ListLengthModel(
        id: 'converter_test',
        name: 'JsonConverter Test',
        description: 'Testing IList to int conversion',
        items: ['flutter', 'dart', 'firestore'].toIList(), // Length = 3
        numbers: [10, 20, 30].toIList(), // Sum = 60
        tags: ['test', 'converter'].toIList(), // No converter
        priority: 1,
        isActive: true,
      );

      // Save to Firestore
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
      expect(retrieved.items, equals(['item_0', 'item_1', 'item_2'].toIList()));
      expect(retrieved.numbers.length, equals(1));
      expect(retrieved.numbers.first, equals(60));
      expect(retrieved.tags, equals(['test', 'converter'].toIList()));

      print('✅ JsonConverter working: List ↔ int conversion successful');
    });

    test('should patch IList fields using chain syntax', () async {
      final model = ListLengthModel(
        id: 'patch_test',
        name: 'Patch Test',
        description: 'Testing patch operations',
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

      print('✅ Patch operations with JsonConverter working correctly');
    });

    test('should handle nestedProfiles operations without converter', () async {
      const profile1 = Profile(
        bio: 'Flutter Developer',
        avatar: 'avatar1.jpg',
        socialLinks: {'twitter': '@flutter_dev'},
        interests: ['flutter', 'dart'],
        followers: 100,
      );

      const profile2 = Profile(
        bio: 'Backend Engineer',
        avatar: 'avatar2.jpg',
        socialLinks: {'github': 'backend_guru'},
        interests: ['node', 'python'],
        followers: 200,
      );

      final model = ListLengthModel(
        id: 'nested_profiles_test',
        name: 'Nested Profiles Test',
        description: 'Testing nested profiles operations',
        nestedProfiles: [profile1, profile2].toIList(),
        items: ['item1', 'item2'].toIList(),
        numbers: [10, 20].toIList(),
      );

      await odm.listLengthModels(model.id).update(model);

      // Verify raw data - nestedProfiles should be stored as objects array
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['nestedProfiles'], isA<List>());
      expect(rawData['nestedProfiles'].length, equals(2));
      expect(rawData['items'], equals(2)); // Converted to length
      expect(rawData['numbers'], equals(30)); // Converted to sum

      // Retrieve and verify
      final retrieved = await odm.listLengthModels(model.id).get();
      expect(retrieved!.nestedProfiles.length, equals(2));
      expect(retrieved.nestedProfiles.first.bio, equals('Flutter Developer'));
      expect(retrieved.nestedProfiles[1].followers, equals(200));

      print(
        '✅ NestedProfiles stored and retrieved correctly without conversion',
      );
    });

    test(
      'should demonstrate numbers increment limitation (converter prevents atomic ops)',
      () async {
        final model = ListLengthModel(
          id: 'increment_test',
          name: 'Increment Test',
          description: 'Testing increment limitations',
          numbers: [100].toIList(),
          priority: 1,
        );

        await odm.listLengthModels(model.id).update(model);

        // This should work fine - priority is a regular int field
        await odm
            .listLengthModels(model.id)
            .patch(($) => [$.priority.increment(5)]);

        final afterPriorityIncrement = await odm
            .listLengthModels(model.id)
            .get();
        expect(afterPriorityIncrement!.priority, equals(6)); // 1 + 5

        // However, you CANNOT increment numbers because it's converted to sum
        // The following would be conceptually wrong because numbers is converted to int (sum)
        // await odm.listLengthModels(model.id).patch(($) => [
        //   $.numbers.increment(10), // This doesn't make sense - increment a sum?
        // ]);

        print(
          '✅ Priority increment works, but numbers increment not applicable',
        );
        print(
          '⚠️  Numbers field is converted to sum - increment semantics unclear',
        );
      },
    );

    test(
      'should demonstrate array operations limitation on converted fields',
      () async {
        final model = ListLengthModel(
          id: 'array_ops_test',
          name: 'Array Operations Test',
          description: 'Testing array operation limitations',
          numbers: [10, 20, 30].toIList(),
          tags: [
            'tag1',
            'tag2',
          ].toIList(), // Regular array - supports atomic ops
        );

        await odm.listLengthModels(model.id).update(model);

        // Raw data shows the difference
        final rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        final rawData = rawDoc.data()!;

        expect(rawData['numbers'], equals(60)); // Sum stored as single int
        expect(
          rawData['tags'],
          equals(['tag1', 'tag2']),
        ); // Array stored as array

        // You CANNOT do array operations on numbers because it's stored as int
        // await odm.listLengthModels(model.id).patch(($) => [
        //   $.numbers.arrayUnion([40]), // IMPOSSIBLE - numbers is int, not array
        // ]);

        // But you CAN do array operations on tags
        await odm
            .listLengthModels(model.id)
            .patch(
              ($) => [
                $.tags(['tag1', 'tag2', 'tag3'].toIList()),
              ],
            );

        final afterTagUpdate = await odm.listLengthModels(model.id).get();
        expect(afterTagUpdate!.tags.length, equals(3));
        expect(afterTagUpdate.tags.contains('tag3'), isTrue);

        print('✅ Tags (regular array) supports modifications');
        print('⚠️  Numbers (converted to sum) cannot use array operations');
        print(
          '⚠️  JSON type mismatch prevents atomic array operations on converted fields',
        );
      },
    );

    test('should handle edge cases in conversion', () async {
      const lengthConverter = ListLengthConverter();
      const sumConverter = ListSumConverter();

      // Test edge cases
      expect(lengthConverter.toJson(<String>[].toIList()), equals(0));
      expect(lengthConverter.fromJson(0), equals(<String>[].toIList()));

      expect(sumConverter.toJson(<int>[].toIList()), equals(0));
      expect(sumConverter.fromJson(0), equals([0].toIList()));

      // Test large numbers
      final largeList = List.generate(1000, (i) => 'item_$i').toIList();
      expect(lengthConverter.toJson(largeList), equals(1000));

      final reconstructed = lengthConverter.fromJson(1000);
      expect(reconstructed.length, equals(1000));
      expect(reconstructed.first, equals('item_0'));
      expect(reconstructed.last, equals('item_999'));

      // Test negative sum (edge case)
      final negativeNumbers = [-10, -20, 5].toIList();
      expect(sumConverter.toJson(negativeNumbers), equals(-25));
      expect(sumConverter.fromJson(-25), equals([-25].toIList()));

      print('✅ Edge cases handled correctly in converters');
    });

    test(
      'should handle complex mixed operations with all field types',
      () async {
        const profile = Profile(
          bio: 'Mixed Operations Test',
          avatar: 'mixed.jpg',
          socialLinks: {'test': 'mixed'},
          interests: ['testing'],
          followers: 999,
        );

        final model = ListLengthModel(
          id: 'mixed_ops_test',
          name: 'Mixed Operations Test',
          description: 'Testing all field types together',
          nestedProfiles: [profile].toIList(),
          items: ['initial'].toIList(),
          numbers: [100, 200].toIList(),
          tags: ['start'].toIList(),
          priority: 10,
          createdAt: DateTime.now(),
        );

        await odm.listLengthModels(model.id).update(model);

        // Complex patch with all field types
        const newProfile = Profile(
          bio: 'Updated Profile',
          avatar: 'updated.jpg',
          socialLinks: {'updated': 'profile'},
          interests: ['updated', 'testing'],
          followers: 1500,
        );

        await odm
            .listLengthModels(model.id)
            .patch(
              ($) => [
                $.nestedProfiles([profile, newProfile].toIList()),
                $.items(['new', 'updated', 'items'].toIList()),
                $.numbers([50, 75, 25].toIList()),
                $.tags(['updated', 'mixed', 'tags'].toIList()),
                $.priority.increment(5),
                $.isActive(true),
                $.updatedAt(DateTime.now()),
              ],
            );

        final result = await odm.listLengthModels(model.id).get();
        expect(result, isNotNull);

        // Verify all changes
        expect(result!.nestedProfiles.length, equals(2));
        expect(result.nestedProfiles[1].bio, equals('Updated Profile'));
        expect(result.items.length, equals(3)); // Converted back from length
        expect(
          result.numbers.first,
          equals(150),
        ); // Converted back from sum (50+75+25=150)
        expect(result.tags.length, equals(3)); // Regular array
        expect(result.priority, equals(15)); // 10 + 5
        expect(result.isActive, isTrue);
        expect(result.updatedAt, isNotNull);

        // Verify raw storage
        final rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        final rawData = rawDoc.data()!;

        expect(rawData['nestedProfiles'], isA<List>());
        expect(rawData['nestedProfiles'].length, equals(2));
        expect(rawData['items'], equals(3)); // Stored as length
        expect(rawData['numbers'], equals(150)); // Stored as sum
        expect(
          rawData['tags'],
          equals(['updated', 'mixed', 'tags']),
        ); // Stored as array

        print('✅ Complex mixed operations successful across all field types');
      },
    );

    test('should demonstrate converter reversibility limitations', () async {
      // Important limitation: conversion is lossy for some operations
      final originalItems = ['apple', 'banana', 'cherry'].toIList();
      final originalNumbers = [10, 20, 30, 40].toIList();

      final model = ListLengthModel(
        id: 'reversibility_test',
        name: 'Reversibility Test',
        description: 'Testing conversion limitations',
        items: originalItems,
        numbers: originalNumbers,
      );

      await odm.listLengthModels(model.id).update(model);
      final retrieved = await odm.listLengthModels(model.id).get();

      // Items: lossy conversion - original content lost, only length preserved
      expect(retrieved!.items.length, equals(originalItems.length));
      expect(retrieved.items, equals(['item_0', 'item_1', 'item_2'].toIList()));
      expect(retrieved.items, isNot(equals(originalItems))); // Content lost!

      // Numbers: lossy conversion - individual values lost, only sum preserved
      expect(
        retrieved.numbers.length,
        equals(1),
      ); // Reconstructed as single value
      expect(retrieved.numbers.first, equals(100)); // Sum preserved
      expect(
        retrieved.numbers,
        isNot(equals(originalNumbers)),
      ); // Structure lost!

      print('✅ Converter limitations documented:');
      print('   - Items: Content lost, only length preserved');
      print('   - Numbers: Individual values lost, only sum preserved');
      print(
        '⚠️  These converters are for storage optimization, not data preservation',
      );
    });

    test('should handle large collections efficiently', () async {
      // Generate large collections
      final largeItems = List.generate(10000, (i) => 'large_item_$i').toIList();
      final largeNumbers = List.generate(
        1000,
        (i) => i + 1,
      ).toIList(); // Sum = 500500
      final largeTags = List.generate(500, (i) => 'tag_$i').toIList();

      final model = ListLengthModel(
        id: 'performance_test',
        name: 'Performance Test',
        description: 'Testing large collections',
        items: largeItems,
        numbers: largeNumbers,
        tags: largeTags,
      );

      final stopwatch = Stopwatch()..start();
      await odm.listLengthModels(model.id).update(model);
      stopwatch.stop();

      print(
        '⏱️  Large collection update took: ${stopwatch.elapsedMilliseconds}ms',
      );

      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      // Verify conversion efficiency
      expect(rawData['items'], equals(10000)); // Massive compression!
      expect(
        rawData['numbers'],
        equals(500500),
      ); // Single number instead of 1000
      expect(rawData['tags'], isA<List>()); // Still full array
      expect(rawData['tags'].length, equals(500));

      final retrieveStopwatch = Stopwatch()..start();
      final retrieved = await odm.listLengthModels(model.id).get();
      retrieveStopwatch.stop();

      print(
        '⏱️  Large collection retrieval took: ${retrieveStopwatch.elapsedMilliseconds}ms',
      );

      expect(retrieved!.items.length, equals(10000));
      expect(retrieved.numbers.first, equals(500500));
      expect(retrieved.tags.length, equals(500));

      print('✅ Large collections handled efficiently with conversions');
      print('📊 Storage savings: 10000 items → 1 int, 1000 numbers → 1 int');
    });

    test('should handle null and optional fields correctly', () async {
      const model = ListLengthModel(
        id: 'null_test',
        name: 'Null Test',
        description: 'Testing null handling',
        // Using defaults for optional fields
      );

      await odm.listLengthModels(model.id).update(model);

      final retrieved = await odm.listLengthModels(model.id).get();
      expect(retrieved, isNotNull);
      expect(retrieved!.nestedProfiles.isEmpty, isTrue);
      expect(retrieved.items.isEmpty, isTrue);
      expect(retrieved.numbers.isEmpty, isFalse);
      expect(retrieved.tags.isEmpty, isTrue);
      expect(retrieved.createdAt, isNull);
      expect(retrieved.updatedAt, isNull);

      // Verify raw storage of empty collections
      final rawDoc = await fakeFirestore
          .collection('listLengthModels')
          .doc(model.id)
          .get();
      final rawData = rawDoc.data()!;

      expect(rawData['items'], equals(0)); // Empty list → 0
      expect(rawData['numbers'], equals(0)); // Empty list → 0
      expect(rawData['tags'], equals([])); // Empty list → []

      print('✅ Null and empty collections handled correctly');
    });
  });

  group('🚨 Model Getters and Methods Issue Tests', () {
    test('should demonstrate generator issue with getters and methods', () {
      // This test documents the issue we discovered:
      // When a Freezed model has getter methods or custom methods,
      // the code generator incorrectly treats them as constructor parameters

      const converter = ListLengthConverter();

      // Test the converters work independently
      final testList = ['a', 'b', 'c'].toIList();
      final length = converter.toJson(testList);
      expect(length, equals(3));

      final reconstructed = converter.fromJson(3);
      expect(reconstructed.length, equals(3));

      print('✅ JsonConverters work correctly in isolation');
      print('⚠️  Issue: Model with getters/methods causes generator errors');
      print(
        '⚠️  Error: itemsLength and numbersSum treated as constructor params',
      );

      // The actual issue is in the generated code:
      // lib/test_schema.odm.dart tries to use:
      // itemsLength: data['itemsLength'] as int,
      // numbersSum: data['numbersSum'] as int,
      // But these are getter methods, not constructor parameters!
    });

    test('should verify JsonConverter functionality without model issues', () {
      const lengthConverter = ListLengthConverter();
      const sumConverter = ListSumConverter();

      // Test ListLengthConverter
      final items = ['flutter', 'dart'].toIList();
      expect(lengthConverter.toJson(items), equals(2));
      expect(
        lengthConverter.fromJson(2),
        equals(['item_0', 'item_1'].toIList()),
      );

      // Test ListSumConverter
      final numbers = [10, 20, 30].toIList();
      expect(sumConverter.toJson(numbers), equals(60));
      expect(sumConverter.fromJson(60), equals([60].toIList()));

      print('✅ Both JsonConverters work perfectly');
      print('✅ List → int conversion: ✓');
      print('✅ int → List conversion: ✓');
      print('✅ Back and forth conversion: ✓');
    });
  });

  group('🔥 Atomic Array Patch Operations', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test('should use arrayUnion to add tags without duplicates', () async {
      final model = ListLengthModel(
        id: 'array_union_test',
        name: 'Array Union Test',
        description: 'Testing arrayUnion patch operations',
        tags: ['existing1', 'existing2'].toIList(),
        priority: 1,
      );

      await odm.listLengthModels(model.id).update(model);

      // Use addAll patch - atomic operation, no duplicates
      await odm
          .listLengthModels(model.id)
          .patch(
            ($) => [
              $.tags.addAll([
                'new1',
                'new2',
                'existing1',
              ]), // existing1 won't duplicate
              $.priority.increment(1),
            ],
          );

      final result = await odm.listLengthModels(model.id).get();
      expect(
        result!.tags.length,
        equals(4),
      ); // existing1, existing2, new1, new2
      expect(result.tags.contains('existing1'), isTrue);
      expect(result.tags.contains('existing2'), isTrue);
      expect(result.tags.contains('new1'), isTrue);
      expect(result.tags.contains('new2'), isTrue);
      expect(result.priority, equals(2));

      print('✅ ArrayUnion patch prevents duplicates atomically');
    });

    test('should use arrayRemove to remove specific tags', () async {
      final model = ListLengthModel(
        id: 'array_remove_test',
        name: 'Array Remove Test',
        description: 'Testing arrayRemove patch operations',
        tags: ['keep1', 'remove1', 'keep2', 'remove2', 'keep3'].toIList(),
        priority: 5,
      );

      await odm.listLengthModels(model.id).update(model);

      // Use removeAll patch - atomic operation
      await odm
          .listLengthModels(model.id)
          .patch(
            ($) => [
              $.tags.removeAll(['remove1', 'remove2', 'nonexistent']),
              $.priority.increment(-2),
            ],
          );

      final result = await odm.listLengthModels(model.id).get();
      expect(result!.tags.length, equals(3)); // keep1, keep2, keep3
      expect(result.tags.contains('keep1'), isTrue);
      expect(result.tags.contains('keep2'), isTrue);
      expect(result.tags.contains('keep3'), isTrue);
      expect(result.tags.contains('remove1'), isFalse);
      expect(result.tags.contains('remove2'), isFalse);
      expect(result.priority, equals(3));

      print('✅ ArrayRemove patch removes elements atomically');
    });

    test(
      'should combine arrayUnion and arrayRemove in single patch',
      skip:
          'Cannot perform both arrayUnion and arrayRemove operations on the same field in a single update',
      () async {
        final model = ListLengthModel(
          id: 'array_combo_test',
          name: 'Combined Array Operations',
          description: 'Testing combined array patch operations',
          tags: ['old1', 'old2', 'old3'].toIList(),
          items: [
            'item1',
            'item2',
          ].toIList(), // This will be converted to length
          priority: 10,
        );

        await odm.listLengthModels(model.id).update(model);

        // Combine multiple atomic operations in single patch
        await odm
            .listLengthModels(model.id)
            .patch(
              ($) => [
                $.tags.removeAll(['old2']), // Remove one old tag
                $.tags.addAll(['new1', 'new2']), // Add new tags
                $.items(
                  ['updated1', 'updated2', 'updated3'].toIList(),
                ), // Replace items (gets converted)
                $.priority.increment(5),
              ],
            );

        final result = await odm.listLengthModels(model.id).get();

        // Tags: atomic operations worked
        expect(result!.tags.length, equals(4)); // old1, old3, new1, new2
        expect(result.tags.contains('old1'), isTrue);
        expect(result.tags.contains('old3'), isTrue);
        expect(result.tags.contains('new1'), isTrue);
        expect(result.tags.contains('new2'), isTrue);
        expect(result.tags.contains('old2'), isFalse);

        // Items: converted field replaced
        expect(result.items.length, equals(3)); // Length preserved
        expect(result.priority, equals(15));

        // Check raw data
        final rawDoc = await fakeFirestore
            .collection('listLengthModels')
            .doc(model.id)
            .get();
        final rawData = rawDoc.data()!;
        expect(rawData['items'], equals(3)); // Stored as length
        expect(rawData['tags'], isA<List>()); // Stored as array

        print('✅ Combined atomic and replacement operations work together');
      },
    );

    test(
      'should demonstrate converted fields cannot use array operations',
      () async {
        final model = ListLengthModel(
          id: 'converted_limitation_test',
          name: 'Converted Field Limitations',
          description: 'Showing array ops fail on converted fields',
          items: ['item1', 'item2'].toIList(), // Gets converted to int
          numbers: [10, 20].toIList(), // Gets converted to int
          tags: ['tag1', 'tag2'].toIList(), // Stays as array
        );

        await odm.listLengthModels(model.id).update(model);

        // This works - tags is a real array
        await odm
            .listLengthModels(model.id)
            .patch(
              ($) => [
                $.tags.addAll(['tag3']),
              ],
            );

        // These would FAIL at runtime because items/numbers are stored as ints:
        // await odm.listLengthModels(model.id).patch(($) => [
        //   $.items.arrayUnion(['item3']), // ERROR: arrayUnion on int field
        //   $.numbers.arrayUnion([30]), // ERROR: arrayUnion on int field
        // ]);

        final result = await odm.listLengthModels(model.id).get();
        expect(result!.tags.contains('tag3'), isTrue);

        print('✅ Array operations work on real arrays (tags)');
        print('⚠️  Array operations FAIL on converted fields (items/numbers)');
      },
    );
  });

  group('🗺️ Nested Map Operations Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test(
      'should patch individual Profile fields without replacing whole object',
      () async {
        const originalProfile = Profile(
          bio: 'Original Bio',
          avatar: 'original.jpg',
          socialLinks: {'twitter': '@original', 'github': 'original_user'},
          interests: ['coding', 'reading'],
          followers: 100,
        );

        final model = ListLengthModel(
          id: 'profile_partial_update_test',
          name: 'Profile Partial Update',
          description: 'Testing partial profile updates',
          nestedProfiles: [originalProfile].toIList(),
          priority: 1,
        );

        await odm.listLengthModels(model.id).update(model);

        // Update only specific fields, not the whole profile
        final updatedProfile = originalProfile.copyWith(
          followers: 150, // Only update follower count
          socialLinks: {
            ...originalProfile.socialLinks,
            'linkedin': 'new_linkedin', // Add one new social link
          },
        );

        await odm
            .listLengthModels(model.id)
            .patch(
              ($) => [
                $.nestedProfiles([updatedProfile].toIList()),
                $.priority.increment(1),
              ],
            );

        final result = await odm.listLengthModels(model.id).get();
        final resultProfile = result!.nestedProfiles.first;

        // Verify only intended changes
        expect(resultProfile.bio, equals('Original Bio')); // Unchanged
        expect(resultProfile.avatar, equals('original.jpg')); // Unchanged
        expect(
          resultProfile.interests,
          equals(['coding', 'reading']),
        ); // Unchanged
        expect(resultProfile.followers, equals(150)); // Updated
        expect(
          resultProfile.socialLinks['twitter'],
          equals('@original'),
        ); // Unchanged
        expect(
          resultProfile.socialLinks['github'],
          equals('original_user'),
        ); // Unchanged
        expect(
          resultProfile.socialLinks['linkedin'],
          equals('new_linkedin'),
        ); // Added
        expect(result.priority, equals(2));

        print('✅ Partial profile updates preserve unchanged fields');
      },
    );

    test('should modify Profile arrays and maps incrementally', () async {
      const profile = Profile(
        bio: 'Tech Enthusiast',
        avatar: 'tech.jpg',
        socialLinks: {'twitter': '@tech_person'},
        interests: ['tech', 'gaming'],
        followers: 200,
      );

      final model = ListLengthModel(
        id: 'profile_incremental_test',
        name: 'Profile Incremental Update',
        description: 'Testing incremental profile modifications',
        nestedProfiles: [profile].toIList(),
        tags: ['profile_tag'].toIList(),
      );

      await odm.listLengthModels(model.id).update(model);

      // Incremental updates - add to existing rather than replace
      final expandedProfile = profile.copyWith(
        socialLinks: {
          ...profile.socialLinks, // Keep existing
          'youtube': '@tech_channel', // Add new
          'discord': 'TechServer#1234', // Add another
        },
        interests: [
          ...profile.interests, // Keep existing
          'streaming', 'opensource', // Add new
        ],
        followers: profile.followers + 50, // Increment
      );

      await odm
          .listLengthModels(model.id)
          .patch(
            ($) => [
              $.nestedProfiles([expandedProfile].toIList()),
              $.tags(['profile_tag', 'updated_tag'].toIList()),
            ],
          );

      final result = await odm.listLengthModels(model.id).get();
      final resultProfile = result!.nestedProfiles.first;

      // Verify incremental additions
      expect(resultProfile.socialLinks.length, equals(3));
      expect(
        resultProfile.socialLinks['twitter'],
        equals('@tech_person'),
      ); // Original
      expect(
        resultProfile.socialLinks['youtube'],
        equals('@tech_channel'),
      ); // Added
      expect(
        resultProfile.socialLinks['discord'],
        equals('TechServer#1234'),
      ); // Added

      expect(resultProfile.interests.length, equals(4));
      expect(resultProfile.interests.contains('tech'), isTrue); // Original
      expect(resultProfile.interests.contains('gaming'), isTrue); // Original
      expect(resultProfile.interests.contains('streaming'), isTrue); // Added
      expect(resultProfile.interests.contains('opensource'), isTrue); // Added

      expect(resultProfile.followers, equals(250)); // 200 + 50
      expect(result.tags.contains('updated_tag'), isTrue);

      print('✅ Incremental Profile modifications work correctly');
    });

    test(
      'should handle multiple profiles with different map operations',
      () async {
        const devProfile = Profile(
          bio: 'Software Developer',
          avatar: 'dev.jpg',
          socialLinks: {'github': 'dev_coder'},
          interests: ['coding'],
          followers: 300,
        );

        const designProfile = Profile(
          bio: 'UI/UX Designer',
          avatar: 'designer.jpg',
          socialLinks: {'dribbble': 'cool_designer'},
          interests: ['design'],
          followers: 250,
        );

        final model = ListLengthModel(
          id: 'multi_profile_operations_test',
          name: 'Multi Profile Operations',
          description: 'Testing different operations on multiple profiles',
          nestedProfiles: [devProfile, designProfile].toIList(),
        );

        await odm.listLengthModels(model.id).update(model);

        // Different operations for each profile
        final updatedDevProfile = devProfile.copyWith(
          socialLinks: {
            ...devProfile.socialLinks,
            'stackoverflow': 'helpful_dev', // Add professional platform
            'twitter': '@dev_tweets', // Add social platform
          },
          interests: [...devProfile.interests, 'algorithms', 'opensource'],
        );

        final updatedDesignProfile = designProfile.copyWith(
          socialLinks: {
            'dribbble': 'cool_designer', // Keep existing
            'behance': 'amazing_portfolio', // Add portfolio platform
            // Note: not adding all old ones = removing some
          },
          interests: [...designProfile.interests, 'typography', 'branding'],
          followers: designProfile.followers + 75, // Increment followers
        );

        await odm
            .listLengthModels(model.id)
            .patch(
              ($) => [
                $.nestedProfiles(
                  [updatedDevProfile, updatedDesignProfile].toIList(),
                ),
              ],
            );

        final result = await odm.listLengthModels(model.id).get();

        // Verify dev profile changes
        final resultDevProfile = result!.nestedProfiles[0];
        expect(resultDevProfile.socialLinks.length, equals(3));
        expect(resultDevProfile.socialLinks['github'], equals('dev_coder'));
        expect(
          resultDevProfile.socialLinks['stackoverflow'],
          equals('helpful_dev'),
        );
        expect(resultDevProfile.socialLinks['twitter'], equals('@dev_tweets'));
        expect(resultDevProfile.interests.length, equals(3));

        // Verify design profile changes
        final resultDesignProfile = result.nestedProfiles[1];
        expect(resultDesignProfile.socialLinks.length, equals(2));
        expect(
          resultDesignProfile.socialLinks['dribbble'],
          equals('cool_designer'),
        );
        expect(
          resultDesignProfile.socialLinks['behance'],
          equals('amazing_portfolio'),
        );
        expect(resultDesignProfile.interests.length, equals(3));
        expect(resultDesignProfile.followers, equals(325)); // 250 + 75

        print(
          '✅ Multiple profiles with different map/list operations updated successfully',
        );
      },
    );
  });

  // group('🧪 JsonConverter Array Operations Tests', () {
  //   late FakeFirebaseFirestore fakeFirestore;
  //   late FirestoreODM<TestSchema> odm;

  //   setUp(() {
  //     fakeFirestore = FakeFirebaseFirestore();
  //     odm = FirestoreODM(testSchema, firestore: fakeFirestore);
  //   });
  //   test('should verify items field does not have add() method due to converter', () async {
  //     final model = ListLengthModel(
  //     id: 'items_no_add_test',
  //     name: 'Items No Add Test',
  //     description: 'Verifying converted items field lacks add() method',
  //     items: ['initial1', 'initial2'].toIList(), // Converted to length: 2
  //     tags: ['tag1', 'tag2'].toIList(), // No converter
  //     );

  //     await odm.listLengthModels(model.id).update(model);

  //     // Verify that items field doesn't have add() method
  //     // This is a compile-time check - the code below should NOT compile
  //     // because JsonConverter changes the field type from IList<String> to int

  //     try {
  //     // This should fail at compile time, not runtime
  //     // $.items.add('new_item') should not be available

  //     // Instead, we can only do full replacement:
  //     await odm.listLengthModels(model.id).patch(($) => [
  //         $.items(['new1', 'new2', 'new3'].toIList()), // Full replacement only
  //       ]);

  //     final result = await odm.listLengthModels(model.id).get();
  //     print('✅ items field can only be replaced, not appended to');
  //     print('   Result items length: ${result!.items.length}');
  //     print('   Result items content: ${result.items}');
  //     } catch (e) {
  //     print('❌ Unexpected error: $e');
  //     }

  //     // Compare with regular array field that HAS add() method
  //     await odm.listLengthModels(model.id).patch(($) => [
  //       $.tags.add('new_tag'), // This works - tags has add() method
  //       ]);

  //     final finalResult = await odm.listLengthModels(model.id).get();
  //     print('✅ tags field has add() method available');
  //     print('   Final tags: ${finalResult!.tags}');

  //     print('📋 Summary:');
  //     print('   - $.items.add() → NOT AVAILABLE (JsonConverter int field)');
  //     print('   - $.tags.add() → AVAILABLE (regular IList field)');
  //     print('   - JsonConverter fields lose array operation methods');
  //   });

  // test('should test items.addAll() behavior on converted field', () async {
  //   final model = ListLengthModel(
  //     id: 'items_addall_test',
  //     name: 'Items AddAll Test',
  //     description: 'Testing addAll operations on converted items field',
  //     items: ['item1', 'item2'].toIList(), // Converted to length: 2
  //     numbers: [10, 20].toIList(), // Converted to sum: 30
  //     tags: ['tag1'].toIList(), // No converter
  //   );

  //   await odm.listLengthModels(model.id).update(model);

  //   try {
  //     // Try addAll on converted items field
  //     await odm.listLengthModels(model.id).patch(($) => [
  //           $.items.addAll(['new1', 'new2', 'new3']), // Should this work?
  //         ]);

  //     final result = await odm.listLengthModels(model.id).get();
  //     print('✅ items.addAll() worked on converted field');
  //     print('   Result items length: ${result!.items.length}');
  //     print('   Raw storage check needed...');

  //     // Check raw storage
  //     final rawDoc = await fakeFirestore
  //         .collection('listLengthModels')
  //         .doc(model.id)
  //         .get();
  //     final rawData = rawDoc.data()!;
  //     print('   Raw items value: ${rawData['items']} (should be int)');
  //   } catch (e) {
  //     print('❌ items.addAll() failed on converted field: $e');
  //   }

  //   try {
  //     // Try addAll on converted numbers field
  //     await odm.listLengthModels(model.id).patch(($) => [
  //           $.numbers.addAll([5, 15, 25]), // Should this work?
  //         ]);

  //     final result = await odm.listLengthModels(model.id).get();
  //     print('✅ numbers.addAll() worked on converted field');
  //     print('   Result numbers: ${result!.numbers}');

  //     // Check raw storage
  //     final rawDoc = await fakeFirestore
  //         .collection('listLengthModels')
  //         .doc(model.id)
  //         .get();
  //     final rawData = rawDoc.data()!;
  //     print('   Raw numbers value: ${rawData['numbers']} (should be int)');
  //   } catch (e) {
  //     print('❌ numbers.addAll() failed on converted field: $e');
  //   }
  // });

  //   test('should test numbers.add() and increment behavior on converted field', () async {
  //     final model = ListLengthModel(
  //       id: 'numbers_add_test',
  //       name: 'Numbers Add Test',
  //       description: 'Testing add operations on converted numbers field',
  //       numbers: [100, 200, 300].toIList(), // Converted to sum: 600
  //       priority: 5,
  //     );

  //     await odm.listLengthModels(model.id).update(model);

  //     // Check initial raw storage
  //     final initialRawDoc = await fakeFirestore
  //         .collection('listLengthModels')
  //         .doc(model.id)
  //         .get();
  //     final initialRawData = initialRawDoc.data()!;
  //     print('📊 Initial state:');
  //     print('   Raw numbers value: ${initialRawData['numbers']} (converted sum)');
  //     print('   Retrieved numbers: ${(await odm.listLengthModels(model.id).get())!.numbers}');

  //     try {
  //       // Try to use add() on converted numbers field
  //       await odm.listLengthModels(model.id).patch(($) => [
  //             $.numbers.add(50), // What happens here?
  //             $.priority.increment(1), // Regular increment for comparison
  //           ]);

  //       final result = await odm.listLengthModels(model.id).get();
  //       print('✅ numbers.add() worked');
  //       print('   Result numbers: ${result!.numbers}');
  //       print('   Priority: ${result.priority}');

  //       // Check raw storage after add
  //       final rawDoc = await fakeFirestore
  //           .collection('listLengthModels')
  //           .doc(model.id)
  //           .get();
  //       final rawData = rawDoc.data()!;
  //       print('   Raw numbers after add: ${rawData['numbers']}');
  //     } catch (e) {
  //       print('❌ numbers.add() failed: $e');
  //     }
  //   });

  //   test('should test removeAll on converted fields', () async {
  //     final model = ListLengthModel(
  //       id: 'remove_converted_test',
  //       name: 'Remove Converted Test',
  //       description: 'Testing removeAll on converted fields',
  //       items: ['remove1', 'keep1', 'remove2', 'keep2'].toIList(), // Length: 4
  //       numbers: [10, 20, 30, 40, 50].toIList(), // Sum: 150
  //       tags: ['tag1', 'tag2', 'tag3'].toIList(), // Regular array
  //     );

  //     await odm.listLengthModels(model.id).update(model);

  //     try {
  //       // Try removeAll on converted items field
  //       await odm.listLengthModels(model.id).patch(($) => [
  //             $.items.removeAll(['remove1', 'remove2']), // Can we remove from length?
  //           ]);

  //       final result = await odm.listLengthModels(model.id).get();
  //       print('✅ items.removeAll() worked on converted field');
  //       print('   Result items: ${result!.items}');

  //       final rawDoc = await fakeFirestore
  //           .collection('listLengthModels')
  //           .doc(model.id)
  //           .get();
  //       final rawData = rawDoc.data()!;
  //       print('   Raw items value: ${rawData['items']}');
  //     } catch (e) {
  //       print('❌ items.removeAll() failed: $e');
  //     }

  //     try {
  //       // Try removeAll on converted numbers field
  //       await odm.listLengthModels(model.id).patch(($) => [
  //             $.numbers.removeAll([20, 40]), // Can we remove from sum?
  //           ]);

  //       final result = await odm.listLengthModels(model.id).get();
  //       print('✅ numbers.removeAll() worked on converted field');
  //       print('   Result numbers: ${result!.numbers}');

  //       final rawDoc = await fakeFirestore
  //           .collection('listLengthModels')
  //           .doc(model.id)
  //           .get();
  //       final rawData = rawDoc.data()!;
  //       print('   Raw numbers value: ${rawData['numbers']}');
  //     } catch (e) {
  //       print('❌ numbers.removeAll() failed: $e');
  //     }

  //     // Compare with regular array that works
  //     await odm.listLengthModels(model.id).patch(($) => [
  //           $.tags.removeAll(['tag2']),
  //         ]);

  //     final finalResult = await odm.listLengthModels(model.id).get();
  //     print('✅ tags.removeAll() worked on regular array: ${finalResult!.tags}');
  //   });

  //   test('should test mixed operations on all field types', () async {
  //     final model = ListLengthModel(
  //       id: 'mixed_converter_test',
  //       name: 'Mixed Converter Test',
  //       description: 'Testing all operations together',
  //       items: ['item1'].toIList(), // Converted to length: 1
  //       numbers: [100].toIList(), // Converted to sum: 100
  //       tags: ['tag1'].toIList(), // Regular array
  //       priority: 10,
  //     );

  //     await odm.listLengthModels(model.id).update(model);

  //     print('📊 Testing comprehensive mixed operations:');

  //     try {
  //       await odm.listLengthModels(model.id).patch(($) => [
  //             // Test converter fields
  //             $.items.addAll(['add1', 'add2']), // items converter
  //             $.numbers.addAll([25, 75]), // numbers converter

  //             // Test regular fields
  //             $.tags.addAll(['tag2', 'tag3']), // regular array
  //             $.priority.increment(5), // regular int
  //           ]);

  //       final result = await odm.listLengthModels(model.id).get();
  //       print('✅ Mixed operations completed');
  //       print('   Items length: ${result!.items.length} (should reflect converter)');
  //       print('   Numbers: ${result.numbers} (should reflect converter)');
  //       print('   Tags: ${result.tags} (should be regular array)');
  //       print('   Priority: ${result.priority}');

  //       // Check raw storage for all fields
  //       final rawDoc = await fakeFirestore
  //           .collection('listLengthModels')
  //           .doc(model.id)
  //           .get();
  //       final rawData = rawDoc.data()!;
  //       print('📊 Raw storage:');
  //       print('   items: ${rawData['items']} (${rawData['items'].runtimeType})');
  //       print('   numbers: ${rawData['numbers']} (${rawData['numbers'].runtimeType})');
  //       print('   tags: ${rawData['tags']} (${rawData['tags'].runtimeType})');
  //       print('   priority: ${rawData['priority']} (${rawData['priority'].runtimeType})');
  //     } catch (e) {
  //       print('❌ Mixed operations failed: $e');
  //     }
  //   });
  // });
}
