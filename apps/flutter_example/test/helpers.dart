/// Shared test setup: a fake Firestore + ODM over the example schema.
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_example/models/post.dart';
import 'package:flutter_example/models/profile.dart';
import 'package:flutter_example/models/user.dart';
import 'package:flutter_example/test_schema.dart';

export 'package:flutter_example/test_schema.dart';
export 'package:flutter_example/models/profile.dart';
export 'package:flutter_example/models/post.dart';
export 'package:flutter_example/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fresh fake Firestore + ODM for each test.
(FakeFirebaseFirestore, FirestoreODM<TestSchema>) newDb() {
  final fake = FakeFirebaseFirestore();
  final odm = FirestoreODM(testSchema, firestore: fake);
  return (fake, odm);
}

/// A user with deterministic data.
User sampleUser({String id = 'user1', int age = 30}) => User(
  id: id,
  name: 'User $id',
  email: '$id@example.com',
  age: age,
  profile: Profile(
    bio: 'bio-$id',
    avatar: 'avatar-$id',
    socialLinks: {'github': 'https://github.com/$id'},
    interests: ['dart', 'firestore'],
    followers: 100 + age * 10,
  ),
  tags: ['tag-a', 'tag-b'],
  scores: [1, 2, 3],
  settings: {'theme': 'dark'},
  metadata: {'note': 'hello'},
  rating: 4.5,
  isActive: true,
  isPremium: false,
  lastLogin: DateTime.utc(2026, 1, 1),
  createdAt: DateTime.utc(2026, 1, 2),
  updatedAt: DateTime.utc(2026, 1, 3),
);

/// A post for subcollection tests.
Post samplePost({String id = 'post1', String author = 'user1'}) => Post(
  id: id,
  authorId: author,
  title: 'Post $id',
  content: 'Content of $id',
  tags: const ['dart'],
  metadata: const {'kind': 'post'},
  createdAt: DateTime.utc(2026, 2, 1),
);

/// Expects [future] to complete with a [FirestoreODMValidationException].
Future<void> expectValidationError(Future<void> Function() future) async {
  await expectLater(future, throwsA(isA<FirestoreODMValidationException>()));
}
