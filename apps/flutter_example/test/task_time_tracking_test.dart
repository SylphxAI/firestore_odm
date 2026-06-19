import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/task.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('⏱️ Task Time Tracking Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🕐 Duration Calculation from DateTime Fields', () {
      test(
        'should calculate actual duration from start and completion times',
        () async {
          final createdTime = DateTime.now().subtract(const Duration(hours: 2));
          final startTime = DateTime.now().subtract(
            const Duration(hours: 1, minutes: 30),
          );
          final completionTime = DateTime.now().subtract(
            const Duration(minutes: 15),
          );

          final expectedDuration = completionTime.difference(startTime);

          final task = Task(
            id: 'time_calc_task',
            title: 'Time Calculation Task',
            description: 'Testing duration calculation from DateTime fields',
            estimatedDuration: const Duration(hours: 1),
            actualDuration: expectedDuration, // Manually set for comparison
            isCompleted: true,
            priority: 1,
            createdAt: createdTime,
            startedAt: startTime,
            completedAt: completionTime,
            updatedAt: completionTime,
          );

          await odm.tasks(task.id).update(task);
          final retrieved = await odm.tasks(task.id).get();

          expect(retrieved, isNotNull);
          expect(retrieved!.startedAt, equals(startTime));
          expect(retrieved.completedAt, equals(completionTime));
          expect(retrieved.actualDuration, equals(expectedDuration));

          // Verify calculated duration matches stored duration
          final calculatedDuration = retrieved.completedAt!.difference(
            retrieved.startedAt!,
          );
          expect(calculatedDuration, equals(retrieved.actualDuration));
          expect(calculatedDuration.inMinutes, equals(75)); // 1 hour 15 minutes
        },
      );

      test('should handle tasks with multiple duration updates', () async {
        final createdTime = DateTime.now().subtract(const Duration(hours: 3));
        final firstStart = DateTime.now().subtract(
          const Duration(hours: 2, minutes: 30),
        );
        final firstPause = DateTime.now().subtract(const Duration(hours: 2));
        final secondStart = DateTime.now().subtract(
          const Duration(hours: 1, minutes: 30),
        );
        final completion = DateTime.now().subtract(const Duration(minutes: 30));

        // Calculate total working time (excluding pause period)
        final firstWorkPeriod = firstPause.difference(firstStart);
        final secondWorkPeriod = completion.difference(secondStart);
        final totalWorkTime = firstWorkPeriod + secondWorkPeriod;

        final task = Task(
          id: 'multi_duration_task',
          title: 'Multi Duration Task',
          description: 'Task with multiple work periods',
          estimatedDuration: const Duration(hours: 1),
          actualDuration: totalWorkTime,
          isCompleted: true,
          priority: 2,
          createdAt: createdTime,
          startedAt: firstStart, // First start time
          completedAt: completion,
          updatedAt: completion,
        );

        await odm.tasks(task.id).update(task);
        final retrieved = await odm.tasks(task.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.actualDuration, equals(totalWorkTime));
        expect(
          retrieved.actualDuration!.inMinutes,
          equals(90),
        ); // 30 + 60 minutes

        // Verify the actual duration is less than the total elapsed time
        final totalElapsed = retrieved.completedAt!.difference(
          retrieved.startedAt!,
        );
        expect(retrieved.actualDuration, lessThan(totalElapsed));
      });

      test(
        'should calculate work-in-progress duration for ongoing tasks',
        () async {
          final createdTime = DateTime.now().subtract(const Duration(hours: 1));
          final startTime = DateTime.now().subtract(
            const Duration(minutes: 45),
          );
          final currentTime = DateTime.now();

          final task = Task(
            id: 'wip_task',
            title: 'Work in Progress Task',
            description: 'Currently being worked on',
            estimatedDuration: const Duration(hours: 2),
            priority: 1,
            createdAt: createdTime,
            startedAt: startTime,
            updatedAt: currentTime,
          );

          await odm.tasks(task.id).update(task);
          final retrieved = await odm.tasks(task.id).get();

          expect(retrieved, isNotNull);
          expect(retrieved!.isCompleted, isFalse);
          expect(retrieved.actualDuration, isNull);
          expect(retrieved.startedAt, isNotNull);
          expect(retrieved.completedAt, isNull);

          // Calculate elapsed time since start
          final elapsedTime = currentTime.difference(retrieved.startedAt!);
          expect(elapsedTime.inMinutes, greaterThanOrEqualTo(45));
          expect(
            elapsedTime.inMinutes,
            lessThan(50),
          ); // Allow for small test execution time
        },
      );
    });

    group('📊 Duration vs Estimation Analysis', () {
      test('should compare actual vs estimated durations', () async {
        final testCases = [
          {
            'id': 'underestimated_task',
            'title': 'Underestimated Task',
            'estimated': const Duration(hours: 1),
            'actual': const Duration(hours: 2, minutes: 30),
            'description': 'Task that took longer than expected',
          },
          {
            'id': 'overestimated_task',
            'title': 'Overestimated Task',
            'estimated': const Duration(hours: 3),
            'actual': const Duration(hours: 1, minutes: 45),
            'description': 'Task that finished faster than expected',
          },
          {
            'id': 'accurate_task',
            'title': 'Accurately Estimated Task',
            'estimated': const Duration(hours: 2),
            'actual': const Duration(hours: 2, minutes: 5),
            'description': 'Task with accurate estimation',
          },
        ];

        for (final testCase in testCases) {
          final startTime = DateTime.now().subtract(
            testCase['actual']! as Duration,
          );
          final endTime = DateTime.now();

          final task = Task(
            id: testCase['id']! as String,
            title: testCase['title']! as String,
            description: testCase['description']! as String,
            estimatedDuration: testCase['estimated']! as Duration,
            actualDuration: testCase['actual']! as Duration,
            isCompleted: true,
            priority: 1,
            createdAt: startTime.subtract(const Duration(hours: 1)),
            startedAt: startTime,
            completedAt: endTime,
            updatedAt: endTime,
          );

          await odm.tasks(task.id).update(task);
        }

        // Retrieve and analyze all tasks
        final allTasks = await Future.wait([
          odm.tasks('underestimated_task').get(),
          odm.tasks('overestimated_task').get(),
          odm.tasks('accurate_task').get(),
        ]);

        // Underestimated task
        final underTask = allTasks[0]!;
        final underVariance =
            underTask.actualDuration! - underTask.estimatedDuration;
        expect(underVariance.isNegative, isFalse);
        expect(underVariance.inMinutes, equals(90)); // 1.5 hours over

        // Overestimated task
        final overTask = allTasks[1]!;
        final overVariance =
            overTask.actualDuration! - overTask.estimatedDuration;
        expect(overVariance.isNegative, isTrue);
        expect(overVariance.abs().inMinutes, equals(75)); // 1.25 hours under

        // Accurate task
        final accurateTask = allTasks[2]!;
        final accurateVariance =
            accurateTask.actualDuration! - accurateTask.estimatedDuration;
        expect(
          accurateVariance.abs().inMinutes,
          lessThan(10),
        ); // Within 10 minutes
      });

      test('should calculate estimation accuracy metrics', () async {
        const baseDuration = Duration(hours: 2);
        final accuracyTestTasks = [
          {
            'id': 'perfect_estimate',
            'estimated': baseDuration,
            'actual': baseDuration,
          },
          {
            'id': 'close_estimate',
            'estimated': baseDuration,
            'actual': const Duration(hours: 2, minutes: 10),
          },
          {
            'id': 'poor_estimate',
            'estimated': baseDuration,
            'actual': const Duration(hours: 4),
          },
        ];

        for (final taskData in accuracyTestTasks) {
          final task = Task(
            id: taskData['id']! as String,
            title: 'Estimation Test',
            description: 'Testing estimation accuracy',
            estimatedDuration: taskData['estimated']! as Duration,
            actualDuration: taskData['actual']! as Duration,
            isCompleted: true,
            priority: 1,
            createdAt: DateTime.now(),
          );

          await odm.tasks(task.id).update(task);
        }

        // Calculate accuracy percentages
        final retrievedTasks = await Future.wait([
          odm.tasks('perfect_estimate').get(),
          odm.tasks('close_estimate').get(),
          odm.tasks('poor_estimate').get(),
        ]);

        for (final task in retrievedTasks) {
          final estimated = task!.estimatedDuration.inMinutes.toDouble();
          final actual = task.actualDuration!.inMinutes.toDouble();
          final accuracy = (1 - (estimated - actual).abs() / estimated) * 100;

          switch (task.id) {
            case 'perfect_estimate':
              expect(accuracy, equals(100.0));
            case 'close_estimate':
              expect(accuracy, greaterThan(90.0)); // ~91.7%
            case 'poor_estimate':
              expect(accuracy, lessThan(50.0)); // Actually 0% (100% over)
          }
        }
      });
    });

    group('🔄 Task Lifecycle Time Tracking', () {
      test('should track complete task lifecycle with timestamps', () async {
        final createdTime = DateTime.now().subtract(const Duration(days: 2));
        final startTime = DateTime.now().subtract(
          const Duration(days: 1, hours: 8),
        );
        final pauseTime = DateTime.now().subtract(
          const Duration(days: 1, hours: 4),
        );
        final resumeTime = DateTime.now().subtract(const Duration(hours: 6));
        final completeTime = DateTime.now().subtract(const Duration(hours: 2));

        // Initial task creation
        final task = Task(
          id: 'lifecycle_task',
          title: 'Lifecycle Tracking Task',
          description: 'Tracking complete task lifecycle',
          estimatedDuration: const Duration(hours: 8),
          priority: 2,
          createdAt: createdTime,
          updatedAt: createdTime,
        );

        await odm.tasks(task.id).update(task);

        // Start task
        await odm
            .tasks(task.id)
            .modify(
              (task) =>
                  task.copyWith(startedAt: startTime, updatedAt: startTime),
            );

        // Pause task (implicit - just update timestamp)
        await odm
            .tasks(task.id)
            .modify((task) => task.copyWith(updatedAt: pauseTime));

        // Resume task (implicit - update timestamp)
        await odm
            .tasks(task.id)
            .modify((task) => task.copyWith(updatedAt: resumeTime));

        // Complete task
        final workingTime1 = pauseTime.difference(startTime);
        final workingTime2 = completeTime.difference(resumeTime);
        final totalWorkingTime = workingTime1 + workingTime2;

        await odm
            .tasks(task.id)
            .modify(
              (task) => task.copyWith(
                isCompleted: true,
                completedAt: completeTime,
                actualDuration: totalWorkingTime,
                updatedAt: completeTime,
              ),
            );

        final finalTask = await odm.tasks(task.id).get();

        expect(finalTask, isNotNull);
        expect(finalTask!.isCompleted, isTrue);
        expect(finalTask.createdAt, equals(createdTime));
        expect(finalTask.startedAt, equals(startTime));
        expect(finalTask.completedAt, equals(completeTime));
        expect(finalTask.actualDuration, equals(totalWorkingTime));

        // Verify working time calculations
        expect(finalTask.actualDuration!.inHours, equals(8)); // 4 + 4 hours

        // Verify total elapsed time vs working time
        final totalElapsed = finalTask.completedAt!.difference(
          finalTask.startedAt!,
        );
        expect(totalElapsed.inHours, equals(30)); // ~1.25 days
        expect(finalTask.actualDuration, lessThan(totalElapsed));
      });

      test('should handle task reopening and completion cycles', () async {
        final initialTime = DateTime.now().subtract(const Duration(days: 3));

        final task = Task(
          id: 'reopen_task',
          title: 'Reopenable Task',
          description: 'Task that can be reopened',
          estimatedDuration: const Duration(hours: 4),
          priority: 1,
          createdAt: initialTime,
        );

        await odm.tasks(task.id).update(task);

        // First completion cycle
        final firstStart = initialTime.add(const Duration(hours: 2));
        final firstComplete = firstStart.add(const Duration(hours: 3));
        final firstDuration = firstComplete.difference(firstStart);

        await odm
            .tasks(task.id)
            .modify(
              (task) => task.copyWith(
                startedAt: firstStart,
                completedAt: firstComplete,
                actualDuration: firstDuration,
                isCompleted: true,
                updatedAt: firstComplete,
              ),
            );

        var retrieved = await odm.tasks(task.id).get();
        expect(retrieved!.isCompleted, isTrue);
        expect(retrieved.actualDuration!.inHours, equals(3));

        // Reopen task
        final reopenTime = firstComplete.add(const Duration(hours: 6));
        await odm
            .tasks(task.id)
            .modify(
              (task) => task.copyWith(
                isCompleted: false,
                completedAt: null,
                updatedAt: reopenTime,
              ),
            );

        retrieved = await odm.tasks(task.id).get();
        expect(retrieved!.isCompleted, isFalse);
        expect(retrieved.completedAt, isNull);
        expect(
          retrieved.actualDuration,
          isNotNull,
        ); // Preserve previous duration

        // Second completion cycle
        final secondStart = reopenTime.add(const Duration(hours: 1));
        final secondComplete = secondStart.add(const Duration(hours: 2));
        final additionalDuration = secondComplete.difference(secondStart);
        final totalDuration = firstDuration + additionalDuration;

        await odm
            .tasks(task.id)
            .modify(
              (task) => task.copyWith(
                startedAt: secondStart, // Update to most recent start
                completedAt: secondComplete,
                actualDuration: totalDuration,
                isCompleted: true,
                updatedAt: secondComplete,
              ),
            );

        final finalTask = await odm.tasks(task.id).get();
        expect(finalTask!.isCompleted, isTrue);
        expect(finalTask.actualDuration!.inHours, equals(5)); // 3 + 2 hours
      });
    });

    group('⏰ Time Tracking Edge Cases', () {
      test(
        'should handle tasks completed before start time (data integrity)',
        () async {
          final createdTime = DateTime.now().subtract(const Duration(hours: 2));
          final invalidCompleteTime = DateTime.now().subtract(
            const Duration(hours: 1),
          );
          final invalidStartTime = DateTime.now(); // After completion!

          final task = Task(
            id: 'invalid_timing_task',
            title: 'Invalid Timing Task',
            description: 'Task with invalid start/completion timing',
            estimatedDuration: const Duration(hours: 1),
            actualDuration: const Duration(minutes: -60), // Negative duration
            isCompleted: true,
            priority: 1,
            createdAt: createdTime,
            startedAt: invalidStartTime,
            completedAt: invalidCompleteTime,
          );

          await odm.tasks(task.id).update(task);
          final retrieved = await odm.tasks(task.id).get();

          expect(retrieved, isNotNull);
          // The system should store what we give it, even if logically invalid
          expect(retrieved!.startedAt, equals(invalidStartTime));
          expect(retrieved.completedAt, equals(invalidCompleteTime));
          expect(retrieved.actualDuration!.isNegative, isTrue);

          // Calculate the "correct" duration based on stored times
          final calculatedDuration = retrieved.completedAt!.difference(
            retrieved.startedAt!,
          );
          expect(calculatedDuration.isNegative, isTrue);
          expect(calculatedDuration.inMinutes, equals(-60));
        },
      );

      test('should handle very short duration tasks', () async {
        final startTime = DateTime.now();
        final endTime = startTime.add(const Duration(milliseconds: 500));
        final shortDuration = endTime.difference(startTime);

        final task = Task(
          id: 'microsecond_task',
          title: 'Microsecond Task',
          description: 'Very short duration task',
          estimatedDuration: const Duration(seconds: 1),
          actualDuration: shortDuration,
          isCompleted: true,
          priority: 1,
          createdAt: startTime.subtract(const Duration(minutes: 1)),
          startedAt: startTime,
          completedAt: endTime,
        );

        await odm.tasks(task.id).update(task);
        final retrieved = await odm.tasks(task.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.actualDuration!.inMilliseconds, equals(500));
        expect(retrieved.actualDuration, lessThan(retrieved.estimatedDuration));
      });

      test('should handle very long duration tasks', () async {
        final startTime = DateTime.now().subtract(const Duration(days: 365));
        final endTime = DateTime.now();
        final longDuration = endTime.difference(startTime);

        final task = Task(
          id: 'year_long_task',
          title: 'Year Long Task',
          description: 'Task that took a full year',
          estimatedDuration: const Duration(days: 30),
          actualDuration: longDuration,
          isCompleted: true,
          priority: 1,
          createdAt: startTime.subtract(const Duration(days: 1)),
          startedAt: startTime,
          completedAt: endTime,
        );

        await odm.tasks(task.id).update(task);
        final retrieved = await odm.tasks(task.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.actualDuration!.inDays, equals(365));
        expect(
          retrieved.actualDuration,
          greaterThan(retrieved.estimatedDuration),
        );

        // Verify the duration is approximately a year
        expect(retrieved.actualDuration!.inDays, greaterThanOrEqualTo(364));
        expect(retrieved.actualDuration!.inDays, lessThanOrEqualTo(366));
      });

      test(
        'should handle tasks with null duration but valid timestamps',
        () async {
          final startTime = DateTime.now().subtract(const Duration(hours: 2));
          final endTime = DateTime.now();

          final task = Task(
            id: 'null_duration_task',
            title: 'Null Duration Task',
            description: 'Task with timestamps but null actual duration',
            estimatedDuration: const Duration(hours: 2),
            isCompleted: true,
            priority: 1,
            createdAt: startTime.subtract(const Duration(hours: 1)),
            startedAt: startTime,
            completedAt: endTime,
          );

          await odm.tasks(task.id).update(task);
          final retrieved = await odm.tasks(task.id).get();

          expect(retrieved, isNotNull);
          expect(retrieved!.actualDuration, isNull);
          expect(retrieved.startedAt, isNotNull);
          expect(retrieved.completedAt, isNotNull);
          expect(retrieved.isCompleted, isTrue);

          // We can still calculate duration from timestamps
          final implicitDuration = retrieved.completedAt!.difference(
            retrieved.startedAt!,
          );
          expect(implicitDuration.inHours, equals(2));
        },
      );
    });

    group('📈 Time Tracking Analytics', () {
      test('should analyze task completion patterns over time', () async {
        final baseTime = DateTime(2024);

        // Create tasks completed over different time periods
        final tasks = List.generate(10, (index) {
          final dayOffset = index * 3; // Every 3 days
          final taskStart = baseTime.add(Duration(days: dayOffset));
          final taskEnd = taskStart.add(
            Duration(hours: 2 + index),
          ); // Increasing duration

          return Task(
            id: 'pattern_task_$index',
            title: 'Pattern Task $index',
            description: 'Task for pattern analysis',
            estimatedDuration: const Duration(hours: 2),
            actualDuration: taskEnd.difference(taskStart),
            isCompleted: true,
            priority: index % 3 + 1,
            createdAt: taskStart.subtract(const Duration(hours: 1)),
            startedAt: taskStart,
            completedAt: taskEnd,
          );
        });

        for (final task in tasks) {
          await odm.tasks(task.id).update(task);
        }

        // Retrieve all tasks and analyze patterns
        final retrievedTasks = await Future.wait(
          tasks.map((task) => odm.tasks(task.id).get()),
        );

        // Calculate average duration over time
        var totalDuration = Duration.zero;
        for (final task in retrievedTasks) {
          totalDuration += task!.actualDuration!;
        }
        final averageDuration = Duration(
          microseconds: totalDuration.inMicroseconds ~/ retrievedTasks.length,
        );

        expect(
          averageDuration.inHours,
          equals(6),
        ); // (2+3+4+...+11)/10 = 6.5 ≈ 6

        // Find longest and shortest tasks
        final durations = retrievedTasks
            .map((task) => task!.actualDuration!)
            .toList();
        durations.sort((a, b) => a.inMicroseconds.compareTo(b.inMicroseconds));

        expect(durations.first.inHours, equals(2)); // Shortest
        expect(durations.last.inHours, equals(11)); // Longest

        // Calculate completion rate over time (all should be completed)
        final completedCount = retrievedTasks
            .where((task) => task!.isCompleted)
            .length;
        expect(completedCount, equals(10)); // 100% completion rate
      });
    });
  });
}
