# Schema Definition

The foundation of the ODM is the **Schema**. The schema is a central definition of your database structure, telling the ODM which collections exist and what data models they use.

## How to Define a Schema

You create a single schema file that defines all your collections. You do this by declaring the schema class by hand (so the schema variable's type is resolvable before code generation) and annotating a top-level variable of that type with `@Schema()` and one or more `@Collection<Model>(collectionPath)` annotations.

```dart
// lib/schema.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';
import 'models/post.dart';

part 'schema.g.dart'; // combined generated part (ODM + json_serializable)

/// The schema class is declared by hand (ADR-0002) so the schema variable's
/// type is resolvable before code generation.
class FirestoreDatabase extends FirestoreSchema {
  const FirestoreDatabase();
}

@Schema()
@Collection<User>("users")
@Collection<Post>("posts")
const firestoreDatabase = FirestoreDatabase(); // The variable name can be anything
```

After defining your schema and models, run the build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates the necessary code to create a type-safe API for your database.

## Using the ODM Instance

You then create an instance of your ODM, which gives you access to your collections.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart'; // Your schema file

final firestore = FirebaseFirestore.instance;

// Create the ODM instance
final db = FirestoreODM(firestoreDatabase, firestore: firestore);

// Now you can access your collections with type-safety
final usersCollection = db.users;
final postsCollection = db.posts;
