# firestore_odm

A type-safe Firestore ODM for Flutter and Dart: annotations, a code generator
and a runtime that give Firestore collections typed queries, updates,
aggregates, transactions, batches and streams. The maintained successor to
`cloud_firestore_odm`, with a codemod to migrate from it.

## Scope

- Owns the three pub.dev packages, the generated API, the example, the
  documentation site (GitHub Pages) and the release workflow.
- Targets the client SDK (`cloud_firestore`) on the platforms it supports.
  Server and pure-Dart support is planned in phases, now that an official
  Dart Admin SDK exists (`firebase_admin_sdk`, `google_cloud_firestore`); see
  [docs/design/server-support.md](docs/design/server-support.md). Until it
  ships, the packages target Flutter only (#44).
- Does not own application schemas, Firebase projects or security rules.

## Delivery

- Required check: `ci-ok` (merge queue: fast lanes; full suite on a ready
  pull request and on main in `verify.yml`).
- Release: a `v<version>` tag on `main` publishes all three packages, waits
  until pub.dev serves each version, and creates the GitHub release.
- Docs: a push to `main` that touches `docs/` deploys
  https://sylphxai.github.io/firestore_odm/.
- Published versions cannot be withdrawn, so problems are fixed forward with a
  new version.
