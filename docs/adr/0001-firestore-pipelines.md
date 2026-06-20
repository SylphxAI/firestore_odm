# ADR 0001 — Firestore Pipelines support (type-safe)

- **Status:** Accepted — fully type-safe pipeline API implemented
  (`where`/`sort`/`limit` + `select`/`aggregate`). Compile-time verified;
  **runtime behaviour pending Enterprise-database validation** (uncoverable by
  the fake suite).
- **Issue:** [#6](https://github.com/SylphxAI/firestore_odm/issues/6)
- **Depends on:** cloud_firestore ≥ 6.3.0 (shipped in 4.0.0)

## Context

Firestore **Pipelines** (GA 2026-04, **Enterprise edition**) run documents
through chained stages. `cloud_firestore` exposes a string-based,
`Field('age')`-style API.

**Non-negotiable for this project:** firestore_odm exists to eliminate string
field paths and `Map<String,dynamic>` — everything is type-safe via codegen
(`$.profile.followers`, typed values, `User` results). A pipeline API built on
`Field('age')` (as an earlier experimental slice was) **directly contradicts the
library's reason to exist** and is rejected.

### Hard constraints

1. **Enterprise edition only**; running on Standard is a server error.
2. **One-shot** `execute()` — no realtime/offline.
3. **Not testable in our suite.** `fake_cloud_firestore` and the emulator do not
   implement `pipeline()` (it throws). Pipeline **execution is uncoverable in
   CI** — only compile-time type-safety is. Anything beyond that needs a real
   Enterprise database.
4. Result rows are maps (`PipelineResult.data()`) + an optional `document` ref.

## Decision

A separate, execute-only surface, **fully type-safe via the same `$.field`
codegen used by `where`/`orderBy`/`aggregate`** — never string paths.

### Implemented (this line)

Per non-generic model the builder generates `<Model>PipelineSelector` (leaves =
`PipelineField<T>` carrying their `FieldPath` + `toJson`; nested objects = nested
selectors) and a covariant `pipeline()` extension on the model's
`FirestoreCollection`. Runtime `TypedPipeline<T, S>`:

```dart
final adults = await db.users
    .pipeline()
    .where(($) => $.age(isGreaterThanOrEqualTo: 18))   // typed value, no strings
    .where(($) => $.profile.followers(isGreaterThan: 100))
    .sort(($) => $.age.descending())
    .limit(20)
    .execute();                                         // -> List<User>
```

These **preserve the row type `T`**, so they map straight back through the
model's `fromJson`. This is the verified foundation (compile-time tests; full
suite green).

### Implemented — shape-changing stages (`select`, `aggregate`)

These change the row shape, so the result is **not `T`** — they return **typed
Dart records** via dual-phase replay, mirroring the existing `aggregate`
subsystem (`AggregateBuilderContext` vs `AggregateResultContext`):

```dart
// projection -> List of typed records
final rows = await db.users.pipeline()
    .select(($) => (name: $.name.value, years: $.age.value))   // -> List<({String name, int years})>
    .execute();

// aggregation -> a typed record
final stats = await db.users.pipeline()
    .where(($) => $.isActive(isEqualTo: true))
    .aggregate(($) => (count: $.count(), avgAge: $.age.average()));  // -> ({int count, double avgAge})
```

Mechanism:
1. The selector becomes context-capable (a factory `S Function(PipelineContext?)`
   passed to `TypedPipeline`, like the aggregate selector takes a context).
2. **Capture pass:** run the record-builder with a capture context; leaves record
   `AliasedExpression`/`AliasedAggregateFunction` under a deterministic alias and
   return `defaultValue<T>()` dummies; the captured list builds the native
   `select`/`aggregate` stage.
3. **Result pass:** for each result row, re-run the same builder with a row
   context where leaves return `row[alias]` (coerced to the static type); the
   record literal in the lambda reassembles the typed record.

Implementation notes / known limits (compile-verified; validate on Enterprise):
- **Aliasing** is deterministic per (field, op) — `sum_age`, `avg_age`,
  `count_all`, and the field path for projections. Projecting/aggregating the
  **same field+op twice** would collide; revisit with order-based aliases if a
  use case needs it.
- **Numeric coercion**: Firestore returns `num`; values are coerced to the
  static record-field type (`int`/`double`), mirroring `AggregateResultContext`.
- **Native API mapping**: `Field.sum()/average()/minimum()/maximum()/count()` →
  `PipelineAggregateFunction`; count-all via `CountAll`; `Field.alias()` for
  projections; fanned out to the positional `aggregate()/select()` API (≤8 for
  now).
- `select` is currently terminal (`.execute()` → `List<record>`); chaining
  further stages after a projection is a follow-up.

### Runtime verification gap

`where/sort/limit` are exercised by compile-time tests; `select/aggregate` are
**compile-time type-checked only** — their replay/aliasing/coercion runtime
behaviour cannot be exercised by `fake_cloud_firestore` (no pipeline engine) and
**must be validated against a real Enterprise database** before this leaves
"experimental".

## Testing strategy

- **CI (fake):** compile-time type-safety of the typed builder + a test asserting
  the fake rejects `pipeline()`. (Done.)
- **Enterprise e2e:** an opt-in lane against a real Enterprise database — required
  before promoting pipelines (and before shipping the shape-changing stages) out
  of "experimental".

## Consequences

- Standard-edition users are unaffected; the classic typed API is unchanged.
- The whole typed surface (`where/sort/limit/select/aggregate`) honours the
  type-safety promise — no string field paths — and ships experimental.
- `select`/`aggregate` are implemented (typed records) but compile-verified only;
  promoting pipelines out of "experimental" is gated on Enterprise validation —
  tracked in #6.
- Generic models don't yet get a pipeline surface (the selector + collection
  type would need the type parameters threaded through) — follow-up.
