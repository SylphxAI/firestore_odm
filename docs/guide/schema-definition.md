# Schema Definition

The schema is the source of truth for generated collection accessors. Declare
the schema type by hand so it is resolvable before code generation:

```dart
import 'package:firestore_odm/firestore_odm.dart';

part 'schema.g.dart';

class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
@Collection<Post>('posts')
const appSchema = AppSchema();
```

Run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The generated `<library>.g.dart` extension exposes typed collection getters
and callable document handles:

```dart
final db = FirestoreODM(appSchema, firestore: FirebaseFirestore.instance);
final users = db.users;
final user = db.users('user-1');
```

Multiple schema instances are supported. Each `FirestoreODM` instance owns its
schema and Firestore client; no global singleton or generated service registry
is required.
