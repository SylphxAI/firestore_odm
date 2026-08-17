# Getting Started

This is the supported v5 path: declare one model, generate its typed surface,
then use one `FirestoreODM` instance for writes, queries, patches, and
read-modify-write transactions.

## 1. Install the consumer dependencies

Run these commands from the consumer application's directory:

```bash
dart pub add cloud_firestore
dart pub add firestore_odm
dart pub add dev:firestore_odm_builder
dart pub add dev:build_runner
dart pub add freezed_annotation
dart pub add dev:freezed
dart pub add dev:json_serializable
```

`firestore_odm` re-exports the annotation package, so a separate
`firestore_odm_annotation` dependency is not required. Initialize Firebase
through the normal Flutter/Firebase setup before constructing the ODM.

## 2. Declare the model

The `@firestoreOdm` annotation opts the model into converter, filter, order,
aggregate, and patch generation. `@DocumentIdField` is metadata: the ID is
filled from a snapshot and is not stored in the document map.

```dart
// lib/models/user.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
@firestoreOdm
abstract class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    @Default(<String>[]) List<String> tags,
    DateTime? lastLogin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

For nested models, add `explicit_to_json: true` to `build.yaml` so
`json_serializable` calls each nested `toJson()` factory. See
[Data Modeling](/guide/data-modeling.html) for plain Dart and converter-based
models.

## 3. Declare the schema

The schema class is hand-written so its type is resolvable before generation;
the generated part adds typed collection accessors.

```dart
// lib/schema.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

part 'schema.g.dart';

class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
const appSchema = AppSchema();
```

## 4. Generate and check the consumer

```bash
dart run build_runner build --delete-conflicting-outputs
dart analyze
flutter test
```

Run the same three commands after a fresh checkout or dependency update. Do
not copy generated parts from another checkout; generation is part of the
consumer's reproducible build.

## 5. Follow one typed journey

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart';

Future<void> main() async {
  final db = FirestoreODM(
    appSchema,
    firestore: FirebaseFirestore.instance,
  );

  // A generated ID is returned by create(). The model ID is not stored.
  final id = await db.users.create(
    const User(
      id: '',
      name: 'Jane Smith',
      email: 'jane@example.com',
      age: 28,
      tags: ['new'],
    ),
  );

  // Missing documents are represented by null.
  final created = await db.users(id).get();
  if (created == null) throw StateError('created user was not readable');

  // Filters and ordering use generated selectors. A range filter is ordered
  // first on the same field, followed by a document-ID tie breaker.
  final adults = await db.users
      .where(($) => $.age(isGreaterThanOrEqualTo: 18))
      .orderBy(($) => ($.age(), $.documentId()))
      .get();

  // A patch is partial and explicit; it does not perform a read-modify-write.
  await db.users(id).patch(
    (p) => [
      p.tags.arrayUnion(['verified']),
      p.lastLogin.serverTimestamp(),
    ],
  );

  // Put read-modify-write in a transaction. Reads are awaited; writes are
  // deferred until the callback finishes.
  await db.runTransaction((tx) async {
    final users = db.users.inTransaction(tx);
    final current = await users(id).get();
    if (current == null) throw StateError('user disappeared');
    users(id).patch((p) => [p.age.increment(1)]);
  });
}
```

## 6. Recover without hiding the cause

Validation failures are local input errors and expose a stable code. Firestore
access failures remain native `FirebaseException`s with their original code:

```dart
try {
  await db.users.set(user, id: requestedId);
} on FirestoreODMValidationException catch (error) {
  if (error.code == 'invalid_document_id') {
    // Correct the ID; retrying the same value cannot succeed.
    return;
  }
  rethrow;
} on FirebaseException catch (error) {
  switch (error.code) {
    case 'permission-denied':
      // Re-authenticate or request access; do not retry blindly.
      rethrow;
    case 'unavailable':
    case 'deadline-exceeded':
      // Retry the whole idempotent operation with bounded backoff if desired.
      rethrow;
    default:
      rethrow;
  }
}
```

Firestore may retry a transaction callback. Keep external side effects out of
that callback and queue only ODM reads and writes. The fake Firestore test
double is useful for serialization and query coverage, but native
`FieldPath` patch/transaction behavior should be checked with the Firestore
emulator.

For an existing v4 codebase, use the [v5 migration guide](/guide/migration-guide-5.html)
instead of mixing removed write verbs with this journey.
