import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_example/models/enum_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Advanced Enum Features', () {
    late FakeFirebaseFirestore fake;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fake = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fake);
    });

    group('Numeric @JsonValue Support', () {
      test('should serialize and deserialize numeric enum values', () async {
        final task = EnumTask(
          id: 'numeric_test',
          title: 'Test Numeric Enums',
          priority: Priority.high, // Should serialize to 3
          status: TaskStatus.inProgress, // Should serialize to 'in_progress'
          createdAt: DateTime.now(),
        );

        await odm.enumTasks(task.id).update(task);

        // Check raw storage values
        final doc = await fake.collection('enumTasks').doc(task.id).get();
        final data = doc.data()!;

        expect(data['priority'], 3); // Numeric @JsonValue
        expect(data['status'], 'in_progress'); // String @JsonValue
        expect(data['defaultPriority'], 2); // Default to Priority.medium
        expect(
          data['defaultStatus'],
          'pending',
        ); // Default to TaskStatus.pending

        // Verify deserialization
        final retrieved = await odm.enumTasks(task.id).get();
        expect(retrieved, isNotNull);
        expect(retrieved!.priority, Priority.high);
        expect(retrieved.status, TaskStatus.inProgress);
        expect(retrieved.defaultPriority, Priority.medium);
        expect(retrieved.defaultStatus, TaskStatus.pending);
      });

      test('should handle all priority enum values correctly', () async {
        final tasks = [
          EnumTask(
            id: 'low',
            title: 'Low Priority Task',
            priority: Priority.low, // 1
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'medium',
            title: 'Medium Priority Task',
            priority: Priority.medium, // 2
            status: TaskStatus.inProgress,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'high',
            title: 'High Priority Task',
            priority: Priority.high, // 3
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'critical',
            title: 'Critical Priority Task',
            priority: Priority.critical, // 4
            status: TaskStatus.cancelled,
            createdAt: DateTime.now(),
          ),
        ];

        // Store all tasks
        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // Verify storage values
        final docs = await fake.collection('enumTasks').get();
        final storedData = {for (var doc in docs.docs) doc.id: doc.data()};

        expect(storedData['low']!['priority'], 1);
        expect(storedData['medium']!['priority'], 2);
        expect(storedData['high']!['priority'], 3);
        expect(storedData['critical']!['priority'], 4);

        expect(storedData['low']!['status'], 'pending');
        expect(storedData['medium']!['status'], 'in_progress');
        expect(storedData['high']!['status'], 'completed');
        expect(storedData['critical']!['status'], 'cancelled');
      });
    });

    group('Enum OrderBy Functionality', () {
      test('should order by string enum values (AccountType)', () async {
        final users = [
          EnumUser(
            id: 'user_enterprise',
            name: 'Enterprise User',
            accountType: AccountType.enterprise, // 'enterprise'
          ),
          EnumUser(
            id: 'user_free',
            name: 'Free User',
            accountType: AccountType.free, // 'free'
          ),
          EnumUser(
            id: 'user_pro',
            name: 'Pro User',
            accountType: AccountType.pro, // 'pro'
          ),
        ];

        for (final user in users) {
          await odm.enumUsers(user.id).update(user);
        }

        // Order by accountType ascending (alphabetical: enterprise, free, pro)
        final ascending = await odm.enumUsers
            .orderBy(($) => ($.accountType(),))
            .get();
        expect(ascending.map((u) => u.accountType).toList(), [
          AccountType.enterprise,
          AccountType.free,
          AccountType.pro,
        ]);

        // Order by accountType descending (reverse alphabetical: pro, free, enterprise)
        final descending = await odm.enumUsers
            .orderBy(($) => ($.accountType(descending: true),))
            .get();
        expect(descending.map((u) => u.accountType).toList(), [
          AccountType.pro,
          AccountType.free,
          AccountType.enterprise,
        ]);
      });

      test('should order by numeric enum values (Priority)', () async {
        final tasks = [
          EnumTask(
            id: 'task_critical',
            title: 'Critical Task',
            priority: Priority.critical, // 4
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'task_low',
            title: 'Low Task',
            priority: Priority.low, // 1
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'task_high',
            title: 'High Task',
            priority: Priority.high, // 3
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'task_medium',
            title: 'Medium Task',
            priority: Priority.medium, // 2
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // Order by priority ascending (1, 2, 3, 4)
        final ascending = await odm.enumTasks
            .orderBy(($) => ($.priority(),))
            .get();
        expect(ascending.map((t) => t.priority).toList(), [
          Priority.low, // 1
          Priority.medium, // 2
          Priority.high, // 3
          Priority.critical, // 4
        ]);

        // Order by priority descending (4, 3, 2, 1)
        final descending = await odm.enumTasks
            .orderBy(($) => ($.priority(descending: true),))
            .get();
        expect(descending.map((t) => t.priority).toList(), [
          Priority.critical, // 4
          Priority.high, // 3
          Priority.medium, // 2
          Priority.low, // 1
        ]);
      });

      test('should order by multiple enum fields', () async {
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
            priority: Priority.high,
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'task3',
            title: 'Task 3',
            priority: Priority.low,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'task4',
            title: 'Task 4',
            priority: Priority.low,
            status: TaskStatus.inProgress,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // Order by priority descending, then status ascending
        final results = await odm.enumTasks
            .orderBy(($) => ($.priority(descending: true), $.status()))
            .get();

        // Expected order:
        // 1. high + completed ('completed' < 'pending' alphabetically)
        // 2. high + pending
        // 3. low + in_progress ('in_progress' < 'pending' alphabetically)
        // 4. low + pending
        expect(
          results.map((t) => '${t.priority.name}_${t.status.name}').toList(),
          ['high_completed', 'high_pending', 'low_inProgress', 'low_pending'],
        );
      });
    });

    group('Enum Query Filtering', () {
      test('should filter by enum values', () async {
        final tasks = [
          EnumTask(
            id: 'urgent1',
            title: 'Urgent Task 1',
            priority: Priority.critical,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'urgent2',
            title: 'Urgent Task 2',
            priority: Priority.high,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'normal',
            title: 'Normal Task',
            priority: Priority.medium,
            status: TaskStatus.completed,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // Filter by high priority
        final highPriorityTasks = await odm.enumTasks
            .where(($) => $.priority.isEqualTo(Priority.high))
            .get();
        expect(highPriorityTasks.length, 1);
        expect(highPriorityTasks.first.title, 'Urgent Task 2');

        // Filter by pending status
        final pendingTasks = await odm.enumTasks
            .where(($) => $.status.isEqualTo(TaskStatus.pending))
            .get();
        expect(pendingTasks.length, 2);
        expect(
          pendingTasks.map((t) => t.title).toList(),
          contains('Urgent Task 1'),
        );
        expect(
          pendingTasks.map((t) => t.title).toList(),
          contains('Urgent Task 2'),
        );
      });

      test('should use enum comparison operators', () async {
        final tasks = [
          EnumTask(
            id: 'p1',
            title: 'Priority 1',
            priority: Priority.low,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'p2',
            title: 'Priority 2',
            priority: Priority.medium,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'p3',
            title: 'Priority 3',
            priority: Priority.high,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
          EnumTask(
            id: 'p4',
            title: 'Priority 4',
            priority: Priority.critical,
            status: TaskStatus.pending,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // Priority >= medium (numeric: >= 2)
        final mediumOrHigher = await odm.enumTasks
            .where(($) => $.priority.isGreaterThanOrEqualTo(Priority.medium))
            .orderBy(($) => ($.priority(),))
            .get();
        expect(mediumOrHigher.length, 3);
        expect(mediumOrHigher.map((t) => t.priority).toList(), [
          Priority.medium,
          Priority.high,
          Priority.critical,
        ]);

        // Priority < high (numeric: < 3)
        final belowHigh = await odm.enumTasks
            .where(($) => $.priority.isLessThan(Priority.high))
            .orderBy(($) => ($.priority(),))
            .get();
        expect(belowHigh.length, 2);
        expect(belowHigh.map((t) => t.priority).toList(), [
          Priority.low,
          Priority.medium,
        ]);
      });
    });

    group('Mixed Enum Operations', () {
      test('should handle patch operations with multiple enum types', () async {
        final task = EnumTask(
          id: 'mixed_enum_test',
          title: 'Mixed Enum Test',
          priority: Priority.low,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        await odm.enumTasks(task.id).update(task);

        // Patch with different enum types
        await odm
            .enumTasks(task.id)
            .patch(
              ($) => [
                $.priority(Priority.critical), // Numeric enum: 4
                $.status(TaskStatus.completed), // String enum: 'completed'
                $.title('Updated Mixed Enum Task'),
              ],
            );

        final updated = await odm.enumTasks(task.id).get();
        expect(updated!.priority, Priority.critical);
        expect(updated.status, TaskStatus.completed);
        expect(updated.title, 'Updated Mixed Enum Task');

        // Verify raw storage
        final doc = await fake.collection('enumTasks').doc(task.id).get();
        final data = doc.data()!;
        expect(data['priority'], 4);
        expect(data['status'], 'completed');
      });

      test('should handle complex queries with mixed enum types', () async {
        final tasks = List.generate(
          6,
          (i) => EnumTask(
            id: 'task_$i',
            title: 'Task $i',
            priority: Priority.values[i % Priority.values.length],
            status: TaskStatus.values[i % TaskStatus.values.length],
            createdAt: DateTime.now().add(Duration(hours: i)),
          ),
        );

        for (final task in tasks) {
          await odm.enumTasks(task.id).update(task);
        }

        // Complex query: high priority OR completed status, ordered by creation time
        final results = await odm.enumTasks
            .where(
              ($) => $.priority
                  .isEqualTo(Priority.high)
                  .or($.status.isEqualTo(TaskStatus.completed)),
            )
            .orderBy(($) => ($.createdAt(),))
            .get();

        expect(results.isNotEmpty, true);

        // Verify each result matches criteria
        for (final task in results) {
          expect(
            task.priority == Priority.high ||
                task.status == TaskStatus.completed,
            true,
            reason:
                'Task ${task.id} should have high priority OR completed status',
          );
        }
      });
    });
  });
}
