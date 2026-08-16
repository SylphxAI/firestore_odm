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

Current CI model: agent-native Fast Trunk on Sylphx self-hosted runners. The
workflow checks `quality`, `test`, `security`, `docs`, `coverage`, and
`ci-success`; `performance` runs on pull requests, while the emulator lane is
visibility-only in CI and an authoritative release gate.

Release path: a tag or manual release workflow runs the emulator gate, enforces
stable package versions, dry-runs and publishes the three packages to pub.dev,
then verifies each exact version endpoint. A tag also creates the GitHub
release. This repository has no hosted application or serverless runtime;
Platform deploy/health surfaces are not part of its delivery boundary.

Production proof must keep source, CI, release, and live layers distinct:
required CI, release-gate e2e, dry-run/publish output, exact pub.dev readback,
and generated-code smoke tests are required for a package release. Documentation
is checked in CI; a docs-site live claim requires separate readback.

Recovery class: `forward-fix-only`, because pub.dev package versions and
generated downstream APIs cannot be fully undone by source revert.

## References

- Public docs: `docs/README.md`
- v5 semantics contract: `docs/adr/0002-semantics-contract-v5.md`
- Package manifests: `packages/*/pubspec.yaml`
- CI: `.github/workflows/ci.yml`
- Release: `.github/workflows/release.yml`
