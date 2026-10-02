# Design: server and pure-Dart support

- **Status:** Proposed (decision document from a design spike; no production code).
- **Issue:** [#44](https://github.com/SylphxAI/firestore_odm/issues/44), closed "not planned" with this reassess condition: "If a supported Dart server SDK for Firestore appears, open a new issue."
- **Recommendation:** GO, phased, with a gate before the public server package (see [Recommendation](#recommendation)).

All figures below were read on 2026-10-02 from pub.dev, the upstream repositories and this repository at `6cc1b14`.

## Why reopen now

`PROJECT.md` and `docs/guide/introduction.md` say there is no Admin SDK to target. That premise is stale. The Firebase organisation now publishes an official Dart Admin SDK:

- `firebase_admin_sdk` 0.5.6 (published 2026-09-21), publisher `firebase.google.com`, repository `firebase/firebase-admin-dart`. It supersedes the Invertase `dart_firebase_admin`, which is marked discontinued on pub.dev with `replacedBy: firebase_admin_sdk`.
- `google_cloud_firestore` 0.5.5 (published 2026-09-21), same repository, usable standalone or through `FirebaseApp.firestore()`. Its first release was 2026-04-14; it has had 6 releases.

Both pass pub.dev's maximum 160 points. The repository was pushed to on the day of this readback.

## Options surveyed

Download counts are pub.dev `downloadCount30Days` (from `/api/packages/<name>/score`).

| Package | Version / last release | 30-day downloads | Fit |
|---|---|---|---|
| `google_cloud_firestore` | 0.5.5, 2026-09-21 | 21,354 | **Best target.** Official, gRPC-free HTTP/2 client over `google_cloud_firestore_v1`, ADC and service accounts, emulator host, bulk writer, transactions, batches, aggregates (count/sum/avg), pipelines. |
| `firebase_admin_sdk` | 0.5.6, 2026-09-21 | 17,463 | Wraps the package above (Firestore, Storage, Auth, FCM). Same Firestore API; users reach it via `app.firestore()`. Not a separate backend. |
| `dart_firebase_admin` | 0.4.1, 2025-03-21 | 5,932 | Discontinued, unlisted, replaced by `firebase_admin_sdk`. Rejected. |
| `googleapis` (firestore/v1) | 17.0.0, 2026-08-24 | 1,238,375 (whole package, all Google APIs) | Raw generated REST client: no documents-to-Dart-values mapping, no query builder, no transactions helper. Would mean writing our own SDK. Rejected. |
| `firedart` | 0.9.8, 2024-03-15 | 2,956 | Client-style (end-user auth, security rules apply), gRPC, no release in 2.5 years. Wrong trust model for servers. Rejected. |
| `firebase_dart` | 1.6.2, 2026-03-27 | 9,507 | Pure-Dart client port (Auth, RTDB, Storage); no Firestore. Not an option. |
| `cloud_firestore` for desktop | none | n/a | There is no `cloud_firestore_desktop` package (pub.dev API returns 404). `cloud_firestore` itself covers Windows and macOS (Linux is not supported), and it is Flutter-only. Desktop is already in scope today; Linux/server is not. |
| `fire_api` | 1.7.4, 2026-04-16 | 352 | Third-party interface shim over Firestore backends (the same idea as our adapter, but string-keyed). Evidence the seam is workable; not a dependency candidate. |

## Market evidence

Server-side Dart Firestore demand, measured by pub.dev 30-day downloads:

| Package | 30-day downloads |
|---|---|
| `cloud_firestore` (Flutter client) | 1,261,846 |
| `google_cloud_firestore` (server) | 21,354 |
| `firebase_admin_sdk` (server) | 17,463 |
| `firestore_odm` (ours) | 325 |
| `dart_frog` (server framework) | 150,552 |
| `serverpod` (server framework) | 97,025 |

Reading:

- Server Firestore is about 1.7% of the client SDK's volume. It is small, not zero, and the official SDK is five months old and still pre-1.0, so the figure is a floor that was reached while the API is moving.
- `dart_firebase_admin` peaked below 6k, so the new SDK has about 3.5x the old demand within five months of the first `google_cloud_firestore` release. Downloads include CI and resolver traffic and are not unique users.
- The 325 downloads of `firestore_odm` show the Flutter segment is also still being won. A server target does not replace that work; it reaches a segment the typed-ODM competitors (`cloud_firestore_odm`, Flutter-only) cannot.
- Server frameworks (`dart_frog` 150k, `serverpod` 97k) show the Dart server audience exists and mostly talks to Postgres; Firestore from Dart servers is a niche inside it.

Conclusion on demand: weak as a revenue-grade market today; the argument for acting is that the official SDK removes the original blocker and the shared-model story (one `@Collection` model for the Flutter app and its Cloud Run/Functions backend) is unique to us.

## How the code depends on cloud_firestore today

Counts from `packages/firestore_odm/lib/src` (3,421 lines in 21 files):

- 16 files import `package:cloud_firestore`: `aggregate`, `batch`, `exceptions`, `field_selector`, `filter_builder`, `firestore_collection`, `firestore_document`, `firestore_odm`, `model_converter`, `orderby`, `pagination`, `patch`, `pipeline`, `query`, `transaction`, `utils`. One more, `firestore_builder.dart`, imports `package:flutter/widgets.dart` (a `StreamBuilder`-style widget).
- About 90 `firestore.X` references across them. By frequency: `Query` 19, `Pipeline` 8, `Filter` 8, `Ordering` 5, `FieldValue` 5, `Field` 5, `DocumentReference` 5, `DocumentSnapshot` 4, `GetOptions` 3, `PipelineAggregateFunction` 3, `FieldPath`, `AggregateQuery`, `CollectionReference`, `Selectable`, `ExecuteOptions`, `BooleanExpression`, `AliasedAggregateFunction` 2 each; one each of `runTransaction`, `Transaction`, `WriteBatch`, `QuerySnapshot`, `Timestamp`, `PipelineResult`, `AggregateField`, `count`, `sum`, `average`.
- Stream entry points are exactly two: `FirestoreDocument.stream` (`ref.snapshots()`) and `FirestoreQuery.stream` (`_query.snapshots()`).
- Backend entry: `FirestoreODM(schema, {FirebaseFirestore? firestore})` defaulting to `FirebaseFirestore.instance`, and `runTransaction`/`batch` delegating to it.
- Value types leaking into user models: `model_converter.dart` passes `Blob` and `GeoPoint` through unchanged, `Timestamp` is mapped to `DateTime` natively, `DocumentReference` and `FieldValue` (server timestamp, increment, array ops) appear in generated patch code.
- Builder: `firestore_odm_builder` has no Flutter or cloud_firestore dependency in its pubspec. It names cloud_firestore types only as emitted symbols, in `utils/reference_utils.dart` (`Timestamp`, `GeoPoint`, `DocumentReference`) and in type detection (`type_analyzer.dart`, `model_analyzer.dart`: "starts with `package:cloud_firestore`"). `firestore_odm_annotation` is also Flutter-free in code, but both advertise the `flutter` topic and are fine as they are.
- Packaging: `firestore_odm/pubspec.yaml` declares `flutter: sdk` and `flutter_test`, so a pure-Dart project cannot resolve it (the blocker quoted in #44).

## Does a thin adapter work?

The server SDK covers the operations the runtime actually calls. Read from `google_cloud_firestore`'s source at `main`:

| ODM need | cloud_firestore | google_cloud_firestore | Parity |
|---|---|---|---|
| get / set / update / delete, `SetOptions` | yes | yes | yes |
| Query: where/Filter, orderBy, limit, cursors (`startAfter`, `endBefore`, `...Document`) | yes | yes | yes |
| `limitToLast` | yes | yes (Node-style) | verify at implementation |
| Aggregates count/sum/avg | yes | `count()` and aggregate query | verify sum/avg types |
| Batches | `WriteBatch` | `WriteBatch`, plus `BulkWriter` | yes |
| Transactions | `runTransaction` | `runTransaction` with retry and backoff | yes; read-before-write rule is the same, our deferred-write context already enforces it |
| `withConverter` | yes | yes | not needed, ODM converts itself |
| Pipelines | `Query.pipeline()` family | `Firestore.pipeline()`, `PipelineFunctions` | different surface; separate adapter |
| **Realtime `snapshots()`** | yes | **no** (`document_reference.dart:234`: `// TODO snapshots`) | **gap** |
| Offline persistence, `Source.cache` | yes | n/a | not applicable to servers |
| `Timestamp`, `GeoPoint`, `FieldValue`, `FieldPath`, `DocumentReference` | cloud_firestore classes | google_cloud_firestore classes | same names, **different types**; not interchangeable |

An interface of about 12 members would cover it:

```dart
abstract interface class OdmBackend {
  OdmCollection collection(String path);
  OdmCollection collectionGroup(String id);
  Future<T> runTransaction<T>(Future<T> Function(OdmTransaction) body);
  OdmBatch batch();
}
// OdmCollection/OdmQuery: where, orderBy, limit, cursors, get, count/sum/avg
// OdmDocument: get, set, update, delete (+ optional stream())
// FieldValue helpers: serverTimestamp, increment, arrayUnion, arrayRemove, delete
```

### Size estimate

- Phase 1 refactor touches the 16 files above: roughly 90 references replaced by adapter types. Behaviour must not change. Roughly 1,500 changed lines, mostly mechanical, in the first PR plus a cloud_firestore adapter of 300 to 500 lines.
- A server adapter over `google_cloud_firestore`: 400 to 700 lines plus the value-type mapping layer.
- Builder: the emitted `Timestamp`/`GeoPoint`/`DocumentReference`/`FieldValue` symbols must come from the adapter's own value types (or from a re-export chosen by import), a change to `reference_utils.dart`, `type_analyzer.dart`, `model_analyzer.dart` and the three generators (about 7 files).
- Packaging: new `firestore_odm_core` (pure Dart: schema, query/patch builders, converters, exceptions), with `firestore_odm` becoming the Flutter facade (adapter + `FirestoreBuilder`) and a new `firestore_odm_server` package.
- Tests: the Firestore emulator job already runs on merge; server tests run the same suite against `FIRESTORE_EMULATOR_HOST` with the server adapter, which `google_cloud_firestore` supports.

I did not build the prototype beyond the inventory above; the estimate comes from reading call sites, not from compiling an adapter.

## Risks

1. **Type-safety parity.** Our guarantee is that the generated API has no string field paths and no `Map<String, dynamic>` in user code. That lives in the builder and the runtime builders, not in cloud_firestore, so it is preserved if value types are abstracted. The risk is value types: a model with a `Timestamp`, `GeoPoint` or `DocumentReference` field is bound to one SDK's class. Mitigation: keep `DateTime` as the model type for timestamps (already the default), and own `GeoPoint`/`Blob`/`DocumentRef` as ODM-level wrappers converted at the adapter boundary. This is a source-breaking change for users with `GeoPoint` fields in the Flutter package unless the Flutter facade keeps re-exporting the cloud_firestore types, which it should.
2. **Transactions.** Semantics match (reads first, then writes, automatic retry). The server SDK retries with backoff itself; our `TransactionContext` caches snapshots and flushes writes after the callback, which is backend-neutral. Risk is limited to error mapping (`FirebaseException` vs `FirestoreException`), handled in `exceptions.dart`. Server transactions are pessimistic locks while the client SDK's are optimistic, so contention behaviour differs and needs documentation.
3. **Streams on the server.** `google_cloud_firestore` has no listeners today, and server usage (Cloud Run, Functions) rarely wants them. Server package should omit `.stream` at the type level (it is a separate package, so the API is simply absent) rather than throw. If upstream adds `snapshots()`, wire it then. Do not emulate with polling.
4. **Upstream maturity.** Both server packages are 0.x with weekly releases; the Firestore package is five months old with 8 likes. Breaking changes between 0.x minors are likely. Pin a narrow range and run emulator tests against upstream `main` in a scheduled job.
5. **Pipelines.** ADR 0001's typed pipelines wrap cloud_firestore's `Field('x')` API. The server SDK has a different but Node-shaped pipeline API. Treat as a later, separate adapter; do not block the first server release on it.
6. **Maintenance load.** The project is in the Maintain lifecycle. Splitting into three packages triples release surface (the release workflow already publishes three, so it would publish four) and doubles the CI matrix for the shared core.
7. **Cannot be tested here against live Firestore.** Only the emulator is available to CI; Enterprise-edition features (pipelines) cannot be covered, as with ADR 0001.

## Recommendation

**GO, phased.** The original reason to refuse (no official Dart Admin SDK) no longer holds, the seam is real but small (about 16 files, about 90 references, 2 stream entry points), and nothing else offers typed Firestore models shared between a Flutter app and its Dart backend. Demand is modest, so each phase is independently shippable and later phases are gated.

1. **Phase 0: correct the record (one docs PR, no code).** Update `PROJECT.md` and `docs/guide/introduction.md` to say an official Dart Admin SDK exists and that server support is planned and evaluated, linking this document. Reopen or replace #44 with a new issue per its own closing comment.
2. **Phase 1: extract the seam (one refactor PR, no behaviour change).** Introduce the `OdmBackend` interface and a cloud_firestore adapter; move the 16 files onto it; keep the public API and generated output unchanged. The existing unit, emulator and benchmark jobs are the safety net, and the ratcheting benchmark must not regress. Value types stay cloud_firestore's in the Flutter package.
3. **Phase 2: pure-Dart core and server package.** Split `firestore_odm_core`, add `firestore_odm_server` backed by `google_cloud_firestore` (get, queries, writes, batches, transactions, aggregates; no streams, no pipelines), run the emulator suite against it, document it as experimental.
4. **Phase 3, gated: stabilise.** Do this only if, at that point, `google_cloud_firestore` has reached 1.0 or its 30-day downloads exceed about 50,000, and the package has user issues asking for it. Otherwise stop after Phase 2 and keep it experimental. Pipelines and streams wait on upstream.

Stop condition: if Phase 1 cannot keep generated output byte-identical and benchmarks flat, abandon it; nothing in Phase 0 depends on it.
