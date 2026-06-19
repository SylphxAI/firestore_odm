import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📅 DateTime Query Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('🔍 DateTime Range Queries', () {
      test('should query users by creation date range', () async {
        final baseDate = DateTime(2024);
        final users = [
          User(
            id: 'user_old',
            name: 'Old User',
            email: 'old@example.com',
            age: 30,
            profile: const Profile(
              bio: 'Old user bio',
              avatar: 'avatar1.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: baseDate.subtract(
              const Duration(days: 30),
            ), // Before range
          ),
          User(
            id: 'user_new',
            name: 'New User',
            email: 'new@example.com',
            age: 25,
            profile: const Profile(
              bio: 'New user bio',
              avatar: 'avatar2.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: baseDate.add(const Duration(days: 15)), // In range
          ),
          User(
            id: 'user_recent',
            name: 'Recent User',
            email: 'recent@example.com',
            age: 28,
            profile: const Profile(
              bio: 'Recent user bio',
              avatar: 'avatar3.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: baseDate.add(const Duration(days: 45)), // After range
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Query users created after baseDate using ODM
        final recentUsers = await odm.users
            .where(($) => $.createdAt(isGreaterThan: baseDate))
            .get();

        expect(recentUsers.length, equals(2));
        final recentUserIds = recentUsers.map((user) => user.id).toList();
        expect(recentUserIds, containsAll(['user_new', 'user_recent']));
        expect(recentUserIds, isNot(contains('user_old')));

        // Query users created between baseDate and baseDate + 30 days using ODM
        final midRangeUsers = await odm.users
            .where(($) => $.createdAt(isGreaterThan: baseDate))
            .where(
              ($) => $.createdAt(
                isLessThan: baseDate.add(const Duration(days: 30)),
              ),
            )
            .get();

        expect(midRangeUsers.length, equals(1));
        expect(midRangeUsers.first.id, equals('user_new'));
      });

      test('should query posts by publication date', () async {
        final now = DateTime.now();
        final posts = [
          Post(
            id: 'draft_post',
            title: 'Draft Post',
            content: 'This is a draft',
            authorId: 'author1',
            tags: ['draft'],
            metadata: {},
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          Post(
            id: 'published_today',
            title: 'Published Today',
            content: 'Published today',
            authorId: 'author2',
            tags: ['news'],
            metadata: {},
            published: true,
            publishedAt: now.subtract(const Duration(hours: 2)),
            createdAt: now.subtract(const Duration(days: 3)),
          ),
          Post(
            id: 'published_yesterday',
            title: 'Published Yesterday',
            content: 'Published yesterday',
            authorId: 'author3',
            tags: ['old'],
            metadata: {},
            published: true,
            publishedAt: now.subtract(const Duration(days: 1)),
            createdAt: now.subtract(const Duration(days: 2)),
          ),
        ];

        for (final post in posts) {
          await odm.posts(post.id).update(post);
        }

        // Query posts published in the last 12 hours
        final recentPosts = await odm.posts
            .where(
              ($) => $.publishedAt(
                isGreaterThan: now.subtract(const Duration(hours: 12)),
              ),
            )
            .get();

        expect(recentPosts.length, equals(1));
        expect(recentPosts.first.id, equals('published_today'));

        // Query all published posts (non-null publishedAt)
        final allPublished = await odm.posts
            .where(($) => $.publishedAt(isNotEqualTo: null))
            .get();

        expect(allPublished.length, equals(2));
        final publishedIds = allPublished.map((post) => post.id).toList();
        expect(
          publishedIds,
          containsAll(['published_today', 'published_yesterday']),
        );
      });
    });

    group('📊 DateTime Ordering and Sorting', () {
      test('should order users by last login descending', () async {
        final baseTime = DateTime(2024, 6, 1, 12);
        final users = [
          User(
            id: 'user_a',
            name: 'User A',
            email: 'a@example.com',
            age: 25,
            profile: const Profile(
              bio: 'User A bio',
              avatar: 'a.jpg',
              socialLinks: {},
              interests: [],
            ),
            lastLogin: baseTime.add(const Duration(hours: 1)), // Most recent
            createdAt: baseTime,
          ),
          User(
            id: 'user_b',
            name: 'User B',
            email: 'b@example.com',
            age: 30,
            profile: const Profile(
              bio: 'User B bio',
              avatar: 'b.jpg',
              socialLinks: {},
              interests: [],
            ),
            lastLogin: baseTime.subtract(const Duration(hours: 2)), // Oldest
            createdAt: baseTime,
          ),
          User(
            id: 'user_c',
            name: 'User C',
            email: 'c@example.com',
            age: 28,
            profile: const Profile(
              bio: 'User C bio',
              avatar: 'c.jpg',
              socialLinks: {},
              interests: [],
            ),
            lastLogin: baseTime, // Middle
            createdAt: baseTime,
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Query users ordered by lastLogin descending
        final orderedUsers = await odm.users
            .orderBy(($) => ($.lastLogin(descending: true),))
            .get();

        expect(orderedUsers.length, equals(3));
        expect(orderedUsers[0].id, equals('user_a')); // Most recent
        expect(orderedUsers[1].id, equals('user_c')); // Middle
        expect(orderedUsers[2].id, equals('user_b')); // Oldest
      });

      test('should order posts by creation date ascending', () async {
        final baseTime = DateTime(2024);
        final posts = [
          Post(
            id: 'post_newest',
            title: 'Newest Post',
            content: 'Content 1',
            authorId: 'author1',
            tags: ['new'],
            metadata: {},
            createdAt: baseTime.add(const Duration(days: 10)),
          ),
          Post(
            id: 'post_oldest',
            title: 'Oldest Post',
            content: 'Content 2',
            authorId: 'author2',
            tags: ['old'],
            metadata: {},
            createdAt: baseTime,
          ),
          Post(
            id: 'post_middle',
            title: 'Middle Post',
            content: 'Content 3',
            authorId: 'author3',
            tags: ['middle'],
            metadata: {},
            createdAt: baseTime.add(const Duration(days: 5)),
          ),
        ];

        for (final post in posts) {
          await odm.posts(post.id).update(post);
        }

        // Query posts ordered by creation date ascending
        final orderedPosts = await odm.posts
            .orderBy(($) => ($.createdAt(),))
            .get();

        expect(orderedPosts.length, equals(3));
        expect(orderedPosts[0].id, equals('post_oldest'));
        expect(orderedPosts[1].id, equals('post_middle'));
        expect(orderedPosts[2].id, equals('post_newest'));
      });
    });

    group('🎯 DateTime Filtering and Combinations', () {
      test('should filter active users with recent activity', () async {
        final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
        final users = [
          User(
            id: 'active_recent',
            name: 'Active Recent User',
            email: 'active.recent@example.com',
            age: 25,
            profile: Profile(
              bio: 'Active user',
              avatar: 'active.jpg',
              socialLinks: {},
              interests: [],
              lastActive: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            isActive: true,
            lastLogin: DateTime.now().subtract(const Duration(hours: 1)),
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          User(
            id: 'active_old',
            name: 'Active Old User',
            email: 'active.old@example.com',
            age: 35,
            profile: Profile(
              bio: 'Active but old',
              avatar: 'old.jpg',
              socialLinks: {},
              interests: [],
              lastActive: DateTime.now().subtract(const Duration(days: 10)),
            ),
            isActive: true,
            lastLogin: DateTime.now().subtract(const Duration(days: 9)),
            createdAt: DateTime.now().subtract(const Duration(days: 60)),
          ),
          User(
            id: 'inactive_recent',
            name: 'Inactive Recent User',
            email: 'inactive.recent@example.com',
            age: 28,
            profile: Profile(
              bio: 'Inactive user',
              avatar: 'inactive.jpg',
              socialLinks: {},
              interests: [],
              lastActive: DateTime.now().subtract(const Duration(hours: 3)),
            ),
            lastLogin: DateTime.now().subtract(const Duration(hours: 2)),
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
          ),
        ];

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // Query active users with recent login (within 7 days)
        final activeRecentUsers = await odm.users
            .where(($) => $.isActive(isEqualTo: true))
            .where(($) => $.lastLogin(isGreaterThan: cutoffDate))
            .get();

        expect(activeRecentUsers.length, equals(1));
        expect(activeRecentUsers.first.id, equals('active_recent'));
      });

      test('should query posts by author and date range', () async {
        final startDate = DateTime(2024);
        final endDate = DateTime(2024, 2);

        final posts = [
          Post(
            id: 'author1_in_range',
            title: 'Author 1 In Range',
            content: 'Content',
            authorId: 'author1',
            tags: ['test'],
            metadata: {},
            createdAt: DateTime(2024, 1, 15),
          ),
          Post(
            id: 'author1_out_range',
            title: 'Author 1 Out Range',
            content: 'Content',
            authorId: 'author1',
            tags: ['test'],
            metadata: {},
            createdAt: DateTime(2024, 3),
          ),
          Post(
            id: 'author2_in_range',
            title: 'Author 2 In Range',
            content: 'Content',
            authorId: 'author2',
            tags: ['test'],
            metadata: {},
            createdAt: DateTime(2024, 1, 20),
          ),
        ];

        for (final post in posts) {
          await odm.posts(post.id).update(post);
        }

        // Query posts by author1 within date range
        final author1Posts = await odm.posts
            .where(($) => $.authorId(isEqualTo: 'author1'))
            .where(($) => $.createdAt(isGreaterThanOrEqualTo: startDate))
            .where(($) => $.createdAt(isLessThan: endDate))
            .get();

        expect(author1Posts.length, equals(1));
        expect(author1Posts.first.id, equals('author1_in_range'));
      });
    });

    group('📈 DateTime Pagination', () {
      test('should paginate users by creation date', () async {
        final baseDate = DateTime(2024);
        final users = List.generate(
          5,
          (index) => User(
            id: 'user_$index',
            name: 'User $index',
            email: 'user$index@example.com',
            age: 20 + index,
            profile: Profile(
              bio: 'Bio $index',
              avatar: 'avatar$index.jpg',
              socialLinks: {},
              interests: [],
            ),
            createdAt: baseDate.add(Duration(days: index)),
          ),
        );

        for (final user in users) {
          await odm.users(user.id).update(user);
        }

        // First page: Get first 2 users
        final firstPage = await odm.users
            .orderBy(($) => ($.createdAt(),))
            .limit(2)
            .get();

        print('First page users: ${firstPage.map((u) => u.id).join(', ')}');
        expect(firstPage.length, equals(2));
        expect(firstPage[0].id, equals('user_0'));
        expect(firstPage[1].id, equals('user_1'));

        // Second page: Get next 2 users starting after the last user's createdAt
        final lastCreatedAt = firstPage.last.createdAt;
        final secondPage = await odm.users
            .orderBy(($) => ($.createdAt(),))
            .where(($) => $.createdAt(isGreaterThan: lastCreatedAt))
            .limit(2)
            .get();

        expect(secondPage.length, equals(2));
        expect(secondPage[0].id, equals('user_2'));
        expect(secondPage[1].id, equals('user_3'));
      });
    });

    group('🕐 DateTime Null Handling', () {
      test(
        'should handle null vs non-null DateTime fields in queries',
        () async {
          final users = [
            User(
              id: 'user_with_login',
              name: 'User With Login',
              email: 'with.login@example.com',
              age: 25,
              profile: const Profile(
                bio: 'Has login',
                avatar: 'with.jpg',
                socialLinks: {},
                interests: [],
              ),
              lastLogin: DateTime.now(),
              createdAt: DateTime.now(),
            ),
            User(
              id: 'user_never_logged',
              name: 'User Never Logged',
              email: 'never.logged@example.com',
              age: 30,
              profile: const Profile(
                bio: 'Never logged in',
                avatar: 'never.jpg',
                socialLinks: {},
                interests: [],
              ),
              createdAt: DateTime.now(),
            ),
          ];

          for (final user in users) {
            await odm.users(user.id).update(user);
          }

          // Query users who have logged in
          final loggedInUsers = await odm.users
              .where(($) => $.lastLogin(isNotEqualTo: null))
              .get();

          expect(loggedInUsers.length, equals(1));
          expect(loggedInUsers.first.id, equals('user_with_login'));

          // Query users who have never logged in
          final neverLoggedUsers = await odm.users
              .where(($) => $.lastLogin(isEqualTo: null))
              .get();

          expect(neverLoggedUsers.length, equals(1));
          expect(neverLoggedUsers.first.id, equals('user_never_logged'));
        },
      );
    });
  });
}
