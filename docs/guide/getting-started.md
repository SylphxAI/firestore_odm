# 🚀 Getting Started

Get up and running with Firestore ODM in five simple steps.

## 1. Installation

Install Firestore ODM:

```bash
dart pub add firestore_odm
dart pub add dev:firestore_odm_builder
dart pub add dev:build_runner
```

You'll also need a JSON serialization solution:

```bash
# If using Freezed
dart pub add freezed_annotation
dart pub add dev:freezed
dart pub add dev:json_serializable

# If using plain classes
dart pub add json_annotation
dart pub add dev:json_serializable
```

> **Note:** `firestore_odm_annotation` is exported by `firestore_odm`, so you don't need to add it manually.

## 2. Configure json_serializable (Important for Nested Models)

If you're using models with nested objects, create a `build.yaml` file next to your `pubspec.yaml` to enable `explicit_to_json`:

```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
```

**Why is this needed?** When using nested Freezed classes or any nested objects with `json_serializable`, the generated `toJson()` method doesn't automatically call `toJson()` on nested objects. This results in nested objects being serialized as their raw Dart object representation instead of proper JSON. The `explicit_to_json: true` option forces `json_serializable` to generate proper serialization code for nested objects.

**When do you need this?**
- When using nested Freezed classes
- When using nested objects with `json_serializable`
- When you encounter serialization issues with complex object structures

## 3. Define Your Model

Create your data model. We recommend using packages like `freezed` for robust, immutable classes.

Crucially, you must tell the ODM which field holds the document's ID by annotating it with `@DocumentIdField()`. For more details, see the [Document ID Handling](/guide/document-id.html) guide.

```dart
// lib/models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    // This field is automatically populated with the document ID
    @DocumentIdField() required String id,
    required String name,
    required String email,
    required int age,
    DateTime? lastLogin,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## 4. Define Your Schema

Group your collections into a schema. This is the single source of truth for your database structure.

```dart
// lib/schema.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'models/user.dart';

part 'schema.g.dart'; // combined generated part (ODM + json_serializable)

/// The schema class is declared by hand (ADR-0002) so the schema variable's
/// type is resolvable before code generation.
class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>("users")
const appSchema = AppSchema();
```

> **Note:** The `@Schema()` annotation is crucial for the generator to correctly
> process your collections. The generated code lands in `<library>.g.dart`,
> which every annotated model file and the schema file declare as a part.

## 5. Generate Code

Run the `build_runner` to generate the required ODM code:

```bash
# Generate code
dart run build_runner build --delete-conflicting-outputs
```

## 6. Start Using

Initialize the ODM and start performing type-safe operations.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'schema.dart';

void main() async {
  final firestore = FirebaseFirestore.instance;
  final odm = FirestoreODM(appSchema, firestore: firestore);

  // Create a user with an explicit ID (full replace)
  await odm.users.set(User(id: 'jane', name: 'Jane Smith', email: 'jane@example.com'));

  // Or create with a server-generated ID (the ID is returned)
  final id = await odm.users.create(User(id: '', name: 'Jane', email: 'jane@example.com'));

  // Get a user
  final user = await odm.users('jane').get();
  print(user?.name); // Prints "Jane Smith"

  // Partial update with typed ops
  await odm.users.patch('jane', (p) => [p.age.increment(1), p.lastLogin.serverTimestamp()]);

  // Query users
  final smiths = await odm.users.where((_) => _.name(isEqualTo: 'Jane Smith')).get();
  print('Found ${smiths.length} users named Jane Smith');
}