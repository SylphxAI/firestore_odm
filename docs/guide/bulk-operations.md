# Bulk Operations

`patchAll` and `deleteAll` apply one write to every document a query matches.
They read the matching documents, then write in batches of at most 500, which
is Firestore's per-batch limit.

Each batch commits on its own. If a later batch fails, earlier batches stay
committed. For an all-or-nothing change to a small set of documents, use a
[batch](/guide/batch-operations) or a [transaction](/guide/transactions).

## patchAll

`patchAll` takes a list of patch operations. Build them with the model's
generated patch builder, `<Model>PatchBuilder`:

```dart
final p = UserPatchBuilder();

await odm.users
    .where(($) => $.isActive(isEqualTo: false))
    .patchAll([
      p.isPremium.set(false),
      p.tags.arrayUnion(['inactive']),
      p.updatedAt.serverTimestamp(),
    ]);
```

The operations are the same as for [`patch`](/guide/writing-documents#patch).

## deleteAll

```dart
await odm.users
    .where(($) => $.lastLogin(isNull: true))
    .deleteAll();

// Every document in the collection
await odm.users.deleteAll();
```

`deleteAll` does not delete subcollections of the deleted documents.
