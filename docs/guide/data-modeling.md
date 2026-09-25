# Data Modeling

A model is a Dart class that describes one document. The code generator reads
the model's unnamed constructor and generates, in the model's `.g.dart` file:

- the converters that write the model to Firestore and read it back
- the typed selectors used by `where`, `orderBy`, `aggregate` and `patch`

## Rules for a model

- Annotate the class with `@firestoreOdm`. Nested model classes need it too.
- Add `part '<file>.g.dart';` to the model's file.
- Give the class an unnamed constructor. Every constructor parameter becomes a
  document field.
- Hold the document ID in a `String` field marked `@DocumentIdField()`, or in a
  `String` field named `id` (see [Document ID](/guide/document-id)).

You can use freezed or a plain class. `json_serializable` is not required: the
ODM generates its own converters. If your model also has `toJson`/`fromJson`
for other uses, keep them.

## freezed

```dart
// lib/models/user.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'profile.dart';

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
    required Profile profile,
    @Default([]) List<String> tags,
    @Default(false) bool isActive,
    @Default(false) bool isPremium,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;
}
```

```dart
// lib/models/profile.dart
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
@firestoreOdm
abstract class Profile with _$Profile {
  const factory Profile({
    required String bio,
    @Default(0) int followers,
  }) = _Profile;
}
```

The other guides use this `User` and `Profile`.

## Plain class

```dart
// lib/models/task.dart
import 'package:firestore_odm/firestore_odm.dart';

part 'task.g.dart';

@firestoreOdm
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.estimate,
    this.isDone = false,
  });

  @DocumentIdField()
  final String id;
  final String title;
  final Duration estimate;
  final bool isDone;
}
```

## Field types

| Dart type | Stored in Firestore as |
|---|---|
| `String`, `int`, `double`, `num`, `bool` | the same value |
| `DateTime` | a `Timestamp` |
| `Duration` | an integer number of microseconds |
| enum | the constant's name, or its `@JsonValue` |
| `List<T>`, `Set<T>` | an array |
| `Map<String, T>` | a map |
| a nested `@firestoreOdm` class | a map |
| `GeoPoint`, `DocumentReference`, `Blob`, `Timestamp` | the same value |

A nullable field (`T?`) is stored as `null` when it has no value.

When reading, a field missing from the document takes the parameter's
default (a Dart default value or freezed's `@Default`), so you can add fields
with defaults without migrating existing documents. A missing non-nullable
field without a default throws. A `double` field also accepts a whole number
stored as an integer.

Reading a `DateTime` returns the same instant in local time, which matches
`Timestamp.toDate()` in `cloud_firestore`.

## Field names and converters

The generator reads these `json_annotation` annotations on constructor
parameters:

- `@JsonKey(name: 'email_address')` stores the field under a different name.
  Queries and patches use the stored name automatically.
- `@JsonKey(includeFromJson: false, includeToJson: false)` leaves a field out of
  the document. The field must be nullable or have a default.
- `@JsonConverter` on a field converts it with your converter.
- `@JsonValue` on enum constants sets the stored value.

```dart
import 'package:firestore_odm/firestore_odm.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

enum Plan {
  @JsonValue('free')
  free,
  @JsonValue('pro')
  pro,
}

@freezed
@firestoreOdm
abstract class Account with _$Account {
  const factory Account({
    @DocumentIdField() required String id,
    @JsonKey(name: 'email_address') required String email,
    @Default(Plan.free) Plan plan,
    @JsonKey(includeFromJson: false, includeToJson: false) String? draftNote,
  }) = _Account;
}
```

`freezed_annotation` exports `json_annotation`. With a plain class, import
`package:json_annotation/json_annotation.dart` to use these annotations.
