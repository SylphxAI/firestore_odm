# Reading Documents

Call a collection with an ID to get a document handle. `odm.users('jane')` and
`odm.users.doc('jane')` are the same.

## Read once

`get()` returns the model, or `null` when the document does not exist.

```dart
final user = await odm.users('jane').get();

if (user != null) {
  print('Found ${user.name}');
} else {
  print('No such user');
}
```

To check whether a document exists, compare the result with `null`.

### Cache or server only

Pass `GetOptions` to choose where the read comes from. `GetOptions` and
`Source` are exported by `firestore_odm`.

```dart
final cached = await odm.users('jane').get(
  const GetOptions(source: Source.cache),
);
```

## Listen for changes

`stream` emits the document now and after every change. It emits `null` while
the document does not exist.

```dart
final subscription = odm.users('jane').stream.listen((user) {
  if (user == null) {
    print('Deleted');
  } else {
    print('Updated: ${user.name}');
  }
});

// Cancel when you no longer need updates, for example in dispose().
await subscription.cancel();
```

Each read of `stream` starts a new listener. In a Flutter widget, create the
stream once (for example in `initState`) and pass it to a `StreamBuilder`.

To read many documents, see [Fetching Data](/guide/fetching-data).
