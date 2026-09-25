# Writing Documents

There are four writes. Each one is a single Firestore call.

| Method | Firestore call | Use it to |
|---|---|---|
| `create(model)` | `add` | store a new document with a generated ID |
| `set(model)` | `set` | store or fully replace a document |
| `patch(id, ops)` | `update` | change some fields of an existing document |
| `delete(id)` | `delete` | remove a document |

## create

`create` stores the model under a Firestore-generated ID and returns that ID.
The model's ID field is ignored.

```dart
final id = await odm.users.create(
  User(
    id: '',
    name: 'Jane',
    email: 'jane@example.com',
    age: 30,
    profile: const Profile(bio: 'Hi'),
  ),
);
```

## set

`set` writes the whole document. Stored fields that are not in the model are
removed. The ID comes from the model's ID field, from the
`id:` argument, or from a document handle:

```dart
await odm.users.set(user);               // ID from user.id
await odm.users.set(user, id: 'custom'); // explicit ID
await odm.users('jane').set(user);       // document handle
```

## patch

`patch` changes only the fields you list. The document must already exist;
otherwise Firestore throws a `not-found` error.

```dart
await odm.users.patch('jane', ($) => [
  $.name.set('Jane Doe'),
  $.age.increment(1),
  $.tags.arrayUnion(['admin']),
  $.updatedAt.serverTimestamp(),
]);

// The same on a document handle
await odm.users('jane').patch(($) => [$.lastLogin.delete()]);
```

The builder offers these operations:

| Operation | Available on | Example |
|---|---|---|
| `set(value)` | every field | `$.name.set('Jane')` |
| `delete()` | every field | `$.lastLogin.delete()` |
| `increment(n)` | non-nullable `int`, `double`, `num` | `$.age.increment(1)` |
| `arrayUnion(values)` | non-nullable `List` | `$.tags.arrayUnion(['a'])` |
| `arrayRemove(values)` | non-nullable `List` | `$.tags.arrayRemove(['b'])` |
| `serverTimestamp()` | `DateTime` and `DateTime?` | `$.updatedAt.serverTimestamp()` |

`increment`, `arrayUnion`, `arrayRemove` and `serverTimestamp` run on the
server, so concurrent writers do not overwrite each other.

A nested model field has the same handles, by path, so you can update one
nested field without touching its siblings. Replace or remove the whole
nested value with `set` and `delete`:

```dart
await odm.users('jane').patch(($) => [
  $.profile.followers.increment(1),        // updates profile.followers only
  $.profile.interests.arrayUnion(['dart']),
]);

await odm.users('jane').patch(($) => [
  $.profile.set(const Profile(bio: 'Updated', followers: 10)),
]);
```

An empty list of operations writes nothing.

## delete

```dart
await odm.users.delete('jane');
await odm.users('jane').delete(); // same
```

Deleting a document does not delete its subcollections.

## Read, then write

When a write depends on what the document holds now, use a
[transaction](/guide/transactions). Firestore retries it if the document
changes between the read and the write.

```dart
await odm.runTransaction((tx) async {
  final users = odm.users.inTransaction(tx);
  final user = await users('jane').get();
  // Only upgrade users who are active and not premium yet.
  if (user != null && user.isActive && !user.isPremium) {
    users('jane').patch(($) => [
      $.isPremium.set(true),
      $.tags.arrayUnion(['upgraded']),
    ]);
  }
});
```

## Errors

`set`, `patch` and `delete` check the document ID first and throw
`FirestoreODMValidationException` (code `invalid_document_id`) for an invalid
ID. See [Document ID](/guide/document-id#validation).

To write many documents at once, see
[Batch Operations](/guide/batch-operations) and
[Bulk Operations](/guide/bulk-operations).
