# Batch Operations

A batch groups writes so they commit together: either all of them succeed or
none do. A batch cannot read. To read before writing, use a
[transaction](/guide/transactions).

## runBatch

`runBatch` gives you a batch context, runs your function, then commits. Get a
typed handle for each collection with `inBatch`:

```dart
await odm.runBatch((batch) {
  final users = odm.users.inBatch(batch);

  final newId = users.create(newUser); // returns the generated ID now
  users.set(jane);                     // ID from jane.id
  users.set(bob, id: 'bob');           // explicit ID
  users.patch('carol', ($) => [$.age.increment(1)]);
  users.delete('dave');

  // Document handles use doc(id)
  users.doc('erin').patch(($) => [$.isActive.set(false)]);

  // Subcollections work the same way
  odm.usersPosts('jane').inBatch(batch).set(post);
});
```

The function passed to `runBatch` is synchronous: queue the writes, do not
`await` inside it.

## Manual commit

`odm.batch()` returns a batch context that you commit yourself:

```dart
final batch = odm.batch();

odm.users.inBatch(batch).set(jane);
odm.posts.inBatch(batch).patch('p1', ($) => [$.likes.increment(1)]);

await batch.commit();
```

Nothing is written until `commit()` completes.

## Available writes

| Collection handle | Document handle (`doc(id)`) |
|---|---|
| `create(model)` returns the new ID | |
| `set(model, {id})` | `set(model)` |
| `patch(id, ops)` | `patch(ops)` |
| `delete(id)` | `delete()` |

## Limits

- Firestore allows at most 500 writes in one batch. The ODM does not split a
  batch for you; for larger jobs use
  [Bulk Operations](/guide/bulk-operations) or several batches.
- If the commit fails, no write in the batch is applied:

```dart
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseException;

try {
  await odm.runBatch((batch) {
    final users = odm.users.inBatch(batch);
    users.set(jane);
    users.patch('missing', ($) => [$.age.increment(1)]); // fails: not found
  });
} on FirebaseException catch (e) {
  print('Nothing was written: ${e.code}');
}
```

## Batch or transaction?

| | Batch | Transaction |
|---|---|---|
| Reads | No | Yes |
| Atomic | Yes | Yes |
| Works offline | Yes, queued until online | No |
| Use for | Writing known values | Writes that depend on current data |
