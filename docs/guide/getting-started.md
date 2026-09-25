# Getting started

From an empty Flutter app to typed reads and writes in five steps. You need
Dart 3.8 or later and a Firebase project set up for Flutter
([FlutterFire setup](https://firebase.google.com/docs/flutter/setup)).

## 1. Install

```sh
flutter pub add firestore_odm cloud_firestore firebase_core
flutter pub add dev:firestore_odm_builder dev:build_runner
```

`firestore_odm` exports the annotations, so you do not add
`firestore_odm_annotation` yourself.

## 2. Describe a model

Annotate the class with `@firestoreOdm` and mark the field that holds the
document ID with `@DocumentIdField()`. The ID is not stored inside the
document; it is filled in when you read.

A plain class works:

```dart
// lib/schema.dart
import 'package:firestore_odm/firestore_odm.dart';

part 'schema.g.dart';

@firestoreOdm
class User {
  const User({
    required this.id,
    required this.name,
    required this.age,
    this.tags = const [],
    this.lastLogin,
  });

  @DocumentIdField()
  final String id;
  final String name;
  final int age;
  final List<String> tags;
  final DateTime? lastLogin;
}
```

So does a freezed class with json_serializable (add `freezed`,
`freezed_annotation` and `json_serializable`). The ODM generates its own
Firestore converters, so `fromJson`/`toJson` stay free for your API or cache
format:

```dart
@freezed
@firestoreOdm
abstract class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required int age,
    @Default([]) List<String> tags,
    DateTime? lastLogin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

See [Data modeling](/guide/data-modeling) for nested models, enums, generics,
`@JsonKey` and custom converters.

## 3. Declare the schema

The schema lists every collection. A `*` segment marks a subcollection.

```dart
// lib/schema.dart (continued)
class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
@Collection<Post>('users/*/posts')
const appSchema = AppSchema();
```

Every file that declares a model or the schema needs its `part '<file>.g.dart';`
line.

## 4. Generate

```sh
dart run build_runner build --delete-conflicting-outputs
```

Use `dart run build_runner watch` while you edit models.

## 5. Read and write

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter/widgets.dart';

import 'schema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final db = FirestoreODM(appSchema);

  // Write: set replaces the document; create picks an ID and returns it.
  await db.users.set(const User(id: 'kim', name: 'Kim', age: 31));

  // Read one document (null when it does not exist).
  final kim = await db.users('kim').get();

  // Query.
  final adults = await db.users
      .where(($) => $.age(isGreaterThanOrEqualTo: 18))
      .orderBy(($) => ($.name(),))
      .get();

  // Update fields atomically.
  await db.users('kim').patch(($) => [
    $.age.increment(1),
    $.lastLogin.serverTimestamp(),
  ]);

  // Listen.
  db.users('kim').stream.listen((user) => debugPrint(user?.name));
}
```

`FirestoreODM(appSchema)` uses `FirebaseFirestore.instance`; pass
`firestore:` to use another instance or, in tests, `FakeFirebaseFirestore`
from `fake_cloud_firestore`.

## Next

- [Filtering](/guide/filtering-data), [ordering](/guide/ordering-and-limiting)
  and [pagination](/guide/pagination)
- [Writing documents](/guide/writing-documents)
- [Transactions](/guide/transactions) and [batches](/guide/batch-operations)
- [Aggregations](/guide/aggregations)
- [Subcollections](/guide/subcollections)
- Coming from cloud_firestore_odm? [Run the codemod](/guide/migrate-from-cloud-firestore-odm).
