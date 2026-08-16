# Filtering Data

The `.where()` method is the foundation of all queries. It takes a builder function that gives you access to all fields on your model, ensuring type-safety at compile time.

## Basic Comparisons

You can use standard comparison operators like `isEqualTo`, `isNotEqualTo`, `isGreaterThan`, `isLessThan`, etc.

```dart
// Find users who are exactly 30 years old
final users = await db.users.where(($) => $.age(isEqualTo: 30)).get();

// Find users with more than 1000 followers
final popularUsers = await db.users
  .where(($) => $.profile.followers(isGreaterThan: 1000))
  .get();
```

## Array Operations

-   **`arrayContains`**: Find documents where an array field contains a specific value.
-   **`arrayContainsAny`**: Find documents where an array field contains any of the specified values.
-   **`whereIn`**: Find documents where a field's value is in a list of possible values.
-   **`whereNotIn`**: Find documents where a field's value is not in a list of possible values.

```dart
// Find users interested in 'flutter'
final flutterDevs = await db.users
  .where(($) => $.tags(arrayContains: 'flutter'))
  .get();

// Find users who are either premium or verified
final specialUsers = await db.users
  .where(($) => $.status(whereIn: ['premium', 'verified']))
  .get();
```

## Complex Logical Queries

You can combine multiple conditions using `and()` and `or()`. The `and` and `or` methods can be nested to create highly specific queries.

```dart
final engagedUsers = await db.users.where(($) => $.and(
  // Condition 1: User must be active
  $.isActive(isEqualTo: true),
  // Condition 2: User must be premium OR have more than 1000 followers
  $.or(
    $.isPremium(isEqualTo: true),
    $.profile.followers(isGreaterThan: 1000),
  ),
)).get();
```

## Map fields

Generated selectors cover declared model fields and nested model fields. A
dynamic key inside a `Map` has no compile-time type contract, so query it through
the underlying `cloud_firestore` reference when necessary; do not invent a
second generated map DSL. Prefer a nested model when the keys are part of the
application contract.
