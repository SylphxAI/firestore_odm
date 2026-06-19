/// Test for nullable type handling fixes
/// This test verifies the fixes for GitHub Issue #3:
/// https://github.com/SylphxAI/firestore_odm/issues/3
///
/// Issues tested:
/// 1. Nullable Map types in DartMapFieldUpdate
/// 2. Nullable return type in MapFilterField.toJson
/// 3. Type mismatch in fromJson for nested objects
/// 4. Enum lookup returns nullable but field is non-nullable

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/nullable_types_test.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreODM<TestSchema> db;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    db = FirestoreODM(testSchema, firestore: firestore);
  });

  group('Issue #3: Nullable Types Support', () {
    group('Issue 1 & 2: Nullable Map Fields', () {
      test('should handle nullable map field with null value', () async {
        final model = NullableTypesTestModel(
          id: 'test1',
          name: 'Test',
          nullableMap: null,
          nullableStringMap: null,
          status: TestStatus.active,
          priority: Priority.high,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test1').get();

        expect(result, isNotNull);
        expect(result!.nullableMap, isNull);
        expect(result.nullableStringMap, isNull);
      });

      test('should handle nullable map field with non-null value', () async {
        final model = NullableTypesTestModel(
          id: 'test2',
          name: 'Test',
          nullableMap: {'key': 'value', 'count': 42},
          nullableStringMap: {'hello': 'world'},
          status: TestStatus.pending,
          priority: Priority.low,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test2').get();

        expect(result, isNotNull);
        expect(result!.nullableMap, isNotNull);
        expect(result.nullableMap!['key'], equals('value'));
        expect(result.nullableStringMap!['hello'], equals('world'));
      });

      test('should patch nullable map field', () async {
        final model = NullableTypesTestModel(
          id: 'test3',
          name: 'Test',
          nullableMap: {'initial': 'value'},
          status: TestStatus.active,
          priority: Priority.medium,
        );

        await db.nullableTypesTests.insert(model);

        // Patch the nullable map
        await db
            .nullableTypesTests('test3')
            .patch(
              ($) => [
                $.nullableMap({'updated': 'data'}),
              ],
            );

        final result = await db.nullableTypesTests('test3').get();
        expect(result!.nullableMap!['updated'], equals('data'));
      });
    });

    group('Issue 3: Nested Object fromJson Type', () {
      test('should handle nullable nested object with null value', () async {
        final model = NullableTypesTestModel(
          id: 'test4',
          name: 'Test',
          nullableNested: null,
          status: TestStatus.completed,
          priority: Priority.high,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test4').get();

        expect(result, isNotNull);
        expect(result!.nullableNested, isNull);
      });

      test('should handle nullable nested object with value', () async {
        final model = NullableTypesTestModel(
          id: 'test5',
          name: 'Test',
          nullableNested: const NestedData(name: 'nested', value: 100),
          status: TestStatus.active,
          priority: Priority.medium,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test5').get();

        expect(result, isNotNull);
        expect(result!.nullableNested, isNotNull);
        expect(result.nullableNested!.name, equals('nested'));
        expect(result.nullableNested!.value, equals(100));
      });

      test('should handle list of nested objects', () async {
        final model = NullableTypesTestModel(
          id: 'test6',
          name: 'Test',
          nestedList: const [
            NestedData(name: 'first'),
            NestedData(name: 'second', value: 50),
          ],
          status: TestStatus.pending,
          priority: Priority.low,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test6').get();

        expect(result, isNotNull);
        expect(result!.nestedList, hasLength(2));
        expect(result.nestedList[0].name, equals('first'));
        expect(result.nestedList[1].value, equals(50));
      });
    });

    group('Issue 4: Non-nullable Enum Fields', () {
      test('should handle non-nullable enum with string JsonValue', () async {
        final model = NullableTypesTestModel(
          id: 'test7',
          name: 'Test',
          status: TestStatus.active,
          priority: Priority.high,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test7').get();

        expect(result, isNotNull);
        expect(result!.status, equals(TestStatus.active));
      });

      test('should handle non-nullable enum with numeric JsonValue', () async {
        final model = NullableTypesTestModel(
          id: 'test8',
          name: 'Test',
          status: TestStatus.pending,
          priority: Priority.medium,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test8').get();

        expect(result, isNotNull);
        expect(result!.priority, equals(Priority.medium));
      });

      test('should handle nullable enum with null value', () async {
        final model = NullableTypesTestModel(
          id: 'test9',
          name: 'Test',
          status: TestStatus.completed,
          priority: Priority.low,
          nullableStatus: null,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test9').get();

        expect(result, isNotNull);
        expect(result!.nullableStatus, isNull);
      });

      test('should handle nullable enum with non-null value', () async {
        final model = NullableTypesTestModel(
          id: 'test10',
          name: 'Test',
          status: TestStatus.active,
          priority: Priority.high,
          nullableStatus: TestStatus.pending,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('test10').get();

        expect(result, isNotNull);
        expect(result!.nullableStatus, equals(TestStatus.pending));
      });

      test('should filter by non-nullable enum', () async {
        await db.nullableTypesTests.insert(
          NullableTypesTestModel(
            id: 'filter1',
            name: 'Active',
            status: TestStatus.active,
            priority: Priority.high,
          ),
        );
        await db.nullableTypesTests.insert(
          NullableTypesTestModel(
            id: 'filter2',
            name: 'Pending',
            status: TestStatus.pending,
            priority: Priority.low,
          ),
        );

        final activeResults = await db.nullableTypesTests
            .where(($) => $.status(isEqualTo: TestStatus.active))
            .get();

        expect(activeResults, hasLength(1));
        expect(activeResults.first.name, equals('Active'));
      });
    });

    group('Complex Scenarios', () {
      test('should handle model with all nullable fields set', () async {
        final model = NullableTypesTestModel(
          id: 'complex1',
          name: 'Complete',
          nullableMap: {'data': 'value'},
          nullableStringMap: {'key': 'val'},
          requiredMap: {'count': 1},
          nullableNested: const NestedData(name: 'test', value: 42),
          nestedList: const [NestedData(name: 'item')],
          status: TestStatus.completed,
          priority: Priority.high,
          nullableStatus: TestStatus.active,
        );

        await db.nullableTypesTests.insert(model);
        final result = await db.nullableTypesTests('complex1').get();

        expect(result, isNotNull);
        expect(result!.nullableMap, isNotNull);
        expect(result.nullableStringMap, isNotNull);
        expect(result.nullableNested, isNotNull);
        expect(result.nestedList, hasLength(1));
        expect(result.status, equals(TestStatus.completed));
        expect(result.priority, equals(Priority.high));
        expect(result.nullableStatus, equals(TestStatus.active));
      });
    });
  });
}
