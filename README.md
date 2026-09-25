<div align="center">

<img src="https://mark.sylphx.com/api/v1/mark/hero?type=wave&theme=tokyonight&text=firestore_odm&desc=Type-safe+Firestore+ODM+for+Flutter+and+Dart&height=200&animation=rise" alt="firestore_odm" width="100%" />

# firestore_odm

**Type-safe Firestore ODM for Flutter and Dart — the maintained successor to cloud_firestore_odm.**

[![pub package](https://img.shields.io/pub/v/firestore_odm?style=flat-square)](https://pub.dev/packages/firestore_odm)
[![pub points](https://img.shields.io/pub/points/firestore_odm?style=flat-square)](https://pub.dev/packages/firestore_odm/score)
[![CI](https://img.shields.io/github/actions/workflow/status/SylphxAI/firestore_odm/ci.yml?style=flat-square&label=CI)](https://github.com/SylphxAI/firestore_odm/actions/workflows/ci.yml)
[![GitHub stars](https://img.shields.io/github/stars/SylphxAI/firestore_odm?style=flat-square)](https://github.com/SylphxAI/firestore_odm/stargazers)
[![license](https://img.shields.io/github/license/SylphxAI/firestore_odm?style=flat-square)](https://github.com/SylphxAI/firestore_odm/blob/main/LICENSE)

[Documentation](https://sylphxai.github.io/firestore_odm/) · [Getting started](https://sylphxai.github.io/firestore_odm/guide/getting-started) · [Migrate from cloud_firestore_odm](https://sylphxai.github.io/firestore_odm/guide/migrate-from-cloud-firestore-odm) · [Benchmarks](https://sylphxai.github.io/firestore_odm/guide/benchmarks)

</div>

Describe your documents once. firestore_odm generates typed queries, updates,
aggregates, transactions and streams for them, so a misspelled field or a
wrong value type is a compile error instead of a production bug.

```dart
@firestoreOdm
class User {
  const User({required this.id, required this.name, required this.age, this.tags = const [], this.lastLogin});

  @DocumentIdField()
  final String id;
  final String name;
  final int age;
  final List<String> tags;
  final DateTime? lastLogin;
}

class AppSchema extends FirestoreSchema {
  const AppSchema();
}

@Schema()
@Collection<User>('users')
@Collection<Post>('users/*/posts') // Post: another @firestoreOdm model
const appSchema = AppSchema();
```

```dart
final db = FirestoreODM(appSchema);

// Typed filters, ordering and paging. Returns List<User>.
final adults = await db.users
    .where(($) => $.age(isGreaterThanOrEqualTo: 18) & $.tags(arrayContains: 'beta'))
    .orderBy(($) => ($.age(descending: true), $.name()))
    .limit(20)
    .get();

// Typed atomic updates, including nested fields.
await db.users('kim').patch(($) => [
  $.age.increment(1),
  $.tags.arrayUnion(['admin']),
  $.lastLogin.serverTimestamp(),
]);

// Server-side aggregates as a typed record.
final stats = await db.users
    .aggregate(($) => (count: $.count(), averageAge: $.age.average()))
    .get();

// Subcollections, streams and transactions.
db.usersPosts('kim').stream.listen((posts) => print(posts.length));
await db.runTransaction((tx) async {
  final users = db.users.inTransaction(tx);
  final kim = await users('kim').get();
  users('kim').patch(($) => [$.age.set(kim!.age + 1)]);
});
```

A complete, tested version of this example is in
[`example/lib/main.dart`](https://github.com/SylphxAI/firestore_odm/blob/main/packages/firestore_odm/example/lib/main.dart).

## Why firestore_odm

The official `cloud_firestore_odm` has not had a release since
`1.0.0-dev.88` (October 2024). It requires `cloud_firestore ^5`, and its
generator requires `analyzer <7`, so it cannot be used with `cloud_firestore`
6, `firebase_core` 4, freezed 3 or a current `json_serializable`.

firestore_odm runs on current Firebase and Flutter, is released as stable
versions, and goes further:

- **Typed everything**: filters (with `&` and `|`), nested fields
  (`$.profile.followers`), ordering with record-typed cursors, partial updates,
  aggregates, transactions and batches.
- **Firestore semantics, no surprises**: `DateTime` is stored as a native
  Timestamp; `GeoPoint`, `DocumentReference` and `Blob` fields are stored
  natively; every write maps to one Firestore call.
- **Any model style**: plain Dart classes, freezed or json_serializable. The
  builder generates the Firestore converters, so json_serializable is optional.
  Fields added later with a default read fine from older documents.
- **Bulk writes**: `patchAll` and `deleteAll` over a query, chunked to
  Firestore's 500-write batch limit.
- **Fast builds**: after a model edit, 20 models rebuild in 1.5 seconds,
  against 17 seconds with cloud_firestore_odm; runtime cost stays within a few
  microseconds of raw `cloud_firestore`
  ([benchmarks](https://sylphxai.github.io/firestore_odm/guide/benchmarks)).
- **Firestore Pipelines** (Enterprise edition, experimental) with typed stages.

## Install

```sh
flutter pub add firestore_odm cloud_firestore firebase_core
flutter pub add dev:firestore_odm_builder dev:build_runner
dart run build_runner build --delete-conflicting-outputs
```

Requires Dart 3.8 or later and `cloud_firestore` 6. Supported on Android, iOS,
macOS, Windows and web (the platforms `cloud_firestore` supports).

## Compared with the alternatives

| | firestore_odm | cloud_firestore_odm | raw cloud_firestore |
| --- | --- | --- | --- |
| Works with cloud_firestore 6 / firebase_core 4 | yes | no | yes |
| Typed filters and ordering | yes | yes | no (field names as strings) |
| OR filters and nested fields | yes | no | untyped |
| Typed partial updates (increment, arrayUnion, serverTimestamp) | yes | through untyped `FieldValue` | no |
| Aggregates (count, sum, average) | typed | no | untyped |
| Typed transactions and batches | yes | update only | no |
| Update or delete every match of a query | yes | no | by hand |
| json_serializable required | no | yes | no |
| Last release | 2026, stable | 2024, pre-release | current |

The [full comparison](https://sylphxai.github.io/firestore_odm/guide/comparison)
covers every feature and the other Firestore packages on pub.dev.

## Migrate from cloud_firestore_odm

A codemod rewrites your pubspec, collection declarations, `whereX` / `orderByX`
queries, `update(...)` calls and subcollection access, and lists anything left
to finish by hand with file and line:

```sh
dart pub global activate firestore_odm_builder
dart pub global run firestore_odm_builder:migrate           # preview
dart pub global run firestore_odm_builder:migrate --apply   # write
```

Your Firestore data stays as it is. The
[migration guide](https://sylphxai.github.io/firestore_odm/guide/migrate-from-cloud-firestore-odm)
maps every API.

## Documentation

- [Getting started](https://sylphxai.github.io/firestore_odm/guide/getting-started)
- [Schema and models](https://sylphxai.github.io/firestore_odm/guide/schema-definition)
- [Queries](https://sylphxai.github.io/firestore_odm/guide/filtering-data) and [pagination](https://sylphxai.github.io/firestore_odm/guide/pagination)
- [Writing documents](https://sylphxai.github.io/firestore_odm/guide/writing-documents)
- [Transactions](https://sylphxai.github.io/firestore_odm/guide/transactions) and [batches](https://sylphxai.github.io/firestore_odm/guide/batch-operations)
- [Aggregations](https://sylphxai.github.io/firestore_odm/guide/aggregations)
- [API reference](https://pub.dev/documentation/firestore_odm/latest/)

## Contributing

Issues and pull requests are welcome. See
[CONTRIBUTING.md](https://github.com/SylphxAI/firestore_odm/blob/main/CONTRIBUTING.md)
for the setup; `melos run check` runs what CI runs on a pull request.

## Also from Sylphx

- [anymd](https://github.com/SylphxAI/anymd): any file to clean Markdown for
  AI agents (PDF, Office, EPUB, web pages, images, audio, video); a Rust MCP
  server and CLI that runs locally.
- [repomap](https://github.com/SylphxAI/repomap): a map of your codebase for
  AI agents: code graph, search, call paths and change impact.
- [lockdocs](https://github.com/SylphxAI/lockdocs): exact-version library docs
  from your lockfile, local and offline.
- [readme-mark](https://github.com/SylphxAI/readme-mark): README banners,
  badges and stats cards from one URL (the banner above).

## Star history

[![Star history](https://api.star-history.com/svg?repos=SylphxAI/firestore_odm&type=Date)](https://star-history.com/#SylphxAI/firestore_odm&Date)

## License

[MIT](https://github.com/SylphxAI/firestore_odm/blob/main/LICENSE)
