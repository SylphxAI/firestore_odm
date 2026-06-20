# ADR 0001 — Firestore Pipelines support

- **Status:** Accepted (minimal slice shipped; full design pending)
- **Issue:** [#6](https://github.com/SylphxAI/firestore_odm/issues/6)
- **Depends on:** cloud_firestore ≥ 6.3.0 (shipped in 4.0.0-dev.5)

## Context

Firestore **Pipelines** are a server-side query API (GA 2026-04, Firestore
**Enterprise edition**) that runs documents through chained **stages**
(`collection → where → sort → limit → offset → aggregate → select → addFields →
distinct → unnest → union → findNearest → search → …`). They add JOINs,
aggregation filtering, array unnesting, vector and full-text search, etc., far
beyond the classic query engine.

`cloud_firestore` exposes them as:

```dart
firestore.pipeline()              // -> PipelineSource
  .collection('users')            // -> Pipeline
  .where(Field('age').greaterThanValue(18))
  .sort(Field('age').descending())
  .limit(10)
  .execute();                     // -> Future<PipelineSnapshot> { result: List<PipelineResult> }
```

### Hard constraints (shape the design)

1. **Enterprise edition only.** Running a pipeline against a Standard database
   is a server error.
2. **One-shot.** `execute()` only — no realtime listeners, no offline cache.
3. **Not testable in our suite.** `fake_cloud_firestore` and the emulator do
   **not** implement `pipeline()` (it throws). End-to-end behaviour can only be
   validated against a real Enterprise database. Our 503-test suite is
   fake-based, so pipeline *execution* is uncoverable in CI.
4. **Result rows are not documents.** A `PipelineResult` is a map (`data()`)
   plus an optional `document` ref — `select`/`aggregate` rows may have no
   document at all.

## Decision

Expose pipelines as a **separate, opt-in, execute-only surface** distinct from
the reactive `.get()/.stream()` query API — never wired into streaming or cache.

### Minimal slice (shipped in this PR)

A runtime wrapper, `TypedPipeline<T>`, reached via `collection.pipeline()`:

- Stages: `where(BooleanExpression)`, `sort(Ordering...)`, `limit(int)`.
- `execute()` → maps each `PipelineResult.data()` through the model's `fromJson`,
  injecting the row's document id into the model's document-id field when present.
- Expression building uses cloud_firestore's `Field('path')` API, re-exported
  from `firestore_odm` for convenience.
- Marked **experimental** in docs; covered by a compile-time type-safety test
  and a test asserting the fake throws (documenting the Enterprise requirement).

This is intentionally string-path (`Field('age')`) rather than fully
ODM-type-safe — see below.

### Maximal design (follow-up)

1. **Generated per-model field selectors.** Reuse the existing field analysis
   (the same source that powers filter/orderBy builders) to generate a typed
   selector so callers write `($) => $.age.gte(18)` / `($) => $.age.descending()`
   instead of `Field('age')...`. The selector emits the native
   `BooleanExpression`/`Ordering`. This is the bulk of the work: a new generator
   producing a `UserPipelineSelector` per model whose leaves know their field
   paths and types.
2. **Full stage coverage:** `offset`, `aggregate` (Count/Sum/Average/Min/Max…),
   `select`/`addFields`/`removeFields`, `distinct`, `unnest`, `union`,
   `findNearest` (vector), `search` (full-text). Aggregate/select rows return a
   projected shape, not `T`; model these as `TypedPipeline<T>.aggregate(...)
   → Future<List<Map>>` or generated projection types.
3. **Edition guard / docs:** surface a clear error/oc when run against a
   Standard database, and document the Enterprise + index requirements.

### Testing strategy

- **CI (fake):** compile-time type-safety of the builder + assert `pipeline()`
  is unsupported by the fake. (Done.)
- **Enterprise e2e:** a separate, opt-in integration lane against a real
  Enterprise database, gated so it never runs in the fake suite. Required before
  pipelines are promoted out of "experimental".

## Consequences

- Users on Standard edition are unaffected (the classic API is unchanged).
- The feature ships **experimental** until validated on Enterprise.
- cloud_firestore is now 6.x (4.0.0-dev.5), so the dependency is in place.
- Promoting pipelines to stable is **blocked on an Enterprise test environment**,
  not on code — tracked in #6.
