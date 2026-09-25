# Comparison

How firestore_odm compares with the official `cloud_firestore_odm` and with
raw `cloud_firestore` typed through `withConverter`. Versions: firestore_odm
5.1, cloud_firestore_odm 1.0.0-dev.88 (its last release), cloud_firestore 6.

| | firestore_odm | cloud_firestore_odm | raw cloud_firestore |
| --- | --- | --- | --- |
| Last release | 2026 | October 2024 (pre-release) | current |
| Works with cloud_firestore 6 / firebase_core 4 | yes | no (`cloud_firestore ^5`) | yes |
| Works with current analyzer, freezed 3, json_serializable | yes | no (`analyzer <7`, `freezed_annotation <3`) | yes |
| Typed filters | `where(($) => $.age(isGreaterThan: 18))` | `whereAge(isGreaterThan: 18)` | string field names |
| OR / AND filters | typed, `a \| b`, `a & b` | no | `Filter.or`, string field names |
| Nested field filters and updates | `$.profile.followers` | top-level fields only | string paths |
| Typed ordering and cursors | record-typed: `orderBy(($) => ($.age(), $.name())).startAfter((30, 'Kim'))` | per-field arguments | untyped values |
| Typed full write | `set(user)`, `create(user)` returns the id | `add` only; `set` through `.reference` | via `withConverter` |
| Typed partial update | `patch(($) => [$.name.set('Kim'), $.age.increment(1)])` | `update(name: 'Kim', ageFieldValue: FieldValue.increment(1))` | `Map<String, dynamic>` |
| Aggregates (count, sum, average) | typed record: `aggregate(($) => (n: $.count(), avg: $.age.average()))` | no | untyped |
| Transactions | typed get/set/patch/delete, writes deferred after reads | `transactionGet`, `transactionUpdate` | untyped |
| Batches | typed set/patch/delete | `batchUpdate` | untyped |
| Update or delete every match of a query | `patchAll`, `deleteAll` (chunked to 500 writes) | no | by hand |
| Subcollections | typed, `odm.usersPosts(userId)` | typed, `ref.doc(id).posts` | untyped |
| Streams | `stream` of models | `snapshots()` of snapshot wrappers | snapshots |
| Cache or server reads (`GetOptions`) | yes | yes | yes |
| Snapshot metadata | through the native reference (`ref`, `nativeQuery`) | yes | yes |
| Models | plain classes, freezed, json_serializable | json_serializable required | any |
| GeoPoint, DocumentReference, Blob, Timestamp fields | stored natively | with json converters | native |
| Firestore Pipelines (Enterprise edition) | typed, experimental | no | untyped |
| Flutter widget | use `StreamBuilder` | `FirestoreBuilder` | use `StreamBuilder` |
| Field validators | no (validate in the constructor) | `@Min`, `@Max` | no |
| Migration tool | [codemod from cloud_firestore_odm](/guide/migrate-from-cloud-firestore-odm) | | |

Code generation and runtime cost are measured in [Benchmarks](/guide/benchmarks).

## Other Firestore packages on pub.dev

| Package | Latest release | cloud_firestore | What it is |
| --- | --- | --- | --- |
| [firestore_ref](https://pub.dev/packages/firestore_ref) | 0.16 (2026) | 6 | typed reference and document helpers; queries use field names |
| [firestorm](https://pub.dev/packages/firestorm) | 1.0 (2026) | 6 | object mapper for Firestore and Realtime Database, with code generation |
| [dogs_firestore](https://pub.dev/packages/dogs_firestore) | 0.3 (2026) | 5 | Firestore adapter for the dogs object mapper |
| [flamingo](https://pub.dev/packages/flamingo) | 3.0 (2023) | 4 | model framework; no release since 2023 |
