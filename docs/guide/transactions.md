# Transactions

A transaction reads documents and then writes based on what it read. Firestore
commits all the writes together, and retries the whole function if another
client changes a document it read.

## Usage

Get a typed handle for each collection with `inTransaction`. Reads return a
`Future`; writes return nothing and are queued.

```dart
await odm.runTransaction((tx) async {
  final accounts = odm.accounts.inTransaction(tx);

  final from = await accounts('alice').get();
  final to = await accounts('bob').get();
  if (from == null || to == null) {
    throw StateError('Account not found');
  }
  if (from.balance < 100) {
    throw StateError('Insufficient funds');
  }

  accounts('alice').patch(($) => [$.balance.increment(-100)]);
  accounts('bob').patch(($) => [$.balance.increment(100)]);
});
```

This example uses an `Account` model with an `int balance` field, declared as
`@Collection<Account>('accounts')` in the schema:

```dart
// lib/models/account.dart
import 'package:firestore_odm/firestore_odm.dart';

part 'account.g.dart';

@firestoreOdm
class Account {
  const Account({required this.id, required this.balance});

  @DocumentIdField()
  final String id;
  final int balance;
}
```

## How writes are ordered

Firestore requires every read in a transaction to happen before any write. The
ODM handles this for you: writes are queued while your function runs and are
sent after it returns. You can therefore mix reads and writes in any order in
your code.

Because writes are queued, reading a document after writing it in the same
transaction returns the value from before the write.

A document read twice in one attempt is fetched once.

## Available operations

| Collection handle | Document handle (`call(id)` or `doc(id)`) |
|---|---|
| `create(model)` returns the new ID | `get()` |
| `set(model, {id})` | `set(model)` |
| `patch(id, ops)` | `patch(ops)` |
| `delete(id)` | `delete()` |

Transactions read single documents only; queries are not available inside a
transaction.

## Errors and retries

- If your function throws, the transaction is cancelled, nothing is written,
  and `runTransaction` throws the same error.
- Firestore may run your function more than once. Keep side effects, such as
  showing a message, outside the function.
- Transactions need a network connection.
