# Migrating from cloud_firestore

This guide shows common `cloud_firestore` code next to the Firestore ODM
equivalent. The ODM uses `cloud_firestore` underneath, so you can move one
collection at a time and keep the rest of your code unchanged.

Coming from the `cloud_firestore_odm` package instead? See
[Migrate from cloud_firestore_odm](/guide/migrate-from-cloud-firestore-odm).

## Before you start: stored data

The ODM reads documents into your model classes, so the stored data must match
the model:

- `DateTime` fields must be stored as `Timestamp` values. Strings are not
  converted.
- `Duration` fields are stored as integer microseconds.
- A field missing from a document takes the model's default (a Dart default
  or freezed's `@Default`); a missing non-nullable field without a default
  throws. Make a field nullable or give it a default if older documents lack
  it.
- A whole number stored in a `double` field (for example `5` written by the
  console or another client) reads as `5.0`.

A document that does not match its model throws when it is read.

## Setup

Add the packages, write your models and schema, then generate code. See
[Getting Started](/guide/getting-started), [Data Modeling](/guide/data-modeling)
and [Schema Definition](/guide/schema-definition).

```dart
// Before
final users = FirebaseFirestore.instance.collection('users');

// After
final odm = FirestoreODM(appSchema, firestore: FirebaseFirestore.instance);
final users = odm.users;
```

The examples below use the `User` and `Profile` models from
[Data Modeling](/guide/data-modeling).

## Read a document

```dart
// Before
final snap = await users.doc('jane').get();
final name = snap.exists ? snap.data()!['name'] as String : null;

// After
final user = await odm.users('jane').get(); // User?
final name = user?.name;
```

```dart
// Before
users.doc('jane').snapshots().listen((snap) { /* ... */ });

// After
odm.users('jane').stream.listen((User? user) { /* ... */ });
```

## Write a document

```dart
// Before
await users.doc('jane').set({'name': 'Jane', 'email': 'jane@example.com', /* ... */});
final ref = await users.add({'name': 'Bob', /* ... */});

// After
await odm.users.set(jane);                // ID from jane.id
final id = await odm.users.create(bob);   // generated ID
```

```dart
// Before
await users.doc('jane').update({
  'age': FieldValue.increment(1),
  'tags': FieldValue.arrayUnion(['premium']),
  'lastLogin': FieldValue.serverTimestamp(),
  'profile.bio': 'Hello',
});

// After
await odm.users('jane').patch(($) => [
  $.age.increment(1),
  $.tags.arrayUnion(['premium']),
  $.lastLogin.serverTimestamp(),
  $.profile.set(const Profile(bio: 'Hello')),
]);
```

The ODM patches a nested model as a whole value. To change one nested field
without replacing the rest, use `cloud_firestore` directly through
`odm.users('jane').ref.update({'profile.bio': 'Hello'})`.

```dart
// Before
await users.doc('jane').delete();

// After
await odm.users('jane').delete();
```

See [Writing Documents](/guide/writing-documents).

## Queries

```dart
// Before
final snap = await users
    .where('isActive', isEqualTo: true)
    .where('profile.followers', isGreaterThan: 1000)
    .orderBy('profile.followers', descending: true)
    .limit(10)
    .get();
final list = snap.docs.map((d) => d.data()).toList();

// After
final list = await odm.users
    .where(($) =>
        $.isActive(isEqualTo: true) & $.profile.followers(isGreaterThan: 1000))
    .orderBy(($) => ($.profile.followers(descending: true),))
    .limit(10)
    .get(); // List<User>
```

```dart
// Before
users.where(Filter.or(
  Filter('isPremium', isEqualTo: true),
  Filter('age', isGreaterThan: 65),
));

// After
odm.users.where(($) => $.isPremium(isEqualTo: true) | $.age(isGreaterThan: 65));
```

See [Filtering Data](/guide/filtering-data) and
[Ordering & Limiting](/guide/ordering-and-limiting).

## Pagination

```dart
// Before
final next = await users
    .orderBy('age')
    .startAfterDocument(lastSnapshot)
    .limit(20)
    .get();

// After
final next = await odm.users
    .orderBy(($) => ($.age(), $.documentId()))
    .startAfterObject(lastUser)
    .limit(20)
    .get();
```

See [Pagination](/guide/pagination).

## Aggregations

```dart
// Before
final snap = await users
    .aggregate(count(), sum('age'), average('age'))
    .get();
final total = snap.count;
final avg = snap.getAverage('age');

// After
final stats = await odm.users
    .aggregate(($) => (
          total: $.count(),
          sumAge: $.age.sum(),
          avgAge: $.age.average(),
        ))
    .get();
```

See [Aggregations](/guide/aggregations).

## Transactions

```dart
// Before
await FirebaseFirestore.instance.runTransaction((tx) async {
  final snap = await tx.get(users.doc('jane'));
  if ((snap.data()?['age'] as int? ?? 0) < 18) return;
  tx.update(users.doc('jane'), {'isActive': true});
});

// After
await odm.runTransaction((tx) async {
  final txUsers = odm.users.inTransaction(tx);
  final user = await txUsers('jane').get();
  if (user == null || user.age < 18) return;
  txUsers('jane').patch(($) => [$.isActive.set(true)]);
});
```

See [Transactions](/guide/transactions).

## Batches

```dart
// Before
final batch = FirebaseFirestore.instance.batch();
batch.set(users.doc('jane'), {/* ... */});
batch.update(users.doc('bob'), {'age': FieldValue.increment(1)});
batch.delete(users.doc('old'));
await batch.commit();

// After
await odm.runBatch((batch) {
  final b = odm.users.inBatch(batch);
  b.set(jane);
  b.patch('bob', ($) => [$.age.increment(1)]);
  b.delete('old');
});
```

See [Batch Operations](/guide/batch-operations).

## Subcollections

```dart
// Before
final posts = users.doc('jane').collection('posts');

// After: declare @Collection<Post>('users/*/posts') in the schema, then
final posts = odm.usersPosts('jane');
```

See [Subcollections](/guide/subcollections).

## Using cloud_firestore alongside the ODM

Every ODM object exposes the underlying `cloud_firestore` object for anything
the ODM does not cover:

| ODM | `cloud_firestore` |
|---|---|
| `odm.firestore` | `FirebaseFirestore` |
| `odm.users.ref` | `CollectionReference<Map<String, dynamic>>` |
| `odm.users('jane').ref` | `DocumentReference<Map<String, dynamic>>` |
| `query.nativeQuery` | `Query<Map<String, dynamic>>` |
