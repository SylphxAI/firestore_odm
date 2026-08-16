# Reading Documents

Read a document with `get()`. A missing document is represented by `null`:

```dart
final user = await db.users('jane-doe').get();
if (user == null) {
  print('User not found');
} else {
  print(user.name);
}
```

Subscribe to changes with `stream`:

```dart
final subscription = db.users('jane-doe').stream.listen((user) {
  print(user == null ? 'User was deleted' : user.name);
});

await subscription.cancel();
```

There is no separate `exists()` API. Use `get() == null` when the document
contents are not needed; this keeps one read contract and one source of truth.
