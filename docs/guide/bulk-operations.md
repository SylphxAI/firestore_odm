# Bulk Operations

Bulk writes apply to every document matching a query and are **chunked** to
Firestore's 500-write batch limit (ADR-0002) — never one unbounded batch.

## patchAll

Applies the same typed patch operations to every match. Use the generated model
patch builder so serialization stays aligned with the model contract:

```dart
final archived = UserPatchBuilder().isArchived.set(true);

await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .patchAll([archived]);
```

## deleteAll

Deletes every match (chunked):

```dart
await db.users
  .where(($) => $.isActive(isEqualTo: false))
  .deleteAll();
```

> Firestore Pipelines remain an experimental, Enterprise-gated surface. The
> normal `patchAll` and `deleteAll` APIs read the matching references and commit
> chunks of at most 500 writes.
