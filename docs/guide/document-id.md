# Document ID

Annotate the model field that mirrors the Firestore document ID:

```dart
@freezed
class User with _$User {
  const factory User({
    @DocumentIdField() required String id,
    required String name,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

The annotated field is metadata, not a stored field. On reads, the ODM fills it
from the snapshot ID; on writes, it chooses the document path and omits the ID
field from the stored map.

## Explicit IDs

`set` replaces a complete document. It can read the ID from the model or take
one explicitly:

```dart
await db.users.set(user);                    // uses user.id
await db.users.set(user, id: 'user-123');    // uses the explicit ID
await db.users('user-123').set(user);        // document handle
```

## Server-generated IDs

`create` asks Firestore for an ID and returns it. There is no auto-ID sentinel:

```dart
final id = await db.users.create(User(id: '', name: 'Jane'));
print(id);
```

The same rule applies in a batch or transaction: `create` returns the allocated
ID, while `set` and `patch` use an explicit path.

IDs are validated before writes. Empty IDs, `/`, `.`/`..`, and IDs over the
Firestore byte limit raise `FirestoreODMValidationException`.
