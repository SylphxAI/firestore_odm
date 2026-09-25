# Filtering Data

`where` takes a function. Its argument, `$`, has one selector per model field.
Call a selector with exactly one condition:

```dart
final thirty = await odm.users.where(($) => $.age(isEqualTo: 30)).get();
```

A selector called with no condition, or with more than one, throws an
`ArgumentError`.

## Conditions

| Condition | Matches documents where the field |
|---|---|
| `isEqualTo: v` | equals `v` |
| `isNotEqualTo: v` | does not equal `v` |
| `isLessThan: v` | is less than `v` |
| `isLessThanOrEqualTo: v` | is less than or equal to `v` |
| `isGreaterThan: v` | is greater than `v` |
| `isGreaterThanOrEqualTo: v` | is greater than or equal to `v` |
| `whereIn: [a, b]` | equals one of the values |
| `whereNotIn: [a, b]` | equals none of the values |
| `arrayContains: v` | is an array that contains `v` |
| `arrayContainsAny: [a, b]` | is an array that contains any of the values |
| `isNull: true` / `false` | is (or is not) `null` |

Values are type-checked against the field. A `DateTime` value is compared as a
`Timestamp`, and an enum value as its stored value.

```dart
final flutterDevs = await odm.users
    .where(($) => $.tags(arrayContains: 'flutter'))
    .get();

final someAges = await odm.users
    .where(($) => $.age(whereIn: [18, 21, 30]))
    .get();

final neverLoggedIn = await odm.users
    .where(($) => $.lastLogin(isNull: true))
    .get();
```

## Nested fields

Selectors follow nested models:

```dart
final popular = await odm.users
    .where(($) => $.profile.followers(isGreaterThan: 1000))
    .get();
```

## Document ID

`$.documentId` filters on the document ID:

```dart
final pair = await odm.users
    .where(($) => $.documentId(whereIn: ['alice', 'bob']))
    .get();
```

## Combining conditions

Combine conditions with `&` (and) and `|` (or), or with the equivalent
`.and()` and `.or()` methods. Use parentheses to group:

```dart
final engaged = await odm.users
    .where(
      ($) =>
          $.isActive(isEqualTo: true) &
          ($.isPremium(isEqualTo: true) |
              $.profile.followers(isGreaterThan: 1000)),
    )
    .get();

// The same with methods
final engaged2 = await odm.users
    .where(
      ($) => $.isActive(isEqualTo: true).and(
        $.isPremium(isEqualTo: true).or(
          $.profile.followers(isGreaterThan: 1000),
        ),
      ),
    )
    .get();
```

Calling `where` more than once also combines the conditions with "and":

```dart
final q = odm.users
    .where(($) => $.isActive(isEqualTo: true))
    .where(($) => $.age(isGreaterThan: 18));
```

Firestore's own query limits apply, such as the number of `whereIn` values and
the rules for combining range filters. Some queries need a composite index;
Firestore's error message links to the console page that creates it.
