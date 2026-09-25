# Server Timestamps

To store the server's time in a `DateTime` field, use the `serverTimestamp()`
patch operation. Firestore fills in the time when it applies the write, so the
value does not depend on the device clock.

```dart
await odm.users('jane').patch(($) => [$.updatedAt.serverTimestamp()]);
```

It works the same way in bulk writes, batches and transactions:

```dart
await odm.runBatch((batch) {
  odm.users.inBatch(batch).patch('jane', ($) => [$.updatedAt.serverTimestamp()]);
});

await odm.runTransaction((tx) async {
  odm.users.inTransaction(tx)('jane').patch(
    ($) => [$.updatedAt.serverTimestamp()],
  );
});
```

## Setting a server time when creating a document

`create` and `set` write the model's own values. To add a server time to a new
document atomically, queue the write and a patch in one batch:

```dart
await odm.runBatch((batch) {
  final users = odm.users.inBatch(batch);
  final id = users.create(newUser);
  users.patch(id, ($) => [$.createdAt.serverTimestamp()]);
});
```

## Use a nullable field

Declare server-set fields as `DateTime?`. Until the server confirms the write,
a listener on the same device sees the field as `null`.

## Reading

Firestore stores the value as a `Timestamp`. The ODM returns it as a
`DateTime` for the same instant, in local time.
