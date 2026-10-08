# Migrate from cloud_firestore_odm

`cloud_firestore_odm` has not had a release since `1.0.0-dev.88` (October 2024).
That release requires `cloud_firestore ^5`, and its generator requires
`analyzer <7` and `freezed_annotation <3`. So you cannot use it with
`cloud_firestore` 6, `firebase_core` 4, freezed 3 or a current
`json_serializable`. firestore_odm covers the same ground on current Firebase
and adds typed updates, aggregates and OR filters.

The codemod changes local source files, not your Firestore database. Keep your
collection paths, document IDs and stored field names unchanged. Before shipping,
check any custom `fromJson`/`toJson`, `@JsonConverter` or `@JsonKey` mapping against
an existing document: firestore_odm stores `DateTime` as native Firestore
`Timestamp`, not an ISO string. Do not rewrite stored data to make a code migration
pass. Use a compatible converter when your old app used another representation.

## The 10-minute path

Allow about 10 minutes for the small sample below, excluding SDK installation and
package downloads. This is a walkthrough budget, not a measured guarantee for an
arbitrary app; handwritten converters and transaction helpers take longer.

Requires Flutter with Dart 3.8.1 or later, Git, and a working `build_runner` setup.
You do not need Firebase credentials or a running database for the sample.

1. **Checkpoint (1 minute).** Start from a clean working tree and commit the old
   app, including `pubspec.lock`. Create a migration branch and record the old
   commit: `git rev-parse HEAD`. Keep that commit until the new client is verified.
2. **Preview and apply (2 minutes).** Run the commands in step 1 below. Preview
   does not write anything. Read the file/line leftovers before applying, and
   review `git diff` afterwards.
3. **Finish leftovers (4 minutes).** Work through step 2 below, then regenerate.
   The printed list is heuristic and can include already-rewritten calls or
   unrelated `.data` accesses. Zero leftovers is not proof that an app compiles.
4. **Verify (3 minutes).** Run `dart format lib test`, `flutter analyze`, and
   `flutter test`. On your own app, also test an existing document and the queries,
   writes, transactions and listeners you use, with your normal emulator tests.
   Only then ship through your usual release path.

### Try it without touching your app

Create a disposable Flutter app with `flutter create odm_migration_sample` and
open it. Delete its default `test/widget_test.dart`. Replace `lib/main.dart` with
`void main() {}` (the sample checks the data API, not a screen).

Add these entries to its `pubspec.yaml`. Keep the Flutter SDK dependency and
`flutter_test` entry that `flutter create` supplied. The old dependencies are input
to the migration; do not resolve them before running the codemod.

```yaml
# migration-sample: dependencies
dependencies:
  cloud_firestore: ^5.0.0
  cloud_firestore_odm: ^1.0.0-dev.88
  json_annotation: ^4.9.0
dev_dependencies:
  build_runner: ^2.4.0
  cloud_firestore_odm_generator: ^1.0.0-dev.88
```

Save this as `lib/movie.dart`:

```dart
// migration-sample: old-model
import 'package:cloud_firestore_odm/cloud_firestore_odm.dart';
import 'package:json_annotation/json_annotation.dart';

part 'movie.g.dart';

@JsonSerializable()
class Movie {
  Movie({required this.id, required this.title, required this.likes});

  @Id()
  final String id;
  final String title;
  final int likes;
}

@Collection<Movie>('movies')
final moviesRef = MovieCollectionReference();
```

Make the checkpoint, then run step 1. The codemod creates `MoviesSchema`,
`moviesSchema`, `moviesOdm` and a typed `moviesRef` in the same file. Keep its
`part 'movie.g.dart';` line. After applying, add the fake used only for tests:

```sh
flutter pub add dev:fake_cloud_firestore
```

Save this as `test/migration_test.dart`, generate and run `flutter test`:

```dart
// migration-sample: verification
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firestore_odm/firestore_odm.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/movie.dart';

void main() {
  test('existing documents keep their IDs and typed writes keep their fields', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('movies').doc('old-id').set({
      'title': 'Existing movie',
      'likes': 1,
    });
    final movies = FirestoreODM(moviesSchema, firestore: firestore).movies;
    final oldMovie = await movies('old-id').get();
    expect(oldMovie!.id, 'old-id');
    expect(oldMovie.title, 'Existing movie');

    await movies('old-id').patch(($) => [$.likes.increment(1)]);
    final matches = await movies
        .where(($) => $.likes(isGreaterThan: 1))
        .get();
    expect(matches.single.id, 'old-id');
    expect(matches.single.likes, 2);
    final raw = await firestore.collection('movies').doc('old-id').get();
    expect(raw.data(), {'title': 'Existing movie', 'likes': 2});
  });
}
```

This test reads a pre-existing document before writing; it does not call
`Firebase.initializeApp` or connect to production. The same walkthrough is run
in CI by `scripts/check-migration-guide.sh`. The fake is not a substitute for
emulator coverage of your own converters, indexes, rules or SDK-specific queries.

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

For a Flutter app, use `flutter pub get` and `flutter analyze` in place of the
`dart` commands above. Run `dart format lib test` after the rewrite. Do not remove
`json_serializable` or `json_annotation` while other models still use them.

The CLI skips generated `.g.dart` and `.freezed.dart` files. Regenerate those;
do not hand-edit them. Source directories outside `lib/`, `test/`, `bin/` and
`integration_test/` are not scanned, so check any custom source locations yourself.

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

## Roll back safely

If generation, analysis or the sample test fails, stop before releasing. Keep the
leftovers output and diff for diagnosis. To recover without discarding that work,
open the checkpoint in a separate worktree:

```sh
git worktree add ../your_app_before_odm <checkpoint-sha>
```

Replace `<checkpoint-sha>` with the old commit recorded earlier. In that worktree,
use the **old Flutter SDK**, run `flutter pub get` against the old lockfile, and
regenerate with the old builder. Run its normal tests. Your migration branch stays
intact, so you can fix it or abandon it without a destructive reset.

If a migrated client has already shipped, redeploy the previous tested client
using your normal release path. A code rollback cannot undo writes made by that
client. Verify old and new clients can both read your stored representations
before release; if they cannot, keep the old representation through a converter
and handle any necessary data migration separately. Never delete collections or
rewrite documents as a rollback step for this codemod.

## Sharing the guide with someone still on the old package

When answering a migration or dependency-compatibility question in the
[old package's issue tracker](https://github.com/FirebaseExtended/firestoreodm-flutter/issues),
link this walkthrough rather than copying the API table into an answer. A concise
answer is:

> firestore_odm is a separately maintained alternative with a preview-first
> migration command. The [10-minute sample and migration guide](https://sylphxai.github.io/firestore_odm/guide/migrate-from-cloud-firestore-odm)
> covers the rewrites, manual leftovers, tests and rollback. It changes source
> files, not the database; check existing document serialization before shipping.

Use it only where it answers the question; it is not an official Firebase package
or an automatic drop-in replacement.

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
