# Firestore ODM Project

Firestore ODM is a production Dart/Flutter package ecosystem for type-safe
Firestore access through annotations and code generation. It publishes
`firestore_odm`, `firestore_odm_annotation`, and `firestore_odm_builder`.

## Goals

- Own Firestore ODM annotations, runtime package, builder package, generated API
  semantics, example app, documentation, CI, and pub.dev release workflow.
- Keep Firestore data access type-safe, generated, benchmarked, and compatible
  with supported Dart/Flutter versions.
- Publish packages only with CI, dry-run/publish proof, pub.dev readback, and
  documentation evidence.

## Non-Goals

- Do not own downstream app schemas, Firebase projects, Firestore security
  rules, or tenant data models.
- Do not encode app-specific Firestore behavior into the generic ODM.
- Do not rely on source revert for already-published pub.dev packages.

## Boundaries

Owned contexts are the annotation package, runtime package, builder package,
generated code contract, example app, docs, package versions, and release
workflow. Downstream apps consume only pub.dev packages and documented APIs.

Public surfaces:

- pub.dev packages under `packages/*/pubspec.yaml`.
- Documentation under `docs/` and GitHub Pages.
- Required contexts `quality`, `security`, `docs`, `performance`, `coverage`,
  and `ci-success`.
- Release workflow `.github/workflows/release.yml`.

## Delivery

Current CI model: `legacy-ci`. Required contexts are `quality`, `security`,
`docs`, `performance`, `coverage`, and `ci-success`.

Release path: tag or manual release workflow dry-runs/publishes packages to
pub.dev, creates a GitHub release, and verifies publication. Production proof
must include required CI, dry-run/publish output, pub.dev readback, docs
readback, and generated-code smoke tests.

Recovery class: `forward-fix-only`, because pub.dev package versions and
generated downstream APIs cannot be fully undone by source revert.

## References

- Public docs: `docs/README.md`
- Package manifests: `packages/*/pubspec.yaml`
- CI: `.github/workflows/ci.yml`
- Release: `.github/workflows/release.yml`
