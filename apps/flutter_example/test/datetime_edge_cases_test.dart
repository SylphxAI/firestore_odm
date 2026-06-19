import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/test_schema.dart';

void main() {
  group('🧪 DateTime Edge Cases Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🌍 Timezone and UTC Handling', () {
      test('should handle UTC vs local DateTime consistently', () async {
        final utcTime = DateTime.utc(2024, 6, 15, 12);
        final localTime = DateTime(2024, 6, 15, 12);

        final userUtc = User(
          id: 'user_utc',
          name: 'UTC User',
          email: 'utc@example.com',
          age: 25,
          profile: const Profile(
            bio: 'UTC user',
            avatar: 'utc.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: utcTime,
          lastLogin: utcTime,
        );

        final userLocal = User(
          id: 'user_local',
          name: 'Local User',
          email: 'local@example.com',
          age: 30,
          profile: const Profile(
            bio: 'Local user',
            avatar: 'local.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: localTime,
          lastLogin: localTime,
        );

        await odm.users(userUtc.id).update(userUtc);
        await odm.users(userLocal.id).update(userLocal);

        final retrievedUtc = await odm.users(userUtc.id).get();
        final retrievedLocal = await odm.users(userLocal.id).get();

        expect(retrievedUtc, isNotNull);
        expect(retrievedLocal, isNotNull);

        // Both should be stored and retrieved consistently
        expect(retrievedUtc!.createdAt, equals(utcTime));
        expect(retrievedLocal!.createdAt, equals(localTime));

        // UTC time should be marked as UTC
        expect(retrievedUtc.createdAt!.isUtc, isTrue);
        expect(retrievedLocal.createdAt!.isUtc, isFalse);
      });

      test('should handle timezone conversions correctly', () async {
        final utcTime = DateTime.utc(2024, 1, 1, 12);
        final localEquivalent = utcTime.toLocal();

        final user = User(
          id: 'timezone_user',
          name: 'Timezone User',
          email: 'timezone@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Timezone test',
            avatar: 'tz.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: utcTime,
          updatedAt: localEquivalent,
        );

        await odm.users(user.id).update(user);
        final retrieved = await odm.users(user.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.createdAt, equals(utcTime));
        expect(retrieved.updatedAt, equals(localEquivalent));

        // Verify they represent the same moment in time
        expect(
          retrieved.createdAt!.millisecondsSinceEpoch,
          equals(retrieved.updatedAt!.millisecondsSinceEpoch),
        );
      });
    });

    group('📏 DateTime Precision and Boundaries', () {
      test('should maintain millisecond precision', () async {
        final preciseTime = DateTime.fromMillisecondsSinceEpoch(
          1704067200123, // 2024-01-01 00:00:00.123 UTC
        );

        final user = User(
          id: 'precise_user',
          name: 'Precise User',
          email: 'precise@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Precision test',
            avatar: 'precise.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: preciseTime,
        );

        await odm.users(user.id).update(user);
        final retrieved = await odm.users(user.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.createdAt, equals(preciseTime));
        expect(
          retrieved.createdAt!.millisecondsSinceEpoch,
          equals(preciseTime.millisecondsSinceEpoch),
        );
        expect(retrieved.createdAt!.millisecond, equals(123));
      });

      test('should handle microsecond precision if supported', () async {
        final microsecondTime = DateTime.fromMicrosecondsSinceEpoch(
          1704067200123456, // 2024-01-01 00:00:00.123456 UTC
        );

        final user = User(
          id: 'microsecond_user',
          name: 'Microsecond User',
          email: 'micro@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Microsecond test',
            avatar: 'micro.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: microsecondTime,
        );

        await odm.users(user.id).update(user);
        final retrieved = await odm.users(user.id).get();

        expect(retrieved, isNotNull);
        // Note: Firestore typically stores millisecond precision
        // This test verifies the behavior with microsecond input
        expect(retrieved!.createdAt, isNotNull);
        expect(
          retrieved.createdAt!.millisecondsSinceEpoch,
          equals(microsecondTime.millisecondsSinceEpoch),
        );
      });

      test('should handle date boundaries correctly', () async {
        final dateEdgeCases = [
          DateTime(2000), // Y2K
          DateTime(2024, 2, 29), // Leap year day
          DateTime(2023, 2, 28), // Non-leap year Feb 28
          DateTime(2024, 12, 31, 23, 59, 59, 999), // Year end
          DateTime(1970), // Unix epoch
          DateTime(2038, 1, 19, 3, 14, 7), // Year 2038 problem
        ];

        for (var i = 0; i < dateEdgeCases.length; i++) {
          final date = dateEdgeCases[i];
          final user = User(
            id: 'edge_case_$i',
            name: 'Edge Case User $i',
            email: 'edge$i@example.com',
            age: 25,
            profile: Profile(
              bio: 'Edge case $i',
              avatar: 'edge$i.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: date,
          );

          await odm.users(user.id).update(user);
          final retrieved = await odm.users(user.id).get();

          expect(retrieved, isNotNull, reason: 'Failed for date: $date');
          expect(
            retrieved!.createdAt,
            equals(date),
            reason: 'Date mismatch for: $date',
          );
        }
      });
    });

    group('🎭 DateTime Extreme Values', () {
      test('should handle very old dates', () async {
        final ancientDate = DateTime(1900);

        final user = User(
          id: 'ancient_user',
          name: 'Ancient User',
          email: 'ancient@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Very old',
            avatar: 'ancient.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: ancientDate,
        );

        await odm.users(user.id).update(user);
        final retrieved = await odm.users(user.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.createdAt, equals(ancientDate));
      });

      test('should handle far future dates', () async {
        final futureDate = DateTime(2100, 12, 31);

        final user = User(
          id: 'future_user',
          name: 'Future User',
          email: 'future@example.com',
          age: 25,
          profile: const Profile(
            bio: 'From the future',
            avatar: 'future.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: futureDate,
        );

        await odm.users(user.id).update(user);
        final retrieved = await odm.users(user.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.createdAt, equals(futureDate));
      });

      test('should handle DateTime.now() variations', () async {
        final now1 = DateTime.now();
        final now2 = DateTime.now();
        final nowUtc = DateTime.now().toUtc();

        // Create users with slightly different "now" times
        final users = [
          User(
            id: 'now_1',
            name: 'Now User 1',
            email: 'now1@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Now 1',
              avatar: 'now1.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: now1,
          ),
          User(
            id: 'now_2',
            name: 'Now User 2',
            email: 'now2@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Now 2',
              avatar: 'now2.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: now2,
          ),
          User(
            id: 'now_utc',
            name: 'Now UTC User',
            email: 'nowutc@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Now UTC',
              avatar: 'nowutc.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: nowUtc,
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
          final retrieved = await odm.users(user.id).get();
          expect(retrieved, isNotNull);
          expect(retrieved!.createdAt, isNotNull);
        }

        // Verify they're all very close in time (within a few seconds)
        final retrievedUsers = await Future.wait([
          odm.users('now_1').get(),
          odm.users('now_2').get(),
          odm.users('now_utc').get(),
        ]);

        for (var i = 0; i < retrievedUsers.length - 1; i++) {
          final diff = retrievedUsers[i]!.createdAt!
              .difference(retrievedUsers[i + 1]!.createdAt!)
              .abs();
          expect(
            diff.inSeconds,
            lessThan(10),
            reason: 'DateTime.now() calls too far apart',
          );
        }
      });
    });

    group('🔄 DateTime Serialization Edge Cases', () {
      test(
        'should handle DateTime serialization round-trip with edge values',
        () async {
          final edgeDates = [
            DateTime.fromMillisecondsSinceEpoch(0), // Unix epoch
            DateTime.fromMillisecondsSinceEpoch(1), // First millisecond
            DateTime.fromMillisecondsSinceEpoch(
              -1,
            ), // Before epoch (if supported)
            DateTime(2024, 1, 1), // Exact midnight
            DateTime(2024, 1, 1, 23, 59, 59, 999), // Last millisecond of day
          ];

          for (var i = 0; i < edgeDates.length; i++) {
            final date = edgeDates[i];
            final post = Post(
              id: 'edge_post_$i',
              title: 'Edge Post $i',
              content: 'Testing edge date: $date',
              authorId: 'author',
              tags: ['edge', 'test'],
              metadata: {'edge_case': i},
              createdAt: date,
              publishedAt: date,
            );

            await odm.posts(post.id).update(post);
            final retrieved = await odm.posts(post.id).get();

            expect(retrieved, isNotNull, reason: 'Failed for edge date: $date');
            expect(
              retrieved!.createdAt,
              equals(date),
              reason: 'createdAt mismatch for: $date',
            );
            expect(
              retrieved.publishedAt,
              equals(date),
              reason: 'publishedAt mismatch for: $date',
            );

            // Verify millisecond precision is maintained
            expect(
              retrieved.createdAt.millisecondsSinceEpoch,
              equals(date.millisecondsSinceEpoch),
              reason: 'Millisecond precision lost for: $date',
            );
          }
        },
      );

      test('should handle DateTime with zero components', () async {
        final zeroComponentDates = [
          DateTime(2024, 1, 1), // All time components zero
          DateTime(2024, 1, 1, 12), // Minutes, seconds, ms zero
          DateTime(2024, 1, 1, 12, 30), // Seconds, ms zero
          DateTime(2024, 1, 1, 12, 30, 45), // Only ms zero
        ];

        for (var i = 0; i < zeroComponentDates.length; i++) {
          final date = zeroComponentDates[i];
          final user = User(
            id: 'zero_component_$i',
            name: 'Zero Component User $i',
            email: 'zero$i@example.com',
            age: 25,
            profile: Profile(
              bio: 'Zero components $i',
              avatar: 'zero$i.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: date,
          );

          await odm.users(user.id).update(user);
          final retrieved = await odm.users(user.id).get();

          expect(retrieved, isNotNull);
          expect(retrieved!.createdAt, equals(date));
          expect(retrieved.createdAt!.hour, equals(date.hour));
          expect(retrieved.createdAt!.minute, equals(date.minute));
          expect(retrieved.createdAt!.second, equals(date.second));
          expect(retrieved.createdAt!.millisecond, equals(date.millisecond));
        }
      });
    });

    group('🚫 DateTime Null Safety Edge Cases', () {
      test(
        'should handle transitions between null and non-null DateTime fields',
        () async {
          final user = User(
            id: 'null_transition_user',
            name: 'Null Transition User',
            email: 'null.transition@example.com',
            age: 25,
            profile: const Profile(
              bio: 'Testing null transitions',
              avatar: 'null.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: DateTime.now(),
          );

          // Initial state: lastLogin is null
          await odm.users(user.id).update(user);
          var retrieved = await odm.users(user.id).get();
          expect(retrieved!.lastLogin, isNull);
          expect(retrieved.updatedAt, isNull);

          // Update to non-null
          final loginTime = DateTime.now();
          await odm
              .users(user.id)
              .modify(
                (user) => user.copyWith(
                  lastLogin: loginTime,
                  updatedAt: DateTime.now(),
                ),
              );

          retrieved = await odm.users(user.id).get();
          expect(retrieved!.lastLogin, isNotNull);
          expect(retrieved.lastLogin, equals(loginTime));
          expect(retrieved.updatedAt, isNotNull);

          // Update back to null
          await odm
              .users(user.id)
              .modify(
                (user) => user.copyWith(lastLogin: null, updatedAt: null),
              );

          retrieved = await odm.users(user.id).get();
          expect(retrieved!.lastLogin, isNull);
          expect(retrieved.updatedAt, isNull);
        },
      );

      test('should handle multiple null DateTime fields correctly', () async {
        final user = User(
          id: 'multi_null_user',
          name: 'Multi Null User',
          email: 'multi.null@example.com',
          age: 25,
          profile: const Profile(
            bio: 'All dates null except required',
            avatar: 'multinull.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: DateTime.now(), // Required field
        );

        await odm.users(user.id).update(user);
        final retrieved = await odm.users(user.id).get();

        expect(retrieved, isNotNull);
        expect(retrieved!.createdAt, isNotNull); // Required
        expect(retrieved.lastLogin, isNull);
        expect(retrieved.updatedAt, isNull);
        expect(retrieved.profile.lastActive, isNull);
      });
    });

    group('⚠️ DateTime Comparison Edge Cases', () {
      test(
        'should handle DateTime equality with different precisions',
        () async {
          final baseTime = DateTime(2024, 6, 15, 12, 30, 45);
          final timeWithMs = DateTime(2024, 6, 15, 12, 30, 45, 123);
          final timeWithMicros = DateTime(2024, 6, 15, 12, 30, 45, 123, 456);

          final users = [
            User(
              id: 'base_time',
              name: 'Base Time',
              email: 'base@example.com',
              age: 25,
              profile: const Profile(
                bio: 'Base',
                avatar: 'base.jpg',
                socialLinks: {},
                interests: [],
              ),
              createdAt: baseTime,
            ),
            User(
              id: 'time_with_ms',
              name: 'Time With Ms',
              email: 'ms@example.com',
              age: 25,
              profile: const Profile(
                bio: 'With Ms',
                avatar: 'ms.jpg',
                socialLinks: {},
                interests: [],
              ),
              createdAt: timeWithMs,
            ),
            User(
              id: 'time_with_micros',
              name: 'Time With Micros',
              email: 'micros@example.com',
              age: 25,
              profile: const Profile(
                bio: 'With Micros',
                avatar: 'micros.jpg',
                socialLinks: {},
                interests: [],
              ),
              createdAt: timeWithMicros,
            ),
          ];

          for (final user in users) {
            await odm.users(user.id).update(user);
          }

          final retrievedUsers = await Future.wait([
            odm.users('base_time').get(),
            odm.users('time_with_ms').get(),
            odm.users('time_with_micros').get(),
          ]);

          // Verify times are different due to precision
          expect(
            retrievedUsers[0]!.createdAt!.millisecondsSinceEpoch,
            isNot(equals(retrievedUsers[1]!.createdAt!.millisecondsSinceEpoch)),
          );

          // But they should be very close (same second)
          expect(
            retrievedUsers[0]!.createdAt!
                .difference(retrievedUsers[1]!.createdAt!)
                .abs()
                .inSeconds,
            equals(0),
          );
        },
      );

      test('should handle DateTime arithmetic edge cases', () async {
        final baseTime = DateTime(2024, 1, 1, 12);

        // Test duration arithmetic that crosses boundaries
        final endOfYear = DateTime(2023, 12, 31, 23, 59, 59);
        final startOfYear = DateTime(2024, 1);
        final yearBoundaryDiff = startOfYear.difference(endOfYear);

        expect(yearBoundaryDiff.inSeconds, equals(1));

        // Test leap year handling
        final beforeLeap = DateTime(2024, 2, 28, 23, 59, 59);
        final afterLeap = DateTime(2024, 3);
        final leapDiff = afterLeap.difference(beforeLeap);

        expect(leapDiff.inDays, equals(1));
        expect(leapDiff.inSeconds, equals(86401)); // 24 hours + 1 second

        final user = User(
          id: 'arithmetic_user',
          name: 'Arithmetic User',
          email: 'arithmetic@example.com',
          age: 25,
          profile: const Profile(
            bio: 'Testing arithmetic',
            avatar: 'arithmetic.jpg',
            socialLinks: {},
            interests: [],
          ),
          createdAt: baseTime,
          updatedAt: baseTime.add(yearBoundaryDiff),
        );

        await odm.users(user.id).update(user);
        final retrieved = await odm.users(user.id).get();

        expect(retrieved, isNotNull);
        final calculatedDiff = retrieved!.updatedAt!.difference(
          retrieved.createdAt!,
        );
        expect(calculatedDiff, equals(yearBoundaryDiff));
      });
    });
  });
}
