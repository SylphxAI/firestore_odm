# Bulk Operations

Bulk writes apply to every document matching a query and are **chunked** to
Firestore's 500-write batch limit (ADR-0002) — never one unbounded batch.

## patchAll

Applies the same typed patch operations to every match:

```dart
await db.users
  .where(($) => $.isActive(isEqualTo: true))
  .patchAll([SetOperation(const FieldNode(components: ['archived']), true)]);
```

## deleteAll

Deletes every match (chunked):

```dart
await db.users
  .where(($) => $.isActive(isEqualTo: false))
  .deleteAll();
```

> For Enterprise-edition users, Firestore Pipelines provide server-side bulk
> update/delete stages (experimental surface, ADR-0001/0002) — the ODM's typed
> pipeline API is the supported path there.
