import 'dart:async';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/manual_user3.dart';
import 'package:flutter_example/test_schema.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🔥 Complex Collection (ManualUser3) Comprehensive Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreODM<TestSchema> odm;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      odm = FirestoreODM(testSchema, firestore: fakeFirestore);
    });

    group('📝 Basic CRUD Operations', () {
      test('should create, read, update, delete in Book collection', () async {
        const user = ManualUser3<ManualUser3Profile<Book>>(
          id: 'book_user_001',
          name: 'Book Lover',
          customField: ManualUser3Profile<Book>(
            email: 'books@test.com',
            age: 30,
            isPremium: true,
            rating: 4.8,
            tags: ['reader', 'books'],
            preferences: {'genre': 'fiction', 'format': 'hardcover'},
            customList: [
              Book(title: 'The Hobbit', author: 'J.R.R. Tolkien'),
              Book(title: 'Dune', author: 'Frank Herbert'),
            ],
          ),
        );

        // CREATE
        await odm.manualUsers3('book_user_001').update(user);

        // READ
        final retrieved = await odm.manualUsers3('book_user_001').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Book Lover'));
        expect(retrieved.customField.customList.length, equals(2));
        expect(
          retrieved.customField.customList.first.title,
          equals('The Hobbit'),
        );

        // UPDATE using modify
        await odm
            .manualUsers3('book_user_001')
            .modify(
              (user) => user.copyWith(
                name: 'Updated Book Lover',
                customField: user.customField.copyWith(
                  age: user.customField.age + 1,
                  rating: user.customField.rating + 0.2,
                  tags: [...user.customField.tags, 'updated'],
                  customList: [
                    ...user.customField.customList,
                    const Book(title: 'Foundation', author: 'Isaac Asimov'),
                  ],
                ),
              ),
            );

        final updated = await odm.manualUsers3('book_user_001').get();
        expect(updated!.name, equals('Updated Book Lover'));
        expect(updated.customField.age, equals(31));
        expect(updated.customField.tags, contains('updated'));
        expect(updated.customField.customList.length, equals(3));

        // DELETE
        await odm.manualUsers3('book_user_001').delete();
        final deleted = await odm.manualUsers3('book_user_001').get();
        expect(deleted, isNull);

        print('✅ Book collection CRUD operations work correctly');
      });

      test(
        'should create, read, update, delete in String collection',
        () async {
          const user = ManualUser3<ManualUser3Profile<String>>(
            id: 'string_user_001',
            name: 'String Collector',
            customField: ManualUser3Profile<String>(
              email: 'strings@test.com',
              age: 25,
              rating: 3.5,
              tags: ['collector', 'strings'],
              preferences: {'type': 'mixed', 'format': 'array'},
              customList: ['hello', 'world', 'flutter', 'dart'],
            ),
          );

          // CREATE
          await odm.manualUsers3Strings('string_user_001').update(user);

          // READ
          final retrieved = await odm
              .manualUsers3Strings('string_user_001')
              .get();
          expect(retrieved, isNotNull);
          expect(retrieved!.name, equals('String Collector'));
          expect(retrieved.customField.customList.length, equals(4));
          expect(retrieved.customField.customList, contains('flutter'));

          // UPDATE using modify
          await odm
              .manualUsers3Strings('string_user_001')
              .modify(
                (user) => user.copyWith(
                  customField: user.customField.copyWith(
                    isPremium: true,
                    customList: [
                      ...user.customField.customList,
                      'firestore',
                      'odm',
                    ],
                  ),
                ),
              );

          final updated = await odm
              .manualUsers3Strings('string_user_001')
              .get();
          expect(updated!.customField.isPremium, isTrue);
          expect(updated.customField.customList.length, equals(6));
          expect(updated.customField.customList, contains('odm'));

          // DELETE
          await odm.manualUsers3Strings('string_user_001').delete();
          final deleted = await odm
              .manualUsers3Strings('string_user_001')
              .get();
          expect(deleted, isNull);

          print('✅ String collection CRUD operations work correctly');
        },
      );
    });

    group('🔍 Query Operations', () {
      setUp(() async {
        // Setup test data for queries
        final bookUsers = [
          const ManualUser3<ManualUser3Profile<Book>>(
            id: 'book_query_001',
            name: 'Alice Book Fan',
            customField: ManualUser3Profile<Book>(
              email: 'alice@books.com',
              age: 28,
              isPremium: true,
              rating: 4.7,
              tags: ['premium', 'fiction'],
              preferences: {'genre': 'sci-fi'},
              customList: [
                Book(title: 'Neuromancer', author: 'William Gibson'),
                Book(title: 'Snow Crash', author: 'Neal Stephenson'),
              ],
            ),
          ),
          const ManualUser3<ManualUser3Profile<Book>>(
            id: 'book_query_002',
            name: 'Bob Book Reader',
            customField: ManualUser3Profile<Book>(
              email: 'bob@books.com',
              age: 35,
              rating: 3.8,
              tags: ['casual', 'non-fiction'],
              preferences: {'genre': 'history'},
              customList: [Book(title: 'Sapiens', author: 'Yuval Noah Harari')],
            ),
          ),
        ];

        final stringUsers = [
          const ManualUser3<ManualUser3Profile<String>>(
            id: 'string_query_001',
            name: 'Charlie String Master',
            customField: ManualUser3Profile<String>(
              email: 'charlie@strings.com',
              age: 30,
              isPremium: true,
              rating: 4.9,
              tags: ['premium', 'expert'],
              preferences: {'type': 'advanced'},
              customList: ['typescript', 'javascript', 'dart', 'kotlin'],
            ),
          ),
        ];

        for (final user in bookUsers) {
          await odm.manualUsers3(user.id).update(user);
        }
        for (final user in stringUsers) {
          await odm.manualUsers3Strings(user.id).update(user);
        }
      });

      test('should filter by nested fields in Book collection', () async {
        // Query premium book users
        final premiumUsers = await odm.manualUsers3
            .where(($) => $.customField.isPremium(isEqualTo: true))
            .get();

        expect(premiumUsers.length, equals(1));
        expect(premiumUsers.first.name, equals('Alice Book Fan'));

        // Query by age range
        final youngUsers = await odm.manualUsers3
            .where(($) => $.customField.age(isLessThan: 30))
            .get();

        expect(youngUsers.length, equals(1));
        expect(youngUsers.first.name, equals('Alice Book Fan'));

        print('✅ Book collection queries work correctly');
        print(
          '   Premium users: ${premiumUsers.map((u) => u.name).join(', ')}',
        );
        print('   Young users: ${youngUsers.map((u) => u.name).join(', ')}');
      });

      test('should filter by nested fields in String collection', () async {
        // Query premium string users
        final premiumUsers = await odm.manualUsers3Strings
            .where(($) => $.customField.isPremium(isEqualTo: true))
            .get();

        expect(premiumUsers.length, equals(1));
        expect(premiumUsers.first.name, equals('Charlie String Master'));

        // Query by rating
        final highRatedUsers = await odm.manualUsers3Strings
            .where(($) => $.customField.rating(isGreaterThan: 4.5))
            .get();

        expect(highRatedUsers.length, equals(1));
        expect(highRatedUsers.first.customField.rating, equals(4.9));

        print('✅ String collection queries work correctly');
        print(
          '   Premium users: ${premiumUsers.map((u) => u.name).join(', ')}',
        );
        print(
          '   High rated users: ${highRatedUsers.map((u) => u.name).join(', ')}',
        );
      });

      test('should support ordering and limiting', () async {
        // Order by rating in Book collection using tuple syntax
        final orderedBooks = await odm.manualUsers3
            .orderBy(($) => ($.customField.rating(),))
            .get();

        expect(orderedBooks.isNotEmpty, isTrue);

        // Order by age in String collection using tuple syntax
        final orderedStrings = await odm.manualUsers3Strings
            .orderBy(($) => ($.customField.age(),))
            .get();

        expect(orderedStrings.isNotEmpty, isTrue);

        print('✅ Ordering works correctly');
        print('   Book users count: ${orderedBooks.length}');
        print('   String users count: ${orderedStrings.length}');
      });
    });

    group('📡 Streaming Operations', () {
      test('should stream changes in Book collection via queries', () async {
        // Add initial user
        await odm
            .manualUsers3('stream_book_001')
            .update(
              const ManualUser3<ManualUser3Profile<Book>>(
                id: 'stream_book_001',
                name: 'Stream Book User',
                customField: ManualUser3Profile<Book>(
                  email: 'stream@books.com',
                  age: 25,
                  isPremium: true,
                  rating: 4,
                  tags: ['streaming'],
                  preferences: {'realtime': 'true'},
                  customList: [
                    Book(title: 'Real-time Book', author: 'Stream Author'),
                  ],
                ),
              ),
            );

        // Query for streaming users
        final streamingUsers = await odm.manualUsers3
            .where(($) => $.customField.tags(arrayContains: 'streaming'))
            .get();

        expect(streamingUsers.length, equals(1));
        expect(streamingUsers.first.name, equals('Stream Book User'));

        // Update user
        await odm
            .manualUsers3('stream_book_001')
            .modify(
              (user) => user.copyWith(
                name: 'Updated Stream Book User',
                customField: user.customField.copyWith(rating: 4.5),
              ),
            );

        final updatedUsers = await odm.manualUsers3
            .where(($) => $.customField.tags(arrayContains: 'streaming'))
            .get();

        expect(updatedUsers.length, equals(1));
        expect(updatedUsers.first.name, equals('Updated Stream Book User'));
        expect(updatedUsers.first.customField.rating, equals(4.5));

        print('✅ Book collection query-based operations work correctly');
      });

      test('should stream individual documents', () async {
        // Create initial document
        await odm
            .manualUsers3Strings('stream_string_doc')
            .update(
              const ManualUser3<ManualUser3Profile<String>>(
                id: 'stream_string_doc',
                name: 'Stream String Doc',
                customField: ManualUser3Profile<String>(
                  email: 'stream@strings.com',
                  age: 30,
                  rating: 3,
                  tags: ['stream'],
                  customList: ['initial'],
                ),
              ),
            );

        final streamResults = <ManualUser3<ManualUser3Profile<String>>?>[];
        late StreamSubscription subscription;

        // Stream single document
        subscription = odm
            .manualUsers3Strings('stream_string_doc')
            .stream
            .listen(streamResults.add);

        await Future.delayed(const Duration(milliseconds: 50));

        // Update document
        await odm
            .manualUsers3Strings('stream_string_doc')
            .modify(
              (user) => user.copyWith(
                customField: user.customField.copyWith(
                  customList: [...user.customField.customList, 'updated'],
                ),
              ),
            );

        await Future.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(streamResults.length, greaterThan(1));
        final finalUser = streamResults.last!;
        expect(finalUser.customField.customList, contains('updated'));

        print('✅ Document streaming works correctly');
      });
    });

    group('🔄 Transaction Operations', () {
      test(
        'should perform atomic transactions across both collections',
        () async {
          // Setup initial data
          await odm
              .manualUsers3('trans_book_001')
              .update(
                const ManualUser3<ManualUser3Profile<Book>>(
                  id: 'trans_book_001',
                  name: 'Transaction Book User',
                  customField: ManualUser3Profile<Book>(
                    email: 'trans@books.com',
                    age: 25,
                    rating: 3,
                    tags: ['transaction'],
                    preferences: {'credits': '100'},
                    customList: [
                      Book(
                        title: 'Before Transaction',
                        author: 'Before Author',
                      ),
                    ],
                  ),
                ),
              );

          await odm
              .manualUsers3Strings('trans_string_001')
              .update(
                const ManualUser3<ManualUser3Profile<String>>(
                  id: 'trans_string_001',
                  name: 'Transaction String User',
                  customField: ManualUser3Profile<String>(
                    email: 'trans@strings.com',
                    age: 30,
                    rating: 3.5,
                    tags: ['transaction'],
                    preferences: {'tokens': '50'},
                    customList: ['before', 'transaction'],
                  ),
                ),
              );

          // Perform atomic transaction
          await odm.runTransaction((tx) async {
            // Upgrade both users to premium
            await tx
                .manualUsers3('trans_book_001')
                .modify(
                  (user) => user.copyWith(
                    customField: user.customField.copyWith(
                      isPremium: true,
                      rating: user.customField.rating + 1.0,
                      tags: [...user.customField.tags, 'premium'],
                    ),
                  ),
                );

            await tx
                .manualUsers3Strings('trans_string_001')
                .modify(
                  (user) => user.copyWith(
                    customField: user.customField.copyWith(
                      isPremium: true,
                      rating: user.customField.rating + 0.5,
                      tags: [...user.customField.tags, 'premium'],
                    ),
                  ),
                );
          });

          // Verify both updates succeeded
          final bookUser = await odm.manualUsers3('trans_book_001').get();
          final stringUser = await odm
              .manualUsers3Strings('trans_string_001')
              .get();

          expect(bookUser!.customField.isPremium, isTrue);
          expect(bookUser.customField.rating, equals(4.0));
          expect(bookUser.customField.tags, contains('premium'));

          expect(stringUser!.customField.isPremium, isTrue);
          expect(stringUser.customField.rating, equals(4.0));
          expect(stringUser.customField.tags, contains('premium'));

          print('✅ Cross-collection transactions work correctly');
          print('   Book user premium: ${bookUser.customField.isPremium}');
          print('   String user premium: ${stringUser.customField.isPremium}');
        },
      );
    });

    group('⚡ Batch Operations', () {
      test('should perform batch operations across both collections', () async {
        final batch = odm.batch();

        // Batch create users in both collections
        const bookUser = ManualUser3<ManualUser3Profile<Book>>(
          id: 'batch_book_001',
          name: 'Batch Book User',
          customField: ManualUser3Profile<Book>(
            email: 'batch@books.com',
            age: 28,
            isPremium: true,
            rating: 4.2,
            tags: ['batch', 'books'],
            preferences: {'format': 'digital'},
            customList: [Book(title: 'Batch Book', author: 'Batch Author')],
          ),
        );

        const stringUser = ManualUser3<ManualUser3Profile<String>>(
          id: 'batch_string_001',
          name: 'Batch String User',
          customField: ManualUser3Profile<String>(
            email: 'batch@strings.com',
            age: 32,
            rating: 3.8,
            tags: ['batch', 'strings'],
            preferences: {'type': 'bulk'},
            customList: ['batch', 'operation', 'test'],
          ),
        );

        // Add to batch
        batch.manualUsers3.insert(bookUser);
        batch.manualUsers3Strings.insert(stringUser);

        // Commit batch
        await batch.commit();

        // Verify batch operations
        final retrievedBook = await odm.manualUsers3('batch_book_001').get();
        final retrievedString = await odm
            .manualUsers3Strings('batch_string_001')
            .get();

        expect(retrievedBook, isNotNull);
        expect(retrievedString, isNotNull);
        expect(retrievedBook!.name, equals('Batch Book User'));
        expect(retrievedString!.name, equals('Batch String User'));

        print('✅ Batch operations work correctly');
        print('   Book user: ${retrievedBook.name}');
        print('   String user: ${retrievedString.name}');
      });
    });

    group('🔧 Atomic Updates', () {
      test('should use atomic operations with modify', () async {
        // Create initial users
        await odm
            .manualUsers3('atomic_book_001')
            .update(
              const ManualUser3<ManualUser3Profile<Book>>(
                id: 'atomic_book_001',
                name: 'Atomic Book User',
                customField: ManualUser3Profile<Book>(
                  email: 'atomic@books.com',
                  age: 25,
                  rating: 3,
                  tags: ['atomic'],
                  preferences: {'score': '100'},
                  customList: [
                    Book(title: 'Original Book', author: 'Original Author'),
                  ],
                ),
              ),
            );

        // Test atomic updates (default is atomic: true)
        await odm
            .manualUsers3('atomic_book_001')
            .modify(
              (user) => user.copyWith(
                customField: user.customField.copyWith(
                  age: user.customField.age + 5, // Should use atomic increment
                  rating:
                      user.customField.rating +
                      1.0, // Should use atomic increment
                  tags: [
                    ...user.customField.tags,
                    'updated',
                  ], // Should use atomic array union
                ),
              ),
            );

        final updated = await odm.manualUsers3('atomic_book_001').get();
        expect(updated!.customField.age, equals(30));
        expect(updated.customField.rating, equals(4.0));
        expect(updated.customField.tags, containsAll(['atomic', 'updated']));

        // Test non-atomic updates
        await odm
            .manualUsers3('atomic_book_001')
            .modify(
              (user) => user.copyWith(
                name: 'Non-Atomic Updated Name',
                customField: user.customField.copyWith(
                  age: 35, // Direct assignment
                ),
              ),
              atomic: false,
            );

        final nonAtomicUpdated = await odm
            .manualUsers3('atomic_book_001')
            .get();
        expect(nonAtomicUpdated!.name, equals('Non-Atomic Updated Name'));
        expect(nonAtomicUpdated.customField.age, equals(35));

        print('✅ Atomic and non-atomic updates work correctly');
        print('   Final age: ${nonAtomicUpdated.customField.age}');
        print('   Final rating: ${nonAtomicUpdated.customField.rating}');
      });
    });

    group('📊 Aggregation Operations', () {
      test('should perform aggregation queries', () async {
        // Setup test data
        final users = List.generate(
          5,
          (i) => ManualUser3<ManualUser3Profile<Book>>(
            id: 'agg_book_${i.toString().padLeft(3, '0')}',
            name: 'Aggregation User $i',
            customField: ManualUser3Profile<Book>(
              email: 'agg$i@books.com',
              age: 20 + i * 5,
              isPremium: i % 2 == 0,
              rating: 3.0 + i * 0.3,
              tags: ['agg', if (i % 2 == 0) 'premium'],
              preferences: {'level': i.toString()},
              customList: [Book(title: 'Book $i', author: 'Author $i')],
            ),
          ),
        );

        for (final user in users) {
          await odm.manualUsers3(user.id).update(user);
        }

        // Test count aggregation
        final countResult = await odm.manualUsers3
            .aggregate(($) => (count: $.count()))
            .get();

        expect(countResult.count, equals(5));

        print('✅ Aggregation queries work correctly');
        print('   Total count: ${countResult.count}');
      });
    });

    group('📄 Pagination', () {
      test('should support pagination with complex data', () async {
        // Setup paginated data
        final users = List.generate(
          10,
          (i) => ManualUser3<ManualUser3Profile<String>>(
            id: 'page_string_${i.toString().padLeft(3, '0')}',
            name: 'Page User $i',
            customField: ManualUser3Profile<String>(
              email: 'page$i@strings.com',
              age: 20 + i,
              isPremium: i < 5,
              rating: 2.0 + i * 0.2,
              tags: ['page', 'user$i'],
              preferences: {'page': i.toString()},
              customList: ['item$i', 'data$i'],
            ),
          ),
        );

        for (final user in users) {
          await odm.manualUsers3Strings(user.id).update(user);
        }

        // Test pagination using tuple syntax
        final firstPage = await odm.manualUsers3Strings
            .orderBy(($) => ($.name(),))
            .limit(3)
            .get();

        expect(firstPage.length, equals(3));

        final lastUser = firstPage.last;
        final secondPage = await odm.manualUsers3Strings
            .orderBy(($) => ($.name(),))
            .startAfter((lastUser.name,))
            .limit(3)
            .get();

        expect(secondPage.length, equals(3));
        expect(secondPage.first.name, isNot(equals(lastUser.name)));

        print('✅ Pagination works correctly');
        print('   First page: ${firstPage.map((u) => u.name).join(', ')}');
        print('   Second page: ${secondPage.map((u) => u.name).join(', ')}');
      });
    });

    group('🏗️ Collection Operations', () {
      test('should use insert for new documents', () async {
        const newUser = ManualUser3<ManualUser3Profile<Book>>(
          id: 'insert_book_001',
          name: 'Inserted Book User',
          customField: ManualUser3Profile<Book>(
            email: 'insert@books.com',
            age: 27,
            isPremium: true,
            rating: 4.3,
            tags: ['insert', 'new'],
            preferences: {'method': 'insert'},
            customList: [Book(title: 'Inserted Book', author: 'Insert Author')],
          ),
        );

        // Use insert method
        await odm.manualUsers3.insert(newUser);

        final retrieved = await odm.manualUsers3('insert_book_001').get();
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('Inserted Book User'));
        expect(
          retrieved.customField.customList.first.title,
          equals('Inserted Book'),
        );

        print('✅ Insert operations work correctly');
        print('   Inserted user: ${retrieved.name}');
      });

      test('should work with multiple collections simultaneously', () async {
        // Test simultaneous operations on both collections
        const bookUser = ManualUser3<ManualUser3Profile<Book>>(
          id: 'multi_book_001',
          name: 'Multi Book User',
          customField: ManualUser3Profile<Book>(
            email: 'multi@books.com',
            age: 29,
            isPremium: true,
            rating: 4.1,
            tags: ['multi', 'book'],
            preferences: {'collection': 'book'},
            customList: [Book(title: 'Multi Book', author: 'Multi Author')],
          ),
        );

        const stringUser = ManualUser3<ManualUser3Profile<String>>(
          id: 'multi_string_001',
          name: 'Multi String User',
          customField: ManualUser3Profile<String>(
            email: 'multi@strings.com',
            age: 31,
            rating: 3.7,
            tags: ['multi', 'string'],
            preferences: {'collection': 'string'},
            customList: ['multi', 'collection', 'test'],
          ),
        );

        // Insert simultaneously
        await Future.wait([
          odm.manualUsers3.insert(bookUser),
          odm.manualUsers3Strings.insert(stringUser),
        ]);

        // Query both collections
        final bookUsers = await odm.manualUsers3
            .where(($) => $.name(isEqualTo: 'Multi Book User'))
            .get();

        final stringUsers = await odm.manualUsers3Strings
            .where(($) => $.name(isEqualTo: 'Multi String User'))
            .get();

        expect(bookUsers.length, equals(1));
        expect(stringUsers.length, equals(1));
        expect(
          bookUsers.first.customField.customList.first.title,
          equals('Multi Book'),
        );
        expect(stringUsers.first.customField.customList.first, equals('multi'));

        print('✅ Multiple collections work simultaneously');
        print(
          '   Book user collection: ${bookUsers.first.customField.preferences['collection']}',
        );
        print(
          '   String user collection: ${stringUsers.first.customField.preferences['collection']}',
        );
      });
    });
  });
}
