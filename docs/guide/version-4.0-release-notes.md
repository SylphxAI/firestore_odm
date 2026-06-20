# Version 4.0 Release Notes

Firestore ODM 4.0 builds on 3.0's performance foundation with a **fully reworked
code generator**, broader type coverage, and ergonomic wins — while keeping the
schema, model, query, and update API you already write unchanged.

::: warning Breaking: cloud_firestore 6.x
4.0 requires **`cloud_firestore` 6.x** and **`firebase_core` 4.x** (was
cloud_firestore 5.x). The ODM's own query/CRUD/update API is unchanged — upgrade
those two dependencies in your app and re-run the generator. See *Upgrading*
below.
:::

## 🎉 What's New in 4.0

### 🔢 Enum support

Enums are now first-class. `@JsonValue` is honored for **both string and
numeric** values, enums work in `orderBy()`, and defaults are generated.

```dart
@JsonEnum()
enum AccountType {
  @JsonValue('free') free,
  @JsonValue('pro') pro,
  @JsonValue('enterprise') enterprise,
}

// Filter and order by enum fields, fully type-safe
final pros = await db.users
  .where(($) => $.accountType(isEqualTo: AccountType.pro))
  .orderBy(($) => $.accountType())
  .get();
```

### 🧩 Automatic nested-class imports

Filter, patch, aggregate, and `orderBy` selectors for **nested types** no longer
require you to manually import the nested classes — the generator wires up the
imports for you.

```dart
// `Profile` is nested inside `User`; no manual import of Profile needed
await db.users('jane').patch(($) => [
  $.profile.followers.increment(1),
  $.profile.bio.set('Updated bio'),
]);
```

### 🛡️ Stronger nullable & type handling

- Nullable `Map` fields are supported in updates and filters.
- Nested `fromJson` factories that accept a **nullable** map (e.g.
  `Address.fromJson(Map<String, Object?>? json)`) are now deserialized with a
  nullable cast, so reading a document where the field is absent no longer
  crashes with `type 'Null' is not a subtype of type 'Map<String, Object?>'`
  ([#5](https://github.com/SylphxAI/firestore_odm/issues/5)).
- Non-nullable enum fields resolve correctly (no spurious null assertions).

### ⏱️ Server timestamps on insert

`FirestoreODM.serverTimestamp` is now applied on **insert** operations (not only
updates) and is honored inside batches.

### 🧱 Batch & transaction patch builders

Atomic patch operations are available inside `runBatch` and `runTransaction`,
plus a `getBatchCollection()` convenience.

### 🏗️ Reworked code generator

The filter, patch, aggregate, and `orderBy` builders and the converters were
rebuilt on a unified `FieldPath` model, with a consolidated `TypeDefinition`
type. This is internal, but it produces cleaner generated code and a more
consistent foundation for future features.

### 🧪 Firestore Pipelines (experimental)

`collection.pipeline()` returns a type-safe `TypedPipeline<T>` over Firestore's
new Pipelines API:

```dart
final adults = await db.users
    .pipeline()
    .where(Field('age').greaterThanOrEqualValue(18))
    .sort(Field('age').descending())
    .limit(20)
    .execute(); // -> List<User>
```

> Pipelines are a **Firestore Enterprise edition** feature: one-shot
> `execute()` only (no realtime/offline), and **not supported by the emulator or
> `fake_cloud_firestore`**. This API is **experimental** and must be validated
> against a real Enterprise database. Design + roadmap:
> [ADR&nbsp;0001](https://github.com/SylphxAI/firestore_odm/blob/main/docs/adr/0001-firestore-pipelines.md),
> [#6](https://github.com/SylphxAI/firestore_odm/issues/6).

## ⚙️ Performance

The performance characteristics established in 3.0 are retained:

| Metric | Value |
|--------|-------|
| Runtime performance | ~20% faster than baseline |
| Generated code size | ~15% smaller |
| Compilation | Sub-second for complex schemas |
| Runtime overhead | Zero (all work at compile time) |

## ⬆️ Upgrading from 3.x

The ODM's own API is unchanged for typical usage (schema definition, models,
queries, `patch`/`modify`, transactions, batches). The one required change is
the **cloud_firestore 6.x / firebase_core 4.x** bump in your app:

```bash
dart pub add firestore_odm:^4.0.0
dart pub add dev:firestore_odm_builder:^4.0.0
dart pub add cloud_firestore:^6.4.0
dart pub add firebase_core:^4.0.0
dart run build_runner build --delete-conflicting-outputs
```

cloud_firestore 6.0 removed the deprecated persistence `Settings` toggles — use
`Settings.localCache` if you configured those. If you depended on ODM
internal-only classes (e.g. the removed `BatchField` / `BatchConfiguration`
helpers, or the internal `Node2` type), prefer the public
collection/document/patch-builder APIs instead.

## 🔭 What's next

- [Firestore Pipelines](https://github.com/SylphxAI/firestore_odm/issues/6): promote out of experimental once validated on Enterprise; add per-model typed selectors and the remaining stages
- Full map field filtering, ordering, and aggregation
- Nested map support
