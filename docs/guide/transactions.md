> **5.0 note:** this guide documents the v4 API surface. See
> [migration-guide-5](./migration-guide-5) and [getting-started](./getting-started)
> for the current 5.0 API (create/set/patch/delete, no sentinels, no modify).
>
# Transactions

Transactions are essential for operations that need to read and write data atomically across multiple documents. A classic example is transferring funds between two accounts: you need to ensure that the debit from one account and the credit to another either both succeed or both fail, maintaining data consistency.

## How It Works

You provide an asynchronous function to `.runTransaction()`. This function receives a transaction object (`tx`) as its first argument. Inside this function, you should perform all your reads and writes using the `tx` object instead of the global `odm` instance.

### Read-Before-Write

A fundamental rule of Firestore transactions is that all document reads must be performed before any writes. Our ODM simplifies this for you.

### Deferred Writes

The transaction object (`tx`) intelligently handles this rule by using **deferred writes**. When you call a write method like `.patch()`, `.modify()`, or `.delete()` on `tx`, the operation is not sent to the server immediately. Instead, it's queued locally. All queued writes are then sent to Firestore at the very end of the transaction function, after all your `await` calls (including reads) have completed. This ensures the "read-before-write" rule is always followed automatically.

### Supported Operations

All write operations are supported within a transaction:
- `patch()`
- `modify()`
- `delete()`

```dart
Future<void> transferFunds(String fromUserId, String toUserId, int amount) async {
  await db.runTransaction((tx) async {
    // 1. Perform all reads first.
    // Note: We use the `tx` object to get the documents.
    final senderDoc = await tx.users(fromUserId).get();
    final receiverDoc = await tx.users(toUserId).get();

    if (senderDoc == null || receiverDoc == null) {
      throw Exception('One or both users not found.');
    }
    if (senderDoc.balance < amount) {
      throw Exception('Insufficient funds.');
    }

    // 2. Perform all writes. These are deferred and sent at the end.
    // Using modify for safe, atomic updates.
    await tx.users(fromUserId).modify((user) => user.copyWith(
      balance: user.balance - amount, // Becomes atomic decrement
    ));

    await tx.users(toUserId).modify((user) => user.copyWith(
      balance: user.balance + amount, // Becomes atomic increment
    ));
  });
}
```

If any part of the transaction function throws an exception, the entire transaction will be rolled back, and no changes will be saved to the database, ensuring your data remains consistent.