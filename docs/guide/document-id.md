# Document ID

Every Firestore document has an ID. The ODM copies that ID into one `String`
field of your model.

## Choosing the ID field

The generator picks the ID field in this order:

1. The constructor parameter marked `@DocumentIdField()`. It must be a
   `String`, and only one parameter may carry it.
2. Otherwise, a `String` parameter named `id`.
3. Otherwise, the model has no ID field.

```dart
@freezed
@firestoreOdm
abstract class Member with _$Member {
  const factory Member({
    @DocumentIdField() required String uid, // holds the document ID
    required String name,
  }) = _Member;
}
```

## How the ID is handled

- **Writes:** the ID field is removed from the stored data. The document ID
  itself is the only copy.
- **Reads:** `get`, `stream` and queries fill the ID field from the document's
  ID.

## Writing with an ID

```dart
// The ID comes from the model: stored at users/jane
await odm.users.set(User(id: 'jane', /* ... */));

// An explicit ID wins over the model's field: stored at users/custom
await odm.users.set(user, id: 'custom');

// A document handle uses its own ID
await odm.users('jane').set(user);
```

For a model without an ID field, pass `id:` to `set`, or use a document
handle.

## Generated IDs

`create` lets Firestore generate the ID and returns it. The ID field in the
model you pass is ignored, so an empty string is fine:

```dart
final id = await odm.users.create(User(id: '', /* ... */));
final saved = await odm.users(id).get(); // saved?.id == id
```

`create` is also available in batches and transactions, where it returns the
new ID immediately (see [Batch Operations](/guide/batch-operations)).

## Querying by ID

Filters and ordering accept the `documentId` pseudo-field:

```dart
final some = await odm.users
    .where(($) => $.documentId(whereIn: ['alice', 'bob']))
    .get();

final ordered = await odm.users
    .orderBy(($) => ($.age(), $.documentId()))
    .get();
```

## Validation

`set`, `patch` and `delete` on a collection (including in batches and
transactions) check the ID before writing. An ID must not be empty,
must not contain `/`, must not be `.` or `..`, must not match `__.*__`
(reserved by Firestore), and must be at most 1,500 bytes as UTF-8. A rejected ID throws `FirestoreODMValidationException` with code
`invalid_document_id`. `set` without an ID throws the same exception when the
model's ID field is empty.
