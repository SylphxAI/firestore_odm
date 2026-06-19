# Version 4.0 Release Notes

Firestore ODM 4.0 builds on 3.0's performance foundation with a **fully reworked
code generator**, broader type coverage, and ergonomic wins — while keeping the
schema, model, query, and update API you already write unchanged.

::: info Pre-release
4.0 is currently published as a pre-release (`4.0.0-dev`). The current stable
line is 3.x. There are no intentional breaking changes to the public API;
4.0 is primarily new capabilities plus a large internal refactor.
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

## ⚙️ Performance

The performance characteristics established in 3.0 are retained:

| Metric | Value |
|--------|-------|
| Runtime performance | ~20% faster than baseline |
| Generated code size | ~15% smaller |
| Compilation | Sub-second for complex schemas |
| Runtime overhead | Zero (all work at compile time) |

## ⬆️ Upgrading from 3.x

The public API is unchanged for typical usage (schema definition, models,
queries, `patch`/`modify`, transactions, batches). Upgrade by bumping the
dependency and re-running the generator:

```bash
dart pub add firestore_odm:^4.0.0-dev
dart pub add dev:firestore_odm_builder:^4.0.0-dev
dart run build_runner build --delete-conflicting-outputs
```

If you depended on internal-only classes (e.g. the removed `BatchField` /
`BatchConfiguration` helpers, or referenced the internal `Node2` type), prefer
the public collection/document/patch-builder APIs instead.

## 🔭 What's next

- [Firestore Pipelines support](https://github.com/SylphxAI/firestore_odm/issues/6)
- Full map field filtering, ordering, and aggregation
- Nested map support
