import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔄 Iterable Support Tests', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: firestore);
    });

    test('should support Set with addAll and removeAll', () async {
      // Create a test user
      const user = User(
        id: 'iterable_set_user',
        name: 'Iterable Set User',
        email: 'iterable.set@example.com',
        age: 30,
        tags: ['initial', 'existing'],
        scores: [10, 20, 30],
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 100,
        ),
        isActive: true,
        rating: 4.5,
      );

      await odm.users.insert(user);

      print('🧪 Test: Using Set with addAll and removeAll');

      // Test addAll with Set
      await odm
          .users('iterable_set_user')
          .patch(
            ($) => [
              $.tags.addAll({'premium', 'verified', 'active'}), // Using Set
              $.scores.addAll({40, 50, 60}), // Using Set
            ],
          );

      var result = await odm.users('iterable_set_user').get();
      print('📊 After addAll with Set:');
      print('   Tags: ${result!.tags}');
      print('   Scores: ${result.scores}');

      expect(
        result.tags,
        containsAll(['initial', 'existing', 'premium', 'verified', 'active']),
      );
      expect(result.scores, containsAll([10, 20, 30, 40, 50, 60]));

      // Test removeAll with Set
      await odm
          .users('iterable_set_user')
          .patch(
            ($) => [
              $.tags.removeAll({'initial', 'existing'}), // Using Set
              $.scores.removeAll({10, 20}), // Using Set
            ],
          );

      result = await odm.users('iterable_set_user').get();
      print('📊 After removeAll with Set:');
      print('   Tags: ${result!.tags}');
      print('   Scores: ${result.scores}');

      expect(result.tags, containsAll(['premium', 'verified', 'active']));
      expect(result.tags, isNot(contains('initial')));
      expect(result.tags, isNot(contains('existing')));
      expect(result.scores, containsAll([30, 40, 50, 60]));
      expect(result.scores, isNot(contains(10)));
      expect(result.scores, isNot(contains(20)));

      print('✅ Set support works correctly with addAll/removeAll');
    });

    test('should support custom Iterable with addAll and removeAll', () async {
      // Create a test user
      const user = User(
        id: 'iterable_custom_user',
        name: 'Iterable Custom User',
        email: 'iterable.custom@example.com',
        age: 25,
        tags: ['start'],
        scores: [100],
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 50,
        ),
        isActive: true,
        rating: 3.5,
      );

      await odm.users.insert(user);

      print('🧪 Test: Using custom Iterable with addAll and removeAll');

      // Create custom iterables
      final customTagsIterable = [
        'custom1',
        'custom2',
        'custom3',
      ].where((tag) => tag.startsWith('custom'));
      final customScoresIterable = [200, 300, 400].map((score) => score);

      // Test addAll with custom Iterable
      await odm
          .users('iterable_custom_user')
          .patch(
            ($) => [
              $.tags.addAll(customTagsIterable), // Using custom Iterable
              $.scores.addAll(customScoresIterable), // Using custom Iterable
            ],
          );

      var result = await odm.users('iterable_custom_user').get();
      print('📊 After addAll with custom Iterable:');
      print('   Tags: ${result!.tags}');
      print('   Scores: ${result.scores}');

      expect(
        result.tags,
        containsAll(['start', 'custom1', 'custom2', 'custom3']),
      );
      expect(result.scores, containsAll([100, 200, 300, 400]));

      // Test removeAll with custom Iterable
      final removeTagsIterable = [
        'custom1',
        'custom3',
      ].where((tag) => tag.contains('1') || tag.contains('3'));
      final removeScoresIterable = [
        200,
        400,
      ].where((score) => score % 200 == 0);

      await odm
          .users('iterable_custom_user')
          .patch(
            ($) => [
              $.tags.removeAll(removeTagsIterable), // Using custom Iterable
              $.scores.removeAll(removeScoresIterable), // Using custom Iterable
            ],
          );

      result = await odm.users('iterable_custom_user').get();
      print('📊 After removeAll with custom Iterable:');
      print('   Tags: ${result!.tags}');
      print('   Scores: ${result.scores}');

      expect(result.tags, containsAll(['start', 'custom2']));
      expect(result.tags, isNot(contains('custom1')));
      expect(result.tags, isNot(contains('custom3')));
      expect(result.scores, containsAll([100, 300]));
      expect(result.scores, isNot(contains(200)));
      expect(result.scores, isNot(contains(400)));

      print('✅ Custom Iterable support works correctly with addAll/removeAll');
    });

    test('should support mixed Iterable types in same operation', () async {
      // Create a test user
      const user = User(
        id: 'iterable_mixed_user',
        name: 'Iterable Mixed User',
        email: 'iterable.mixed@example.com',
        age: 35,
        tags: ['base'],
        scores: [1],
        profile: Profile(
          bio: 'Test bio',
          avatar: 'avatar.jpg',
          socialLinks: {'twitter': '@test'},
          interests: ['tech'],
          followers: 75,
        ),
        isActive: true,
        rating: 4,
      );

      await odm.users.insert(user);

      print('🧪 Test: Using mixed Iterable types in same operation');

      // Test with different Iterable types in same patch
      await odm
          .users('iterable_mixed_user')
          .patch(
            ($) => [
              $.tags.addAll(['list1', 'list2']), // List
              $.scores.addAll({10, 20}), // Set
              $.profile.interests.addAll(
                ['music', 'sports'].where((i) => i.length > 4),
              ), // Custom Iterable
            ],
          );

      final result = await odm.users('iterable_mixed_user').get();
      print('📊 After mixed Iterable types:');
      print('   Tags: ${result!.tags}');
      print('   Scores: ${result.scores}');
      print('   Interests: ${result.profile.interests}');

      expect(result.tags, containsAll(['base', 'list1', 'list2']));
      expect(result.scores, containsAll([1, 10, 20]));
      expect(
        result.profile.interests,
        containsAll(['tech', 'music', 'sports']),
      );

      print('✅ Mixed Iterable types work correctly in same operation');
    });
  });
}
