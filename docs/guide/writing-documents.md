# Writing Documents

5.0 write verbs map 1:1 to Firestore primitives (ADR-0002). There is no
`insert`/`update`/`upsert` triad and no `modify()` magic.

## create — server-generated ID

`create` stores the document with a Firestore-generated ID and returns it:

```dart
final id = await db.users.create(User(
  id: '', // not stored; the real ID is returned
  name: 'Jane',
  email: 'jane@example.com',
));

print(id); // the generated document ID
```

## set — full replace

`set` writes the whole document. The ID comes from the model's document ID
field, or an explicit `id:` argument:

```dart
await db.users.set(user);               // id from user.id
await db.users.set(user, id: 'custom'); // explicit ID
await db.users('custom').set(user);     // document handle
```

`set` replaces the document; missing fields in the model are removed from the
stored document.

## patch — partial update with typed ops

`patch` applies exactly six FieldValue-shaped operations:

| Operation | Example |
|---|---|
| set | `p.name.set('Renamed')` |
| delete | `p.lastLogin.delete()` |
| increment | `p.age.increment(1)` |
| arrayUnion | `p.tags.arrayUnion(['new'])` |
| arrayRemove | `p.tags.arrayRemove(['old'])` |
| serverTimestamp | `p.updatedAt.serverTimestamp()` |

```dart
await db.users('jane').patch((p) => [
  p.age.increment(1),
  p.updatedAt.serverTimestamp(),
]);
```

## delete

```dart
await db.users('jane').delete();
```

## Validation

Document IDs are validated against Firestore's rules (non-empty, no `/`,
not `.`/`..`, ≤1500 bytes) before every write; violations raise
`FirestoreODMValidationException` with code `invalid_document_id`.

## Read-modify-write

If you need the current value to decide the next write, do it in a
transaction — that is where read-modify-write is safe:

```dart
await db.runTransaction((tx) async {
  final txUsers = db.users.inTransaction(tx);
  final user = await txUsers('jane').get();
  if (user != null) {
    txUsers('jane').patch((p) => [p.age.increment(1)]);
  }
});
```
