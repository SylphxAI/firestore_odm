# Batch Operations

Firestore batches make up to 500 writes atomic. The v5 API exposes the native
write meanings directly: `create`, `set`, `patch`, and `delete`. A batch cannot
read, and a batch is not automatically chunked; use query `patchAll` or
`deleteAll` when you need chunking.

## Automatic commit

`runBatch` creates and commits a `BatchContext` after the synchronous callback:

```dart
await db.runBatch((batch) {
  final users = db.users.inBatch(batch);

  users.set(user1); // ID comes from @DocumentIdField
  users.set(user2, id: 'user-2');
  users.patch('user-1', (p) => [p.loginCount.increment(1)]);
  users.doc('user-3').delete();
});
```

`create` allocates a Firestore document ID immediately, so the ID can be used
for another write in the same batch:

```dart
late String userId;
await db.runBatch((batch) {
  final users = db.users.inBatch(batch);
  userId = users.create(userWithEmptyId);
  users.doc(userId).patch((p) => [p.createdAt.serverTimestamp()]);
});
```

## Manual commit

Use `batch()` when the commit should happen later:

```dart
final batch = db.batch();
final users = db.users.inBatch(batch);
users.set(user1);
db.posts.inBatch(batch).patch('post-1', (p) => [p.likes.increment(1)]);
await batch.commit();
```

Subcollections use the generated path-derived accessor:

```dart
await db.runBatch((batch) {
  db.usersPosts('user-1').inBatch(batch).set(post);
  db.usersPosts('user-1').inBatch(batch).doc('post-2').delete();
});
```

## Limits and failure behavior

- Firestore limits one batch to 500 writes; keep a manual batch within that
  limit.
- All writes in a committed batch succeed or fail together.
- Reads are not allowed in a batch; use `runTransaction` for read-then-write.
- `patch` uses the six typed operations (`set`, `delete`, `increment`,
  `arrayUnion`, `arrayRemove`, and `serverTimestamp`).

For a query-wide operation, use the chunked APIs instead:

```dart
await db.users
    .where(($) => $.isArchived(isEqualTo: true))
    .deleteAll();
```
