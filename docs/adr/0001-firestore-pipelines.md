# ADR 0001 - Firestore Pipelines support (type-safe)

- **Status:** Accepted; shipped.
- **Issue:** [#6](https://github.com/SylphxAI/firestore_odm/issues/6)
- **Depends on:** cloud_firestore 6.3.0 or later

## Context

Firestore Pipelines (Enterprise edition) run documents through chained stages.
`cloud_firestore` exposes a string-based, `Field('age')`-style API. This
library exists to remove string field paths and `Map<String, dynamic>`, so a
pipeline API built on `Field('age')` is rejected.

Constraints:

1. Enterprise edition only; running on Standard is a server error.
2. One-shot `execute()`, no realtime or offline.
3. `fake_cloud_firestore` and the emulator do not implement `pipeline()`, so
   CI covers compile-time type safety only; execution needs a real Enterprise
   database.
4. Result rows are maps (`PipelineResult.data()`) plus an optional document
   reference.

## Decision

A separate, execute-only surface built on the same `$.field` codegen as
`where`, `orderBy` and `aggregate`. Per non-generic model the builder generates
`<Model>PipelineSelector` (leaves are `PipelineField<T>`, nested objects are
nested selectors) and a `pipeline()` extension on the model's collection. The
runtime type is `TypedPipeline<T, S>`.

Stages that keep the row type return `T`:

```dart
final adults = await db.users
    .pipeline()
    .where(($) => $.age(isGreaterThanOrEqualTo: 18))
    .where(($) => $.profile.followers(isGreaterThan: 100))
    .sort(($) => $.age.descending())
    .limit(20)
    .execute();                                         // -> List<User>
```

Stages that change the row shape (`select`, `aggregate`) return typed records,
using the same two-pass replay as the `aggregate` subsystem:

```dart
final rows = await db.users.pipeline()
    .select(($) => (name: $.name.value, years: $.age.value))
    .execute();                                         // -> List<({String name, int years})>

final stats = await db.users.pipeline()
    .where(($) => $.isActive(isEqualTo: true))
    .aggregate(($) => (count: $.count(), avgAge: $.age.average()));
```

1. A capture pass runs the record builder with a capture context; leaves record
   an aliased expression and return a dummy value, and the captured list builds
   the native `select` or `aggregate` stage.
2. A result pass re-runs the same builder per row, where leaves return
   `row[alias]` coerced to the static type.

Details: aliases are deterministic per field and operation (`sum_age`,
`avg_age`, `count_all`), so the same field and operation twice in one stage
collides. Firestore returns `num`, which is coerced to `int` or `double`.
`select` ends the chain, and generic models have no pipeline surface.

## Testing

CI checks compile-time type safety of the typed builder and that the fake
rejects `pipeline()`. Runtime behaviour of the stages needs a real Enterprise
database, which CI does not have.
