# Data Modeling

The ODM is designed to be unopinionated about how you create your data models. It supports a variety of popular modeling styles and packages, allowing you to choose the approach that best fits your project.

## Important: Nested Object Serialization

When working with nested objects (especially with Freezed classes), you **must** configure `json_serializable` to properly handle nested serialization. Create a `build.yaml` file next to your `pubspec.yaml`:

```yaml
# build.yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true
```

**Why is this required?** Without `explicit_to_json: true`, `json_serializable` generates `toJson()` methods that don't properly serialize nested objects. Instead of calling `toJson()` on nested objects, it serializes them as raw Dart objects, which causes issues when storing data in Firestore.

**Example of the problem:**
```dart
// Without explicit_to_json: true, this generates broken JSON:
@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required Profile profile, // This won't serialize properly!
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String bio,
    required int followers,
  }) = _Profile;
  
  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);
}
```

**Alternative Solutions:**
If you can't use a global `build.yaml` configuration, you can add the annotation directly to specific classes:

```dart
@freezed
class User with _$User {
  const User._();
  
  @JsonSerializable(explicitToJson: true) // Add this annotation
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required Profile profile,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Using `freezed` (Recommended)

We recommend using the [freezed](https://pub.dev/packages/freezed) package to create your models. It generates robust, immutable classes with `copyWith`, `==`, and `toString()` methods, reducing boilerplate and preventing common errors.

```dart
// lib/models/user.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required String email,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Using Plain Dart Classes with `json_serializable`

If you prefer full control, you can use plain Dart classes and rely on the [json_serializable](https://pub.dev/packages/json_serializable) package for serialization.

```dart
// lib/models/task.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';

@JsonSerializable()
class Task {
  @DocumentIdField()
  final String id;
  final String description;
  final bool isCompleted;

  Task({required this.id, required this.description, this.isCompleted = false});

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
```

## Collection fields

Firestore stores arrays and maps as its native collection types. Model them as
plain Dart `List`, `Map`, or `Set` fields; the ODM serializes them according to
the v5 storage contract. There is no `fast_immutable_collections` dependency
or compatibility adapter in v5.

```dart
@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required List<String> tags,
    required Map<String, String> settings,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

## Customizing Field Names with `@JsonKey`

The ODM fully respects `@JsonKey` annotations from the `json_annotation` package. This allows you to use different field names in your Dart models than what is stored in Firestore. This is particularly useful when working with existing databases that have different naming conventions (e.g., `snake_case`).

You can also use `@JsonKey` to ignore fields during serialization.

```dart
// lib/models/json_key_user.dart
import 'package:firestore_odm_annotation/firestore_odm_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'json_key_user.g.dart';

@JsonSerializable()
class JsonKeyUser {
  @DocumentIdField()
  final String id;

  // 'email' in Dart, but 'email_address' in Firestore
  @JsonKey(name: 'email_address')
  final String email;

  // 'isPremium' in Dart, but 'is_premium_member' in Firestore
  @JsonKey(name: 'is_premium_member')
  final bool isPremium;

  // This field will not be saved to or read from Firestore
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? secretField;

  JsonKeyUser({
    required this.id,
    required this.email,
    required this.isPremium,
    this.secretField,
  });

  factory JsonKeyUser.fromJson(Map<String, dynamic> json) => _$JsonKeyUserFromJson(json);
  Map<String, dynamic> toJson() => _$JsonKeyUserToJson(this);
}
```

## Troubleshooting Nested Object Serialization

### Common Error: "Instance of 'NestedClass'" in Firestore

If you see raw Dart object representations like `Instance of 'Profile'` stored in Firestore instead of proper JSON objects, this indicates that nested objects aren't being serialized correctly.

**Symptoms:**
- Nested objects appear as `Instance of 'ClassName'` in Firestore console
- Deserialization fails when reading documents with nested objects
- Type errors when trying to access nested object properties

**Solution:**
Add the `build.yaml` configuration as described above, or use the `@JsonSerializable(explicitToJson: true)` annotation on affected classes.

### Alternative Per-Class Configuration

If you prefer not to use a global `build.yaml` configuration, you can enable explicit JSON serialization on individual classes:

```dart
@freezed
class User with _$User {
  const User._(); // Required for the annotation below
  
  @JsonSerializable(explicitToJson: true)
  const factory User({
    @DocumentIdField() required String id,
    required String name,
    required Profile profile, // Now properly serialized
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### Working with Lists of Nested Objects

When using lists of nested objects, the `explicit_to_json: true` configuration is especially important:

```dart
@freezed
class Team with _$Team {
  const factory Team({
    @DocumentIdField() required String id,
    required String name,
    required List<Member> members, // Requires explicit_to_json
  }) = _Team;
  
  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
}

@freezed
class Member with _$Member {
  const factory Member({
    required String name,
    required String role,
  }) = _Member;
  
  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}
```

Without proper configuration, the `members` list would be serialized incorrectly, causing data corruption in Firestore.
