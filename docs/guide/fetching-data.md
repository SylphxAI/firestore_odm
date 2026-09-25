# Fetching Data

A collection, or a query built from it with `where`, `orderBy` and `limit`,
returns a list of models.

## Read once

```dart
// Every document in the collection
final all = await odm.users.get();

// A query
final active = await odm.users
    .where(($) => $.isActive(isEqualTo: true))
    .orderBy(($) => ($.age(descending: true),))
    .get();

for (final user in active) {
  print('${user.name} is ${user.age}');
}
```

`get` accepts `GetOptions` to read from the cache or the server only:

```dart
final cached = await odm.users.get(const GetOptions(source: Source.cache));
```

## Listen for changes

`stream` emits the full result list now and after every change to a matching
document.

```dart
final subscription = odm.users
    .where(($) => $.isPremium(isEqualTo: true))
    .stream
    .listen((users) {
  print('Premium users: ${users.length}');
});

// Later
await subscription.cancel();
```

Each read of `stream` starts a new listener. In a Flutter widget, create the
stream once (for example in `initState`) and pass it to a `StreamBuilder`.

## Counting

To count documents without downloading them, use `count()`; see
[Aggregations](/guide/aggregations).

```dart
final n = await odm.users.where(($) => $.isActive(isEqualTo: true)).count();
```

## Using a query more than once

Queries are immutable values. Store one and call `get`, `stream`, or further
builder methods on it as often as you like:

```dart
final adults = odm.users.where(($) => $.age(isGreaterThanOrEqualTo: 18));

final firstTen = await adults.limit(10).get();
final total = await adults.count();
```
