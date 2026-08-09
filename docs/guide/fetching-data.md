> **5.0 note:** this guide documents the v4 API surface. See
> [migration-guide-5](./migration-guide-5) and [getting-started](./getting-started)
> for the current 5.0 API (create/set/patch/delete, no sentinels, no modify).
>
# Fetching Data from Queries

This guide covers how to execute a query to retrieve or subscribe to a set of documents.

## Fetching a Query Once

Once you have constructed a query (by starting with a collection reference and optionally adding `where`, `orderBy`, or `limit` clauses), you execute it by calling `.get()`.

This returns a `Future` that resolves to a `List` of your model objects.

```dart
// Define a query for active users, sorted by age
final activeUsersQuery = db.users
  .where(($) => $.isActive(isEqualTo: true))
  .orderBy(($) => $.age(descending: true));

// Execute the query to get the results
// Returns Future<List<User>>
final List<User> activeUsers = await activeUsersQuery.get();

for (final user in activeUsers) {
  print('${user.name} is ${user.age} years old.');
}
```

## Subscribing to a Query (Real-time)

To create a real-time subscription to a query, use the `.stream` property instead of `.get()`.

This returns a `Stream` that emits a new `List` of your model objects every time there is a change to the documents that match the query. This is incredibly powerful for building reactive lists and UIs.

```dart
// Define a query for premium users
final premiumUsersQuery = db.users.where(($) => $.isPremium(isEqualTo: true));

// Create a stream from the query
// Returns Stream<List<User>>
final premiumUsersStream = premiumUsersQuery.stream;

// Listen to the stream
final subscription = premiumUsersStream.listen((List<User> users) {
  // This code will run initially and then every time the list of
  // premium users changes (e.g., a user is added, removed, or updated).
  print('Current number of premium users: ${users.length}');
});

// In a real app, remember to cancel the subscription when it's no longer needed.
// subscription.cancel();