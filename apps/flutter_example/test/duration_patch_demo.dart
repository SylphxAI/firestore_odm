import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/task.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🎯 Duration Patch Demo', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    test(
      'Duration fields now support chain syntax patch operations! 🚀',
      () async {
        // Create a task with initial duration values
        final task = Task(
          id: 'duration_demo',
          title: 'Duration Patch Demo',
          description: 'Demonstrating Duration field patch support',
          estimatedDuration: const Duration(minutes: 30),
          priority: 1,
          createdAt: DateTime.now(),
        );

        await odm.tasks(task.id).update(task);

        // 🎉 Now Duration fields support chain syntax patch operations!
        await odm
            .tasks(task.id)
            .patch(
              ($) => [
                $.estimatedDuration(const Duration(hours: 2)), // ✅ Works!
                $.actualDuration(
                  const Duration(hours: 1, minutes: 30),
                ), // ✅ Works!
                $.isCompleted(true),
                $.priority.increment(1),
              ],
            );

        final result = await odm.tasks(task.id).get();

        // Verify all fields were updated correctly
        expect(result, isNotNull);
        expect(result!.estimatedDuration, equals(const Duration(hours: 2)));
        expect(
          result.actualDuration,
          equals(const Duration(hours: 1, minutes: 30)),
        );
        expect(result.isCompleted, isTrue);
        expect(result.priority, equals(2));

        print('🎉 Duration patch operations working perfectly!');
        print('📊 Estimated: ${result.estimatedDuration}');
        print('⏱️  Actual: ${result.actualDuration}');
        print('✅ Completed: ${result.isCompleted}');
        print('🔢 Priority: ${result.priority}');
      },
    );

    test('Duration fields can be set to null using patch', () async {
      final task = Task(
        id: 'duration_null_demo',
        title: 'Duration Null Demo',
        description: 'Testing Duration null assignment',
        estimatedDuration: const Duration(hours: 1),
        actualDuration: const Duration(minutes: 45),
        isCompleted: true,
        priority: 1,
        createdAt: DateTime.now(),
      );

      await odm.tasks(task.id).update(task);

      // Set actualDuration to null using patch
      await odm
          .tasks(task.id)
          .patch(
            ($) => [
              $.actualDuration(null), // ✅ Works!
              $.isCompleted(false),
            ],
          );

      final result = await odm.tasks(task.id).get();

      expect(result, isNotNull);
      expect(
        result!.estimatedDuration,
        equals(const Duration(hours: 1)),
      ); // Unchanged
      expect(result.actualDuration, isNull); // Set to null
      expect(result.isCompleted, isFalse); // Updated

      print('🎯 Duration null assignment working correctly!');
    });
  });
}
