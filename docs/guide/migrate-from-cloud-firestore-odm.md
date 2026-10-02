# Migrate from cloud_firestore_odm

`cloud_firestore_odm` has not had a release since `1.0.0-dev.88` (October 2024).
That release requires `cloud_firestore ^5`, and its generator requires
`analyzer <7` and `freezed_annotation <3`. So you cannot use it with
`cloud_firestore` 6, `firebase_core` 4, freezed 3 or a current
`json_serializable`. firestore_odm covers the same ground on current Firebase
and adds typed updates, aggregates and OR filters.

Your Firestore data does not change. Both packages read and write the same
documents, so you only migrate code.

## 1. Run the codemod

The codemod ships with `firestore_odm_builder`. It rewrites your
`pubspec.yaml` and the Dart files in `lib/`, `test/`, `bin/` and
`integration_test/`, then lists anything left to finish by hand, with file and
line.

```sh
dart pub global activate firestore_odm_builder
cd your_app
dart pub global run firestore_odm_builder:migrate          # preview
dart pub global run firestore_odm_builder:migrate --apply  # write the changes
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart analyze
```

Commit or stash your work first, so you can review the diff.

What the codemod rewrites:

| cloud_firestore_odm | firestore_odm |
| --- | --- |
| `cloud_firestore_odm`, `cloud_firestore_odm_generator` in `pubspec.yaml` | `firestore_odm`, `firestore_odm_builder`; `cloud_firestore` raised to `^6.4.0`, `firebase_core` to `^4.0.0` |
| `import 'package:cloud_firestore_odm/...'` | `import 'package:firestore_odm/firestore_odm.dart'` |
| `@Collection<Movie>('movies')` + `final moviesRef = MovieCollectionReference();` | a schema class, `@Schema()`, the same `@Collection`s, and `final moviesRef = moviesOdm.movies;` |
| `@Collection<Movie>('movies')` written on the model class itself | removed from the class and declared in a schema at the end of the same file (`MovieSchema`, `movieSchema`, `movieOdm`); keep that file's `part '...g.dart'` line, because the generated code goes into it |
| `MovieCollectionReference(firestore)` / `MovieCollectionReference()` for a model with a root collection | `FirestoreODM(movieSchema, firestore: firestore).movies` / `movieOdm.movies`; calls on a variable assigned from it (`.snapshots()`, `.add()`, `whereX`) are rewritten too |
| model class used in a `@Collection` | the same class with `@firestoreOdm` |
| `@Id()` | `@DocumentIdField()` |
| `.whereTitle(isEqualTo: t)` | `.where(($) => $.title(isEqualTo: t))` |
| `.whereDocumentId(whereIn: ids)` | `.where(($) => $.documentId(whereIn: ids))` |
| `.orderByYear(startAfter: 2000).orderByTitle(startAfter: 'M')` | `.orderBy(($) => ($.year(), $.title())).startAfter((2000, 'M'))` |
| `.update(title: t, likesFieldValue: FieldValue.increment(1))` | `.patch(($) => [$.title.set(t), $.likes.increment(1)])` |
| `moviesRef.doc(id).comments` | `moviesOdm.moviesComments(id)` |
| `moviesRef.add(movie)` | `moviesRef.create(movie)` (returns the new id) |
| `.snapshots()` on a typed reference | `.stream` |
| `FirestoreBuilder<MovieQuerySnapshot>(...)` / `FirestoreBuilder<MovieDocumentSnapshot>(...)` | `FirestoreBuilder<List<Movie>>(...)` / `FirestoreBuilder<Movie?>(...)`, the same widget with the model payload type |
| `@Min(0)` / `@Max(10)` and the generated `_$assertMovie(this)` call | the annotations are kept (the generated write paths enforce them); only the `_$assertMovie(this)` call is removed |

The codemod keeps your reference variables (`moviesRef`), so most call sites
compile once the calls above are rewritten.

## 2. Finish what the codemod lists

### Generated reference types

cloud_firestore_odm generated `MovieDocumentReference`, `CommentCollectionReference`
and `MovieQuerySnapshot` types that you might use in field types, function
signatures or helpers such as
`CommentCollectionReference(moviesRef.doc(id).reference)`. The codemod lists
each one by line and leaves it alone, because the right replacement depends on
how you use it:

| cloud_firestore_odm | firestore_odm |
| --- | --- |
| `MovieCollectionReference` / `MovieQuery` type | the typed collection or query from the schema, for example `moviesOdm.movies` |
| `MovieDocumentReference` type | the typed document, `moviesOdm.movies(id)` |
| `CommentCollectionReference(movieRef.reference)` for a subcollection | `moviesOdm.moviesComments(movieId)` |
| `typedRef.reference` | `typedRef.ref` (the native reference) |
| `MovieDocumentSnapshot` / `MovieQuerySnapshot` outside `FirestoreBuilder` | `Movie?` / `List<Movie>` |

A model with only subcollection paths has no root collection, so its
`XCollectionReference(...)` constructor is also listed instead of rewritten.

Long lines that the codemod writes (for example
`FirestoreODM(movieSchema, firestore: db).movies`) are not wrapped; run
`dart format .` afterwards. If the schema lives in a different file from the
code that uses it, add the import for that file.

### Reads return models, not snapshots

cloud_firestore_odm returned snapshot wrappers. firestore_odm returns your
models:

| cloud_firestore_odm | firestore_odm |
| --- | --- |
| `(await ref.doc(id).get()).data` | `await ref.doc(id).get()` (`Movie?`) |
| `(await query.get()).docs.map((d) => d.data)` | `await query.get()` (`List<Movie>`) |
| `snapshot.id` | the model's `@DocumentIdField()` field |
| `query.snapshots()` of `MovieQuerySnapshot` | `query.stream` of `List<Movie>` |
| `ref.doc(id).get(GetOptions(source: Source.cache))` | `ref.doc(id).get(const GetOptions(source: Source.cache))` |

If you read `snapshot.metadata` (for example `hasPendingWrites`), use the
native reference: `ref.ref` for a collection, `ref.doc(id).ref` for a
document, or `query.nativeQuery` for a query.

### FirestoreBuilder

`FirestoreBuilder` is the same widget, and `ref` accepts the typed reference
or query directly:

```dart
// cloud_firestore_odm
FirestoreBuilder<MovieQuerySnapshot>(
  ref: moviesRef.orderByLikes(descending: true),
  builder: (context, snapshot, child) {
    final movies = snapshot.requireData.docs.map((d) => d.data).toList();
    return MovieList(movies);
  },
);

// firestore_odm
FirestoreBuilder<List<Movie>>(
  ref: moviesRef.orderBy(($) => ($.likes(descending: true),)),
  builder: (context, snapshot, child) {
    if (!snapshot.hasData) return const CircularProgressIndicator();
    return MovieList(snapshot.data!);
  },
);
```

The snapshot carries your models instead of snapshot wrappers:
`AsyncSnapshot<List<Movie>>` for a collection or query, `AsyncSnapshot<Movie?>`
for a document. `snapshot.data!.docs`/`.data` collapse to `snapshot.data!`, and
a missing document is `data == null` rather than a snapshot with `exists`.
The type argument can also be left off when it is inferable from `ref`.

The widget keeps its listener while `ref` still points at the same document or
query, so rebuilding with a freshly created query does not start a second,
billable listener. See [FirestoreBuilder](/guide/firestore-builder).

With a `StreamBuilder` instead, create the stream once (for example in
`initState`), not in `build`, for the same reason.

### Transactions and batches

`transactionGet`, `transactionUpdate`, `transactionSet`, `batchUpdate` and
`batchSet` become typed transaction and batch handles:

```dart
// cloud_firestore_odm
await FirebaseFirestore.instance.runTransaction((tx) async {
  final movie = await moviesRef.doc(id).transactionGet(tx);
  moviesRef.doc(id).transactionUpdate(tx, likes: movie.data!.likes + 1);
});

// firestore_odm
await moviesOdm.runTransaction((tx) async {
  final movies = moviesOdm.movies.inTransaction(tx);
  final movie = await movies(id).get();
  movies(id).patch(($) => [$.likes.set(movie!.likes + 1)]);
});

// or, without reading first:
await moviesRef.patch(id, ($) => [$.likes.increment(1)]);
```

Batches: `await moviesOdm.runBatch((batch) { moviesOdm.movies.inBatch(batch).set(movie); });`.

### Snapshot cursors

`startAfterDocument: snapshot` becomes a cursor on the ordered query, from the
last model you received or from the values themselves:

```dart
final page2 = await moviesRef
    .orderBy(($) => ($.likes(descending: true),))
    .startAfterObject(page1.last)
    .limit(20)
    .get();
```

### Validators

`@Min` and `@Max` stay where they are, and now work on both write paths. They
are checked when a model is written (`set`, `create`) and when a patched field
is set (`$.likes.set(...)`); an out-of-range value throws a
`FirestoreODMValidationException` before anything reaches Firestore. A null
value passes, as it did in cloud_firestore_odm. `increment` is not bounded —
it is a relative change, and the server applies it.

### Named queries (bundles)

Load the bundle with `FirebaseFirestore.instance.loadBundle(...)` and query
through the typed collection; the SDK serves matching queries from the
bundle's cache.

## What you gain

- Typed updates: `$.likes.increment(1)`, `$.tags.arrayUnion([...])`,
  `$.updatedAt.serverTimestamp()`, nested fields such as
  `$.profile.followers.increment(1)`.
- OR filters: `where(($) => $.year(isLessThan: 1970) | $.likes(isGreaterThan: 1000))`.
- Server-side aggregates:
  `aggregate(($) => (count: $.count(), avgLikes: $.likes.average())).get()`.
- Bulk writes over a query: `patchAll` and `deleteAll`, chunked to
  Firestore's 500-write limit.
- Models without json_serializable: plain classes and freezed classes both
  work; the builder generates the Firestore converters.

See [Comparison](/guide/comparison) for the full feature table and
[Benchmarks](/guide/benchmarks) for code generation and runtime numbers.
