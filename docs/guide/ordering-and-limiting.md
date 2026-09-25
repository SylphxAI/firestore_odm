# Ordering & Limiting

## orderBy

`orderBy` takes a function that returns a Dart
[record](https://dart.dev/language/records) of field selectors. Each selector
sorts ascending unless you pass `descending: true`.

```dart
// Most followers first, then by name A-Z
final sorted = await odm.users
    .orderBy(($) => (
          $.profile.followers(descending: true),
          $.name(),
        ))
    .get();
```

A record with one field needs a trailing comma:

```dart
final byAge = await odm.users.orderBy(($) => ($.age(),)).get();
```

The record's type is the query's cursor type; see
[Pagination](/guide/pagination). You can add `$.documentId()` as a last term to
break ties between documents with equal values.

Firestore rules still apply. For example, a query with a range filter
(`isLessThan`, `isGreaterThan`, and so on) on a field must order by that field
first, and some combinations need a composite index.

```dart
final adults = await odm.users
    .where(($) => $.age(isGreaterThanOrEqualTo: 18))
    .orderBy(($) => ($.age(), $.name()))
    .get();
```

## limit and limitToLast

- `limit(n)` returns the first `n` results.
- `limitToLast(n)` returns the last `n` results, still in `orderBy` order.
  It requires `orderBy`.

```dart
final top10 = await odm.users
    .orderBy(($) => ($.profile.followers(descending: true),))
    .limit(10)
    .get();

final newest3 = await odm.users
    .orderBy(($) => ($.createdAt(),))
    .limitToLast(3)
    .get();
```
