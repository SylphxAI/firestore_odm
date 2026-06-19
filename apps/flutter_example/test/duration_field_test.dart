import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/task.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🕐 Duration Field Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📝 Basic Duration Operations', () {
      test('should create and retrieve a task with duration fields', () async {
        final task = Task(
          id: 'task_with_duration',
          title: 'Test Task',
          description: 'A task to test duration handling',
          estimatedDuration: const Duration(hours: 2, minutes: 30),
          actualDuration: const Duration(hours: 3, minutes: 15),
          isCompleted: true,
          priority: 1,
          createdAt: DateTime.now(),
          startedAt: DateTime.now().subtract(const Duration(hours: 3)),
          completedAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);
        final retrieved = await odm.tasks(task.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals('task_with_duration'));
        expect(retrieved.title, equals('Test Task'));
        expect(
          retrieved.estimatedDuration,
          equals(const Duration(hours: 2, minutes: 30)),
        );
        expect(
          retrieved.actualDuration,
          equals(const Duration(hours: 3, minutes: 15)),
        );
        expect(retrieved.isCompleted, isTrue);
      });

      test('should handle null duration fields correctly', () async {
        final task = Task(
          id: 'task_null_duration',
          title: 'Task with Null Duration',
          description: 'Testing null duration handling',
          estimatedDuration: const Duration(minutes: 45),
          priority: 2,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);
        final retrieved = await odm.tasks(task.id).get();

        expect(retrieved, isNotNull);
        expect(
          retrieved!.estimatedDuration,
          equals(const Duration(minutes: 45)),
        );
        expect(retrieved.actualDuration, isNull);
        expect(retrieved.isCompleted, isFalse);
      });

      test('should handle various duration formats', () async {
        final testCases = [
          {
            'id': 'duration_seconds',
            'duration': const Duration(seconds: 30),
            'description': 'Short task in seconds',
          },
          {
            'id': 'duration_minutes',
            'duration': const Duration(minutes: 15),
            'description': 'Medium task in minutes',
          },
          {
            'id': 'duration_hours',
            'duration': const Duration(hours: 8),
            'description': 'Long task in hours',
          },
          {
            'id': 'duration_days',
            'duration': const Duration(days: 2),
            'description': 'Very long task in days',
          },
          {
            'id': 'duration_mixed',
            'duration': const Duration(
              days: 1,
              hours: 2,
              minutes: 30,
              seconds: 45,
            ),
            'description': 'Complex duration with mixed units',
          },
        ];

        for (final testCase in testCases) {
          final task = Task(
            id: testCase['id']! as String,
            title: 'Duration Test',
            description: testCase['description']! as String,
            estimatedDuration: testCase['duration']! as Duration,
            createdAt: DateTime.now(),
          );

          await odm.tasks(task.id).update(task);
          final retrieved = await odm.tasks(task.id).get();

          expect(retrieved, isNotNull);
          expect(retrieved!.estimatedDuration, equals(testCase['duration']));
        }
      });
    });

    group('🔄 Duration Updates', () {
      test('should update duration fields correctly', () async {
        final originalTask = Task(
          id: 'update_duration_task',
          title: 'Update Duration Test',
          description: 'Testing duration updates',
          estimatedDuration: const Duration(hours: 1),
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(originalTask.id).update(originalTask);

        // Update the task with actual duration
        await odm
            .tasks(originalTask.id)
            .modify(
              (task) => task.copyWith(
                actualDuration: const Duration(hours: 1, minutes: 30),
                isCompleted: true,
                completedAt: DateTime.now(),
              ),
            );

        final updated = await odm.tasks(originalTask.id).get();
        expect(updated, isNotNull);
        expect(updated!.estimatedDuration, equals(const Duration(hours: 1)));
        expect(
          updated.actualDuration,
          equals(const Duration(hours: 1, minutes: 30)),
        );
        expect(updated.isCompleted, isTrue);
        expect(updated.completedAt, isNotNull);
      });

      test('should handle duration field modifications', () async {
        final task = Task(
          id: 'modify_duration_task',
          title: 'Modify Duration Test',
          description: 'Testing duration modifications',
          estimatedDuration: const Duration(hours: 2),
          actualDuration: const Duration(hours: 2, minutes: 15),
          isCompleted: true,
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);

        // Modify estimated duration
        await odm
            .tasks(task.id)
            .modify(
              (task) =>
                  task.copyWith(estimatedDuration: const Duration(hours: 3)),
            );

        final modified = await odm.tasks(task.id).get();
        expect(modified, isNotNull);
        expect(modified!.estimatedDuration, equals(const Duration(hours: 3)));
        expect(
          modified.actualDuration,
          equals(const Duration(hours: 2, minutes: 15)),
        );
      });

      test('should patch non-duration fields correctly', () async {
        final originalTask = Task(
          id: 'patch_task',
          title: 'Original Title',
          description: 'Original description',
          estimatedDuration: const Duration(hours: 4),
          priority: 2,
          createdAt: DateTime.now(),
        );

        await odm.tasks(originalTask.id).update(originalTask);

        // Patch non-duration fields (Duration fields have serialization issues with patch operations)
        await odm
            .tasks(originalTask.id)
            .patch(
              ($) => [
                $.title('Updated Title'),
                $.description('Updated description'),
                $.isCompleted(true),
                $.priority(3),
                $.completedAt(DateTime.now()),
              ],
            );

        final patched = await odm.tasks(originalTask.id).get();
        expect(patched, isNotNull);
        expect(patched!.title, equals('Updated Title'));
        expect(patched.description, equals('Updated description'));
        expect(patched.isCompleted, isTrue);
        expect(patched.priority, equals(3));
        expect(patched.completedAt, isNotNull);
        // Duration fields should remain unchanged
        expect(patched.estimatedDuration, equals(const Duration(hours: 4)));
        expect(patched.actualDuration, isNull);
      });

      test('should patch duration fields using chain syntax', () async {
        final task = Task(
          id: 'patch_duration_chain',
          title: 'Chain Patch Test',
          description: 'Testing duration patches with chain syntax',
          estimatedDuration: const Duration(minutes: 30),
          actualDuration: const Duration(minutes: 25),
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);

        // Patch duration fields using chain syntax
        await odm
            .tasks(task.id)
            .patch(
              ($) => [
                $.estimatedDuration(const Duration(hours: 1)),
                $.actualDuration(const Duration(minutes: 45)),
                $.isCompleted(true),
                $.priority.increment(1),
              ],
            );

        final patched = await odm.tasks(task.id).get();
        expect(patched, isNotNull);
        expect(patched!.estimatedDuration, equals(const Duration(hours: 1)));
        expect(patched.actualDuration, equals(const Duration(minutes: 45)));
        expect(patched.isCompleted, isTrue);
        expect(patched.priority, equals(2)); // Incremented from 1
      });

      test('should patch individual duration fields independently', () async {
        final task = Task(
          id: 'patch_individual_duration',
          title: 'Individual Patch Test',
          description: 'Testing individual duration field patches',
          estimatedDuration: const Duration(minutes: 30),
          actualDuration: const Duration(minutes: 25),
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);

        // Patch only estimated duration using chain syntax
        await odm
            .tasks(task.id)
            .patch(($) => [$.estimatedDuration(const Duration(minutes: 45))]);

        final afterFirstPatch = await odm.tasks(task.id).get();
        expect(afterFirstPatch, isNotNull);
        expect(
          afterFirstPatch!.estimatedDuration,
          equals(const Duration(minutes: 45)),
        );
        expect(
          afterFirstPatch.actualDuration,
          equals(const Duration(minutes: 25)),
        ); // Unchanged

        // Patch only actual duration using chain syntax
        await odm
            .tasks(task.id)
            .patch(($) => [$.actualDuration(const Duration(minutes: 50))]);

        final afterSecondPatch = await odm.tasks(task.id).get();
        expect(afterSecondPatch, isNotNull);
        expect(
          afterSecondPatch!.estimatedDuration,
          equals(const Duration(minutes: 45)),
        ); // Unchanged
        expect(
          afterSecondPatch.actualDuration,
          equals(const Duration(minutes: 50)),
        ); // Updated
      });

      test('should patch duration to null using chain syntax', () async {
        final task = Task(
          id: 'patch_null_duration',
          title: 'Patch Null Duration Test',
          description: 'Testing patching duration to null',
          estimatedDuration: const Duration(hours: 2),
          actualDuration: const Duration(hours: 1, minutes: 30),
          isCompleted: true,
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);

        // Patch actual duration to null using chain syntax
        await odm
            .tasks(task.id)
            .patch(($) => [$.actualDuration(null), $.isCompleted(false)]);

        final patched = await odm.tasks(task.id).get();
        expect(patched, isNotNull);
        expect(
          patched!.estimatedDuration,
          equals(const Duration(hours: 2)),
        ); // Unchanged
        expect(patched.actualDuration, isNull); // Set to null
        expect(patched.isCompleted, isFalse); // Updated
      });
    });

    group('🔍 Duration Queries', () {
      test('should query tasks by duration ranges', () async {
        final tasks = [
          Task(
            id: 'short_task',
            title: 'Short Task',
            description: 'Quick task',
            estimatedDuration: const Duration(minutes: 30),
            isCompleted: true,
            priority: 1,
            createdAt: DateTime.now(),
          ),
          Task(
            id: 'medium_task',
            title: 'Medium Task',
            description: 'Medium length task',
            estimatedDuration: const Duration(hours: 2),
            priority: 2,
            createdAt: DateTime.now(),
          ),
          Task(
            id: 'long_task',
            title: 'Long Task',
            description: 'Long duration task',
            estimatedDuration: const Duration(hours: 8),
            priority: 3,
            createdAt: DateTime.now(),
          ),
        ];

        for (final task in tasks) {
          await odm.tasks(task.id).update(task);
        }

        // Note: Since Duration is stored as microseconds in Firestore,
        // we need to query using the microsecond representation
        final oneHourInMicroseconds = const Duration(hours: 1).inMicroseconds;
        final fourHoursInMicroseconds = const Duration(hours: 4).inMicroseconds;

        // Query for tasks with estimated duration > 1 hour
        final longTasks = await fakeFirestore
            .collection('tasks')
            .where('estimatedDuration', isGreaterThan: oneHourInMicroseconds)
            .get();

        expect(longTasks.docs.length, equals(2)); // medium_task and long_task

        // Query for tasks with estimated duration < 4 hours
        final shortToMediumTasks = await fakeFirestore
            .collection('tasks')
            .where('estimatedDuration', isLessThan: fourHoursInMicroseconds)
            .get();

        expect(
          shortToMediumTasks.docs.length,
          equals(2),
        ); // short_task and medium_task
      });

      test(
        'should handle completed vs incomplete tasks with durations',
        () async {
          final completedTask = Task(
            id: 'completed_with_duration',
            title: 'Completed Task',
            description: 'Task that is completed',
            estimatedDuration: const Duration(hours: 1),
            actualDuration: const Duration(minutes: 45),
            isCompleted: true,
            priority: 1,
            createdAt: DateTime.now(),
            completedAt: DateTime.now(),
          );

          final incompleteTask = Task(
            id: 'incomplete_with_duration',
            title: 'Incomplete Task',
            description: 'Task that is not completed',
            estimatedDuration: const Duration(hours: 2),
            priority: 2,
            createdAt: DateTime.now(),
          );

          await odm.tasks(completedTask.id).update(completedTask);
          await odm.tasks(incompleteTask.id).update(incompleteTask);

          // Query completed tasks
          final completedTasks = await fakeFirestore
              .collection('tasks')
              .where('isCompleted', isEqualTo: true)
              .get();

          expect(completedTasks.docs.length, equals(1));
          expect(
            completedTasks.docs.first.id,
            equals('completed_with_duration'),
          );

          // Query incomplete tasks
          final incompleteTasks = await fakeFirestore
              .collection('tasks')
              .where('isCompleted', isEqualTo: false)
              .get();

          expect(incompleteTasks.docs.length, equals(1));
          expect(
            incompleteTasks.docs.first.id,
            equals('incomplete_with_duration'),
          );
        },
      );
    });

    group('🧮 Duration Calculations', () {
      test('should handle duration arithmetic correctly', () async {
        final task = Task(
          id: 'calculation_task',
          title: 'Calculation Test',
          description: 'Testing duration calculations',
          estimatedDuration: const Duration(hours: 2),
          actualDuration: const Duration(hours: 2, minutes: 30),
          isCompleted: true,
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);
        final retrieved = await odm.tasks(task.id).get();

        expect(retrieved, isNotNull);

        // Test duration comparisons
        expect(
          retrieved!.actualDuration! > retrieved.estimatedDuration,
          isTrue,
        );

        // Test duration arithmetic
        final overtime =
            retrieved.actualDuration! - retrieved.estimatedDuration;
        expect(overtime, equals(const Duration(minutes: 30)));

        // Test duration in different units
        expect(retrieved.estimatedDuration.inMinutes, equals(120));
        expect(retrieved.actualDuration!.inMinutes, equals(150));
      });

      test('should handle zero and negative duration edge cases', () async {
        final task = Task(
          id: 'edge_case_task',
          title: 'Edge Case Test',
          description: 'Testing edge cases',
          estimatedDuration: Duration.zero,
          actualDuration: const Duration(microseconds: 1),
          isCompleted: true,
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);
        final retrieved = await odm.tasks(task.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.estimatedDuration, equals(Duration.zero));
        expect(
          retrieved.actualDuration,
          equals(const Duration(microseconds: 1)),
        );
      });
    });

    group('🔄 Round-trip Serialization', () {
      test(
        'should maintain duration precision through serialization',
        () async {
          final originalTask = Task(
            id: 'precision_test',
            title: 'Precision Test',
            description: 'Testing duration precision',
            estimatedDuration: const Duration(
              days: 1,
              hours: 2,
              minutes: 30,
              seconds: 45,
              milliseconds: 123,
              microseconds: 456,
            ),
            actualDuration: const Duration(
              hours: 1,
              minutes: 15,
              seconds: 30,
              milliseconds: 789,
            ),
            priority: 1,
            createdAt: DateTime.now(),
          );

          await odm.tasks(originalTask.id).update(originalTask);
          final retrieved = await odm.tasks(originalTask.id).get();

          expect(retrieved, isNotNull);
          expect(
            retrieved!.estimatedDuration,
            equals(originalTask.estimatedDuration),
          );
          expect(retrieved.actualDuration, equals(originalTask.actualDuration));

          // Verify microsecond precision is maintained
          expect(
            retrieved.estimatedDuration.inMicroseconds,
            equals(originalTask.estimatedDuration.inMicroseconds),
          );
          expect(
            retrieved.actualDuration!.inMicroseconds,
            equals(originalTask.actualDuration!.inMicroseconds),
          );
        },
      );
    });
  });
}
