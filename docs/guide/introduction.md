# What is firestore_odm?

firestore_odm is a type-safe object document mapper (ODM) for
[Cloud Firestore](https://firebase.google.com/docs/firestore) in Flutter and
Dart. You describe your documents as Dart classes and list your collections in
a schema; a code generator then gives every collection typed queries,
updates, aggregates, transactions, batches and streams.

It is the maintained successor to the official `cloud_firestore_odm`, which
has had no release since October 2024 and does not work with
`cloud_firestore` 6.

## What it fixes

With plain `cloud_firestore`, field names are strings and documents are
`Map<String, dynamic>`:

```dart
final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('isActive', isEqualTo: true)
    .where('age', isGreaterThan: 18)
    .get();
final names = snapshot.docs.map((d) => d.data()['name'] as String);

await FirebaseFirestore.instance.doc('users/kim').update({
  'profile.followers': FieldValue.increment(1),
});
```

A typo in `'isActive'` or `'profile.followers'`, or a value of the wrong type,
fails at runtime or silently writes a bad document. With firestore_odm the
compiler checks both:

```dart
final users = await db.users
    .where(($) => $.isActive(isEqualTo: true) & $.age(isGreaterThan: 18))
    .get(); // List<User>
final names = users.map((u) => u.name);

await db.users('kim').patch(($) => [$.profile.followers.increment(1)]);
```

## How it works

- **Models** are plain Dart classes, freezed classes or json_serializable
  classes annotated with `@firestoreOdm`.
- **The schema** lists collections with `@Collection<T>('path')`;
  `users/*/posts` declares a subcollection.
- **`build_runner`** generates the Firestore converters and a `$` selector per
  model, which the query, update and aggregate APIs take as a callback.
- **At runtime** each call maps to one `cloud_firestore` call. There is no
  reflection and no client-side emulation: an aggregate is a server-side
  aggregate query, a transaction is a Firestore transaction.

## Where it runs

Android, iOS, macOS, Windows and web: the platforms `cloud_firestore`
supports. It needs Dart 3.8 or later and `cloud_firestore` 6.

The Firebase Admin SDK for server-side Dart is not a target: firestore_odm
wraps the client SDK and depends on Flutter.

## Next

- [Getting started](/guide/getting-started)
- [Comparison](/guide/comparison) with cloud_firestore_odm, raw
  cloud_firestore and other packages
- [Migrate from cloud_firestore_odm](/guide/migrate-from-cloud-firestore-odm)
- [Benchmarks](/guide/benchmarks)
