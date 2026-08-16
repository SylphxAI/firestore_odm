# Fetching Data from Queries

Build a typed query and call `get()` for a one-shot result:

```dart
final activeUsers = await db.users
    .where(($) => $.isActive(isEqualTo: true))
    .orderBy(($) => $.age(descending: true))
    .get();
```

Use `stream` when the product needs live document-list updates:

```dart
final subscription = db.users
    .where(($) => $.isPremium(isEqualTo: true))
    .stream
    .listen((users) => print('premium users: ${users.length}'));

// Cancel it when the owning UI or job is disposed.
await subscription.cancel();
```

`count()` and `aggregate(...)` are one-shot server-side operations. They do not
have a fake client-side streaming surface; see [Aggregations](./aggregations).
