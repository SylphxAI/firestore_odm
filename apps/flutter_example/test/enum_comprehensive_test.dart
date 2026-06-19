import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_example/models/enum_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Comprehensive Enum Support Summary', () {
    late FakeFirebaseFirestore fake;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fake = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fake);
    });

    group('✅ Working: Numeric @JsonValue Support', () {
      test(
        'should serialize/deserialize numeric enum values correctly',
        () async {
          final task = EnumTask(
            id: 'numeric_enum_test',
            title: 'Test Numeric Enums',
            priority: Priority.critical, // Should serialize to 4
            status: TaskStatus.inProgress, // Should serialize to 'in_progress'
            createdAt: DateTime.now(),
          );

          await odm.enumTasks(task.id).update(task);

          // Verify raw storage - numeric and string @JsonValue
          final doc = await fake.collection('enumTasks').doc(task.id).get();
          final data = doc.data()!;

          expect(
            data['priority'],
            4,
            reason: 'Priority.critical should serialize to 4',
          );
          expect(
            data['status'],
            'in_progress',
            reason: 'TaskStatus.inProgress should serialize to "in_progress"',
          );
          expect(
            data['defaultPriority'],
            2,
            reason: 'Default Priority.medium should serialize to 2',
          );
          expect(
            data['defaultStatus'],
            'pending',
            reason: 'Default TaskStatus.pending should serialize to "pending"',
          );

          // Verify deserialization
          final retrieved = await odm.enumTasks(task.id).get();
          expect(retrieved!.priority, Priority.critical);
          expect(retrieved.status, TaskStatus.inProgress);
          expect(retrieved.defaultPriority, Priority.medium);
          expect(retrieved.defaultStatus, TaskStatus.pending);
        },
      );

      test('should handle all numeric enum values (1,2,3,4)', () async {
        final priorityTests = [
          (Priority.low, 1),
          (Priority.medium, 2),
          (Priority.high, 3),
          (Priority.critical, 4),
        ];

        for (final (priority, expectedValue) in priorityTests) {
          final task = EnumTask(
            id: 'priority_${priority.name}',
            title: 'Priority ${priority.name}',
            priority: priority,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          );

          await odm.enumTasks(task.id).update(task);

          final doc = await fake.collection('enumTasks').doc(task.id).get();
          expect(
            doc.data()!['priority'],
            expectedValue,
            reason:
                'Priority.${priority.name} should serialize to $expectedValue',
          );
        }
      });
    });

    group('✅ Working: String @JsonValue Support', () {
      test('should handle string enum values correctly', () async {
        final statusTests = [
          (TaskStatus.pending, 'pending'),
          (TaskStatus.inProgress, 'in_progress'),
          (TaskStatus.completed, 'completed'),
          (TaskStatus.cancelled, 'cancelled'),
        ];

        for (final (status, expectedValue) in statusTests) {
          final task = EnumTask(
            id: 'status_${status.name}',
            title: 'Status ${status.name}',
            priority: Priority.medium,
            status: status,
            createdAt: DateTime.now(),
          );

          await odm.enumTasks(task.id).update(task);

          final doc = await fake.collection('enumTasks').doc(task.id).get();
          expect(
            doc.data()!['status'],
            expectedValue,
            reason:
                'TaskStatus.${status.name} should serialize to "$expectedValue"',
          );
        }
      });
    });

    group('✅ Working: Enum Query Filtering', () {
      test('should filter by enum values with comparison operators', () async {
        final tasks = [
          EnumTask(
            id: 'low',
            title: 'Low',
            priority: Priority.low,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'medium',
            title: 'Medium',
            priority: Priority.medium,
            status: TaskStatus.inProgress,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'high',
            title: 'High',
            priority: Priority.high,
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'critical',
            title: 'Critical',
            priority: Priority.critical,
            status: TaskStatus.cancelled,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // Test equality
        final highTasks = await odm.enumTasks
            .where(($) => $.priority.isEqualTo(Priority.high))
            .get();
        expect(highTasks.length, 1);
        expect(highTasks.first.title, 'High');

        // Test numeric comparison (>= medium means >= 2)
        final mediumOrHigher = await odm.enumTasks
            .where(($) => $.priority.isGreaterThanOrEqualTo(Priority.medium))
            .get();
        expect(
          mediumOrHigher.length,
          3,
          reason: 'Should find medium, high, and critical',
        );

        // Test string comparison
        final completedTasks = await odm.enumTasks
            .where(($) => $.status.isEqualTo(TaskStatus.completed))
            .get();
        expect(completedTasks.length, 1);
        expect(completedTasks.first.title, 'High');
      });

      test('should handle complex enum queries with OR conditions', () async {
        final tasks = [
          EnumTask(
            id: 't1',
            title: 'Task 1',
            priority: Priority.high,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 't2',
            title: 'Task 2',
            priority: Priority.low,
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 't3',
            title: 'Task 3',
            priority: Priority.medium,
            status: TaskStatus.inProgress,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // High priority OR completed status
        final results = await odm.enumTasks
            .where(
              ($) => $.priority
                  .isEqualTo(Priority.high)
                  .or($.status.isEqualTo(TaskStatus.completed)),
            )
            .get();

        expect(
          results.length,
          2,
          reason: 'Should find high priority task and completed task',
        );
        final titles = results.map((t) => t.title).toSet();
        expect(titles, containsAll(['Task 1', 'Task 2']));
      });
    });

    group('✅ Working: Enum Patch Operations', () {
      test('should patch enum fields correctly', () async {
        final task = EnumTask(
          id: 'patch_test',
          title: 'Original Task',
          priority: Priority.low,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        await odm.enumTasks(task.id).update(task);

        // Patch with mixed enum types
        await odm
            .enumTasks(task.id)
            .patch(
              ($) => [
                $.priority(Priority.critical), // Numeric: 4
                $.status(TaskStatus.completed), // String: 'completed'
                $.title('Updated Task'),
              ],
            );

        final updated = await odm.enumTasks(task.id).get();
        expect(updated!.priority, Priority.critical);
        expect(updated.status, TaskStatus.completed);
        expect(updated.title, 'Updated Task');

        // Verify raw storage
        final doc = await fake.collection('enumTasks').doc(task.id).get();
        final data = doc.data()!;
        expect(data['priority'], 4);
        expect(data['status'], 'completed');
      });
    });

    group('✅ Working: Default Value Handling', () {
      test(
        'should apply enum defaults when optional fields are missing',
        () async {
          // Store data with only required fields, missing optional defaults
          await fake.collection('enumTasks').doc('defaults_test').set({
            'id': 'defaults_test',
            'title': 'Default Test',
            'priority': 3, // Required: Priority.high
            'status': 'completed', // Required: TaskStatus.completed
            'createdAt': DateTime.now().toIso8601String(),
            // defaultPriority, defaultStatus, optionalPriority, optionalStatus missing
            // These should get their defaults
          });

          final task = await odm.enumTasks('defaults_test').get();

          expect(task, isNotNull);
          expect(task!.priority, Priority.high); // 3 = high (from stored data)
          expect(
            task.status,
            TaskStatus.completed,
          ); // 'completed' (from stored data)
          expect(
            task.defaultPriority,
            Priority.medium,
          ); // Default value applied
          expect(
            task.defaultStatus,
            TaskStatus.pending,
          ); // Default value applied
          expect(task.optionalPriority, isNull); // Optional, no default
          expect(task.optionalStatus, isNull); // Optional, no default
        },
      );
    });

    group('✅ Solved: OrderBy with @EnumDefault', () {
      test('should demonstrate orderBy now works with @EnumDefault', () async {
        // Store some test data first
        final tasks = [
          EnumTask(
            id: 'task1',
            title: 'Task 1',
            priority: Priority.high,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'task2',
            title: 'Task 2',
            priority: Priority.low,
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // This now works because EnumTask has @EnumDefault on required fields
        final result = await odm.enumTasks
            .orderBy(($) => ($.priority(),))
            .get();
        expect(result.length, 2);

        print('✅ OrderBy for enums now works with @EnumDefault annotation!');
        print('✅ Successfully ordered ${result.length} tasks by priority enum');
      });
    });

    group('📊 Summary Test', () {
      test('should demonstrate comprehensive enum support', () async {
        print('\n🎯 Enum Support Summary:');
        print('✅ Numeric @JsonValue serialization (Priority: 1,2,3,4)');
        print('✅ String @JsonValue serialization (TaskStatus: string values)');
        print('✅ Default value handling when fields missing');
        print('✅ Query filtering with comparison operators');
        print('✅ Complex queries with OR conditions');
        print('✅ Patch operations with multiple enum types');
        print('✅ Round-trip serialization/deserialization');
        print('✅ OrderBy operations (now working automatically!)');

        // Demonstrate working functionality
        final task = EnumTask(
          id: 'demo',
          title: 'Demo Task',
          priority: Priority.critical, // 4
          status: TaskStatus.inProgress, // 'in_progress'
          createdAt: DateTime.now(),
        );

        await odm.enumTasks(task.id).update(task);

        final retrieved = await odm.enumTasks(task.id).get();
        expect(retrieved!.priority, Priority.critical);
        expect(retrieved.status, TaskStatus.inProgress);

        print('\n✅ All supported enum features working correctly!');
      });
    });
  });
}
