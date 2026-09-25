# Transactions

Transactions provide atomic read-modify-write across documents. The ODM
deferred-write design guarantees Firestore's read-before-write rule: all
reads execute as they are awaited inside the callback; all writes are queued
and flushed after the callback completes. Reads are cached per attempt.

## Usage

```dart
await db.runTransaction((tx) async {
  final txUsers = db.users.inTransaction(tx);

  // 1. Reads (any order, cached).
  final sender = await txUsers('alice').get();
  final receiver = await txUsers('bob').get();
  if (sender == null || receiver == null) {
    throw Exception('Missing account');
  }

  // 2. Writes — deferred and flushed at the end (explicit ops).
  txUsers('alice').patch((p) => [p.balance.increment(-100)]);
  txUsers('bob').patch((p) => [p.balance.increment(100)]);
  txUsers('receipt').set(sampleReceipt());
});
```

Supported operations: `get`, `create` (returns the generated ID), `set`,
`patch`, `delete`. Throwing inside the callback aborts the transaction.
(`sampleReceipt` is illustrative; any model works.)
