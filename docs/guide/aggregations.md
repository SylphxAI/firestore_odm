# Aggregations

Aggregations are **one-shot** server-side queries (ADR-0002): the native
`AggregateQuery` runs on the server and returns a typed Dart record. There is
no streaming aggregate surface — a client-side re-query would silently download
every document, which is exactly what server-side aggregation exists to avoid.
Server-side aggregate streams will be added only when `cloud_firestore`
exposes them.

## Count

```dart
// Number of documents in the collection
final total = await db.users.count();

// Number of documents matching a filter
final active = await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .count();
```

## Typed aggregates

`aggregate(...)` returns a query with a typed record result:

```dart
final stats = await db.users
  .aggregate(($) => (
    count: $.count(),
    totalFollowers: $.profile.followers.sum(),
    averageAge: $.age.average(),
  ))
  .get();

print('${stats.count} users, avg ${stats.averageAge}');
```

Supported operations: `count()`, `sum()`, `average()`. Aggregates compose
with `where` and are limited to 30 aggregate fields (Firestore's limit).
