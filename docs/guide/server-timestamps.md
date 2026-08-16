# Server Timestamps

Server-set times are an explicit patch operation (ADR-0002 — no sentinel
constants):

```dart
await db.users('jane').patch((p) => [p.updatedAt.serverTimestamp()]);
```

Works the same inside transactions and batches:

```dart
await db.runTransaction((tx) async {
  db.users.inTransaction(tx)('jane').patch((p) => [p.updatedAt.serverTimestamp()]);
});

await db.runBatch((batch) {
  db.users.inBatch(batch).patch('jane', (p) => [p.updatedAt.serverTimestamp()]);
});
```

## Reading timestamps back

Firestore stores server timestamps as `Timestamp`. The ODM converts them to
`DateTime` on read (the same instant; Timestamps are timezone-less, so the
returned `DateTime` is in local time — identical to the raw SDK's
`Timestamp.toDate()`).

## Insert-time server timestamps

There is no sentinel for `create`/`set`; if you need a server-set field at
insert time, create the document first and patch it:

```dart
final id = await db.users.create(user);
await db.users(id).patch((p) => [p.createdAt.serverTimestamp()]);
```
