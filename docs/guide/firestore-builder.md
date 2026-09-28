# FirestoreBuilder

`FirestoreBuilder` listens to a typed reference or query and rebuilds when the
data changes. It is the widget `cloud_firestore_odm` had, with the same
`ref`/`builder`/`child` shape; the snapshot carries your models instead of
snapshot wrappers.

```dart
import 'package:firestore_odm/firestore_odm.dart';

FirestoreBuilder<List<User>>(
  ref: odm.users.where(($) => $.isPremium(isEqualTo: true)),
  builder: (context, snapshot, child) {
    if (snapshot.hasError) return Text('Failed: ${snapshot.error}');
    if (!snapshot.hasData) return const CircularProgressIndicator();
    return ListView(
      children: [for (final user in snapshot.data!) Text(user.name)],
    );
  },
);
```

`ref` is anything the ODM can watch:

| `ref` | `snapshot.data` |
| --- | --- |
| `odm.users` (collection) | `List<User>` |
| `odm.users.where(...)`, `orderBy(...)`, `limit(...)` | `List<User>` |
| `odm.users('jane')` (document) | `User?` (null while the document does not exist) |

The type argument is inferred from `ref` when you leave it out.

## Snapshot states

`snapshot` is an `AsyncSnapshot`, exactly as with `StreamBuilder`:

| state | meaning |
| --- | --- |
| `ConnectionState.waiting`, no data | The first value has not arrived yet. Show a spinner or a skeleton. |
| `ConnectionState.active`, `hasData` | A value is available: `snapshot.data`. |
| `ConnectionState.active`, `hasError` | The stream failed: `snapshot.error`, `snapshot.stackTrace`. |

`snapshot.hasData` is false only until the first event; a document that does
not exist arrives as `data == null` with `hasData` true, so "loading" and
"missing" stay distinguishable.

## Rebuilds and listener reuse

The widget keeps one listener per reference. When the widget rebuilds — for
example because a parent set state, or because a filter value changed and you
build a new query — the listener is reused if `ref` still points at the same
document or query, and only then replaced:

```dart
FirestoreBuilder<List<User>>(
  ref: odm.users.where(($) => $.age(isGreaterThanOrEqualTo: minAge)),
  builder: ...,
);
```

Here, a rebuild with the same `minAge` reuses the listener; changing `minAge`
listens to the new query and cancels the old one. This matters for billing:
each listener is a Firestore read stream.

When the reference changes, the previous value is kept while the new one
loads, so the list does not flash empty on every change.

## child

`child` is passed to `builder` untouched, for the part of the tree that does
not depend on the data:

```dart
FirestoreBuilder<List<User>>(
  ref: odm.users,
  builder: (context, snapshot, child) => Column(
    children: [
      child!,
      if (snapshot.hasData) Text('${snapshot.data!.length} users'),
    ],
  ),
  child: const Header(),
);
```

## With StreamBuilder instead

If you prefer `StreamBuilder`, pass `ref.stream`. Create the stream once (for
example in `initState`) rather than in `build`, so rebuilds do not start a new
listener:

```dart
late final Stream<List<User>> _users = odm.users.stream;
```

The listener runs while the widget is mounted; `FirestoreBuilder` cancels its
subscription in `dispose`.
