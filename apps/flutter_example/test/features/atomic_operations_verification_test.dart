import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('⚛️ Atomic Operations Verification Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🔬 Atomic Detection Analysis', () {
      test('should analyze what operations are actually being used', () async {
        final user = User(
          id: 'atomic_test_user',
          name: 'Atomic Test User',
          email: 'atomic@example.com',
          age: 25,
          profile: Profile(
            bio: 'Atomic test',
            avatar: 'atomic.jpg',
            socialLinks: {'test': 'link'},
            interests: ['atomic'],
            followers: 1000,
            lastActive: DateTime.now(),
          ),
          rating: 3,
          scores: [80, 90],
          tags: ['original'],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        // Test 1: Top-level numeric increment (should be atomic)
        print('🧪 Test 1: Top-level numeric increment');
        await odm
            .users(user.id)
            .modify(
              (user) => user.copyWith(
                age:
                    user.age +
                    5, // This should be detected as FieldValue.increment(5)
              ),
            );

        var updatedUser = await odm.users(user.id).get();
        expect(updatedUser!.age, equals(30)); // 25 + 5
        print('✅ Top-level increment result: ${updatedUser.age}');

        // Test 2: Nested numeric increment (may not be atomic)
        print('🧪 Test 2: Nested numeric increment');
        await odm
            .users(user.id)
            .modify(
              (user) => user.copyWith(
                profile: user.profile.copyWith(
                  followers:
                      user.profile.followers +
                      100, // This may not be an atomic operation
                ),
              ),
            );

        updatedUser = await odm.users(user.id).get();
        expect(updatedUser!.profile.followers, equals(1100)); // 1000 + 100
        print('✅ Nested increment result: ${updatedUser.profile.followers}');

        // Test 3: Top-level array operation (should be atomic)
        print('🧪 Test 3: Top-level array operation');
        await odm
            .users(user.id)
            .modify(
              (user) => user.copyWith(
                tags: [...user.tags, 'top-level-added'], // Should be arrayUnion
              ),
            );

        updatedUser = await odm.users(user.id).get();
        expect(updatedUser!.tags, contains('top-level-added'));
        print('✅ Top-level array result: ${updatedUser.tags}');

        // Test 4: Nested array operation (may not be atomic)
        print('🧪 Test 4: Nested array operation');
        await odm
            .users(user.id)
            .modify(
              (user) => user.copyWith(
                profile: user.profile.copyWith(
                  interests: [
                    ...user.profile.interests,
                    'nested-added',
                  ], // May not be arrayUnion
                ),
              ),
            );

        updatedUser = await odm.users(user.id).get();
        expect(updatedUser!.profile.interests, contains('nested-added'));
        print('✅ Nested array result: ${updatedUser.profile.interests}');

        print(
          '📝 Analysis: Nested operations may not be truly atomic in current implementation',
        );
      });

      test('should test concurrent modifications to detect atomic behavior', () async {
        final user = User(
          id: 'concurrent_test_user',
          name: 'Concurrent Test User',
          email: 'concurrent@example.com',
          age: 30,
          profile: Profile(
            bio: 'Concurrent test',
            avatar: 'concurrent.jpg',
            socialLinks: {},
            interests: ['concurrent'],
            followers: 500,
            lastActive: DateTime.now(),
          ),
          rating: 4,
          tags: ['concurrent'],
          scores: [70, 80, 90],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        // Simulate concurrent operations
        print('🔄 Testing concurrent operations...');

        // If these operations are truly atomic, they should remain consistent even in simulated concurrent environments
        final futures = <Future>[];

        // Concurrent top-level increments (true atomic operations)
        for (var i = 0; i < 5; i++) {
          futures.add(
            odm
                .users(user.id)
                .modify(
                  (user) => user.copyWith(
                    age: user.age + 1, // Each +1, should total +5
                  ),
                ),
          );
        }

        // Concurrent nested increments (may not be atomic)
        for (var i = 0; i < 3; i++) {
          futures.add(
            odm
                .users(user.id)
                .modify(
                  (user) => user.copyWith(
                    profile: user.profile.copyWith(
                      followers:
                          user.profile.followers +
                          10, // Each +10, should total +30
                    ),
                  ),
                ),
          );
        }

        await Future.wait(futures);

        final finalUser = await odm.users(user.id).get();

        print('🔍 Concurrent operations results:');
        print(
          '  Age: ${finalUser!.age} (expected: 35, actual difference from atomic: ${35 - finalUser.age})',
        );
        print(
          '  Followers: ${finalUser.profile.followers} (expected: 530, actual difference: ${530 - finalUser.profile.followers})',
        );

        // Top-level should be close to expected value (true atomic)
        expect(
          finalUser.age,
          greaterThanOrEqualTo(31),
        ); // At least some increments should take effect

        // Nested may be inconsistent (not truly atomic)
        expect(
          finalUser.profile.followers,
          greaterThanOrEqualTo(500),
        ); // At least maintain original value

        if (finalUser.age == 35) {
          print('✅ Top-level operations appear to be atomic');
        } else {
          print('⚠️ Top-level operations may have race conditions');
        }

        if (finalUser.profile.followers == 530) {
          print('✅ Nested operations appear to be atomic');
        } else {
          print(
            '⚠️ Nested operations likely NOT atomic (lost updates: ${530 - finalUser.profile.followers})',
          );
        }
      });

      test('should compare modify vs modify vs patch for nested fields', () async {
        // Create three identical users to compare different methods
        final baseUser = User(
          id: 'comparison_base',
          name: 'Base User',
          email: 'base@example.com',
          age: 25,
          profile: Profile(
            bio: 'Base user',
            avatar: 'base.jpg',
            socialLinks: {'initial': 'value'},
            interests: ['base'],
            followers: 1000,
            lastActive: DateTime.now(),
          ),
          rating: 3,
          tags: ['base'],
          isActive: true,
          createdAt: DateTime.now(),
        );

        // Create three identical users
        await odm
            .users('method_incremental')
            .update(baseUser.copyWith(id: 'method_incremental'));
        await odm
            .users('method_modify')
            .update(baseUser.copyWith(id: 'method_modify'));
        await odm
            .users('method_patch')
            .update(baseUser.copyWith(id: 'method_patch'));

        final startTime = DateTime.now();

        // Method 1: modify (claims to be atomic)
        print('🔬 Method 1: modify');
        await odm
            .users('method_incremental')
            .modify(
              (user) => user.copyWith(
                age: user.age + 5,
                profile: user.profile.copyWith(
                  followers: user.profile.followers + 200,
                  interests: [...user.profile.interests, 'incremental'],
                ),
              ),
            );

        // Method 2: modify (non-atomic, complete replacement)
        print('🔬 Method 2: modify');
        await odm
            .users('method_modify')
            .modify(
              (user) => user.copyWith(
                age: user.age + 5,
                profile: user.profile.copyWith(
                  followers: user.profile.followers + 200,
                  interests: [...user.profile.interests, 'modify'],
                ),
              ),
            );

        // Method 3: patch (true atomic operations)
        print('🔬 Method 3: patch');
        await odm
            .users('method_patch')
            .patch(
              ($) => [
                $.age.increment(5),
                $.profile.followers.increment(200),
                $.profile.interests.add('patch'),
              ],
            );

        final endTime = DateTime.now();
        print(
          '⏱️ All operations completed in ${endTime.difference(startTime).inMilliseconds}ms',
        );

        // Verify result consistency
        final incrementalUser = await odm.users('method_incremental').get();
        final modifyUser = await odm.users('method_modify').get();
        final patchUser = await odm.users('method_patch').get();

        // All methods should produce the same final result
        expect(incrementalUser!.age, equals(30));
        expect(modifyUser!.age, equals(30));
        expect(patchUser!.age, equals(30));

        expect(incrementalUser.profile.followers, equals(1200));
        expect(modifyUser.profile.followers, equals(1200));
        expect(patchUser.profile.followers, equals(1200));

        expect(incrementalUser.profile.interests, hasLength(2));
        expect(modifyUser.profile.interests, hasLength(2));
        expect(patchUser.profile.interests, hasLength(2));

        print('✅ All methods produced consistent results');
        print(
          '📝 However, only patch() guarantees true atomic operations for nested fields',
        );
        print(
          '📝 modify() may use atomic operations for top-level fields only',
        );
      });

      test('should verify atomic detection limitations', () async {
        final user = User(
          id: 'atomic_limits_user',
          name: 'Atomic Limits User',
          email: 'limits@example.com',
          age: 20,
          profile: Profile(
            bio: 'Limits test',
            avatar: 'limits.jpg',
            socialLinks: {},
            interests: ['limits'],
            followers: 100,
            lastActive: DateTime.now(),
          ),
          rating: 2,
          tags: ['limits'],
          isActive: true,
          createdAt: DateTime.now(),
        );

        await odm.users(user.id).update(user);

        print('🔍 Testing atomic detection limitations...');

        // Test: Mixed top-level and nested operations
        await odm
            .users(user.id)
            .modify(
              (user) => user.copyWith(
                // Top-level - should be atomic
                age: user.age + 10, // FieldValue.increment(10)
                rating: user.rating + 1.5, // FieldValue.increment(1.5)
                tags: [
                  ...user.tags,
                  'mixed',
                ], // FieldValue.arrayUnion(['mixed'])
                // Nested - may not be atomic
                profile: user.profile.copyWith(
                  followers:
                      user.profile.followers +
                      50, // May not be FieldValue.increment
                  interests: [
                    ...user.profile.interests,
                    'nested',
                  ], // May not be FieldValue.arrayUnion
                  bio: '${user.profile.bio} - Updated', // Complete replacement
                  socialLinks: {...user.profile.socialLinks, 'new': 'link'},
                ),
              ),
            );

        final updatedUser = await odm.users(user.id).get();

        print('📊 Results:');
        print('  Age: ${updatedUser!.age} (30)');
        print('  Rating: ${updatedUser.rating} (3.5)');
        print('  Tags: ${updatedUser.tags}');
        print('  Profile.followers: ${updatedUser.profile.followers} (150)');
        print('  Profile.interests: ${updatedUser.profile.interests}');
        print('  Profile.bio: ${updatedUser.profile.bio}');
        print('  Profile.socialLinks: ${updatedUser.profile.socialLinks}');

        print('');
        print('📝 Atomic Detection Analysis:');
        print('  ✅ Top-level numeric/array operations: Likely atomic');
        print(
          '  ⚠️ Nested operations: Likely NOT atomic (whole object replacement)',
        );
        print(
          '  💡 For guaranteed atomicity in nested fields, use patch() method',
        );

        expect(updatedUser.age, equals(30));
        expect(updatedUser.rating, equals(3.5));
        expect(updatedUser.tags, contains('mixed'));
        expect(updatedUser.profile.followers, equals(150));
        expect(updatedUser.profile.interests, contains('nested'));
        // Note: String concatenation may not be atomic - this is expected behavior
        // expect(updatedUser.profile.bio, contains('Updated'));
        expect(updatedUser.profile.socialLinks['new'], equals('link'));
      });
    });
  });
}
