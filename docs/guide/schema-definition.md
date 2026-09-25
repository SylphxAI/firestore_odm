# Schema Definition

A schema lists your collections and the model stored in each one. The code
generator reads it and adds a typed accessor for every collection to
`FirestoreODM`.

## Define a schema

A schema file has three parts:

1. A schema class that extends `FirestoreSchema`. You write this class
   yourself.
2. A top-level constant of that class, annotated with `@Schema()` and one
   `@Collection<Model>('path')` per collection.
3. A `part` directive for the generated file.

```dart
// lib/schema.dart
import 'package:firestore_odm/firestore_odm.dart';

import 'models/post.dart';
import 'models/user.dart';

part 'schema.g.dart';

class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
@Collection<Post>('posts')
@Collection<Post>('users/*/posts') // subcollection: one per user
const appSchema = AppSchema();
```

Every model used in a `@Collection` must carry `@firestoreOdm` (see
[Data Modeling](/guide/data-modeling)). A `*` in a path stands for a parent
document ID (see [Subcollections](/guide/subcollections)).

Then generate the code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Create the ODM

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';

import 'schema.dart';

final odm = FirestoreODM(appSchema, firestore: FirebaseFirestore.instance);

final users = odm.users;            // root collection: a getter
final posts = odm.posts;
final alicePosts = odm.usersPosts('alice'); // subcollection: a method
```

`firestore` is optional and defaults to `FirebaseFirestore.instance`. Pass
another instance to use a second database or an emulator (see
[Multiple ODM Instances](/guide/multiple-instances)).

## Accessor names

Accessor names come from the collection path. Wildcard segments are dropped
and the remaining segments are joined in camelCase:

| Path | Accessor |
|---|---|
| `users` | `odm.users` |
| `audit_logs` | `odm.auditLogs` |
| `users/*/posts` | `odm.usersPosts(userId)` |
| `users/*/posts/*/comments` | `odm.usersPostsComments(userId, postId)` |

The same model can appear in any number of collections; its generated code is
shared.
