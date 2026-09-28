# Field validators

`@Min` and `@Max` constrain a numeric field to a range. They are the
annotations `cloud_firestore_odm` had, with the same meaning.

```dart
import 'package:firestore_odm/firestore_odm.dart';

@firestoreOdm
class Movie {
  const Movie({required this.id, required this.likes, required this.rating});

  @DocumentIdField()
  final String id;

  @Min(0)
  final int likes;

  @Min(0)
  @Max(100)
  final double rating;
}
```

Put them on the field of a plain class, or on the constructor parameter of a
freezed class:

```dart
@freezed
@firestoreOdm
abstract class Rating with _$Rating {
  const factory Rating({
    @DocumentIdField() required String id,
    @Min(0) @Max(10) required int points,
  }) = _Rating;

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);
}
```

## When they are checked

Before anything is written. The generated converters check every bound and
throw a `FirestoreODMValidationException`, so Firestore never sees the value:

```dart
try {
  await odm.movies.set(Movie(id: 'm1', likes: -1, rating: 50));
} on FirestoreODMValidationException catch (e) {
  print(e.message); // likes must be at least 0, got -1
  print(e.field);   // likes
  print(e.code);    // out_of_range
}
```

All three write paths are covered:

| write | checked |
| --- | --- |
| `set(model)`, `create(model)` | every bounded field, including nested models |
| `patch(($) => [$.likes.set(-1)])` | the value being set, at any nesting depth |
| `patch(($) => [$.likes.increment(1)])` | no — `increment` is a relative change the server applies; nothing is written that needs checking |

A `null` value (an unset optional field) and a non-numeric value pass, as in
`cloud_firestore_odm`.

## Rules

- `@Min`/`@Max` apply to `int`, `double` and `num` fields. On any other type
  the build fails with a clear error instead of generating code that cannot
  work.
- Both annotations can be combined, and each can be used alone.
- The bound is checked in the generated converter, so it covers every write
  path in your code, and values already in Firestore are not re-validated when
  they are read.
- `@Min`/`@Max` are the range checks; anything else (a non-empty string, a
  pattern) belongs in the model's constructor or in the code that builds it.
