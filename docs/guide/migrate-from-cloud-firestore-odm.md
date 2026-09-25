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
| model class used in a `@Collection` | the same class with `@firestoreOdm` |
| `@Id()` | `@DocumentIdField()` |
| `.whereTitle(isEqualTo: t)` | `.where(($) => $.title(isEqualTo: t))` |
| `.whereDocumentId(whereIn: ids)` | `.where(($) => $.documentId(whereIn: ids))` |
| `.orderByYear(startAfter: 2000).orderByTitle(startAfter: 'M')` | `.orderBy(($) => ($.year(), $.title())).startAfter((2000, 'M'))` |
| `.update(title: t, likesFieldValue: FieldValue.increment(1))` | `.patch(($) => [$.title.set(t), $.likes.increment(1)])` |
| `moviesRef.doc(id).comments` | `moviesOdm.moviesComments(id)` |
| `moviesRef.add(movie)` | `moviesRef.create(movie)` (returns the new id) |
| `.snapshots()` on a typed reference | `.stream` |
| `@Min(0)` / `@Max(10)` and the generated `_$assertMovie(this)` call | removed; listed as a follow-up |

The codemod keeps your reference variables (`moviesRef`), so most call sites
compile once the calls above are rewritten.

## 2. Finish what the codemod lists

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

Use a `StreamBuilder` over the typed stream:

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
StreamBuilder<List<Movie>>(
  stream: moviesRef.orderBy(($) => ($.likes(descending: true),)).stream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const CircularProgressIndicator();
    return MovieList(snapshot.data!);
  },
);
```

Create the stream once (for example in `initState`), not in `build`, so a
rebuild does not start a new listener.

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

firestore_odm has no `@Min`/`@Max`. Check values in the model constructor, or
in the code that builds the model.

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
