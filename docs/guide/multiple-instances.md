# Multiple ODM Instances

One `FirestoreODM` instance serves one schema on one Firestore database. You
can create as many as you need, for example:

- one per Firestore database (the default database and a named one)
- one pointing at the emulator or a test double in tests
- separate schemas for separate parts of an app

## Several schemas

Each schema lives in its own file with its own `part`:

```dart
// lib/schemas/admin_schema.dart
import 'package:firestore_odm/firestore_odm.dart';

import '../models/audit_log.dart';
import '../models/user.dart';

part 'admin_schema.g.dart';

class AdminSchema extends FirestoreSchema {
  const AdminSchema();
}

@Schema()
@Collection<User>('users')
@Collection<AuditLog>('audit_logs')
const adminSchema = AdminSchema();
```

```dart
// lib/schemas/app_schema.dart
import 'package:firestore_odm/firestore_odm.dart';

import '../models/post.dart';
import '../models/user.dart';

part 'app_schema.g.dart';

class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
@Collection<Post>('posts')
const appSchema = AppSchema();
```

Each ODM only has the collections of its schema:

```dart
final adminDb = FirestoreODM(adminSchema);
final appDb = FirestoreODM(appSchema);

final logs = adminDb.auditLogs; // OK
final posts = appDb.posts;      // OK
// appDb.auditLogs              // compile error: not in AppSchema
```

A model can appear in several schemas.

## Several databases

Pass the `FirebaseFirestore` instance to use:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

final mainDb = FirestoreODM(appSchema);
final analyticsDb = FirestoreODM(
  appSchema,
  firestore: FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'analytics',
  ),
);
```

## Tests

Pass a test double such as `FakeFirebaseFirestore` from
`fake_cloud_firestore`:

```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

final odm = FirestoreODM(appSchema, firestore: FakeFirebaseFirestore());
```

`odm.firestore` returns the underlying `FirebaseFirestore` instance.
