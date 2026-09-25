# firestore_odm

A type-safe Firestore ODM for Flutter and Dart: annotations, a code generator
and a runtime that give Firestore collections typed queries, updates,
aggregates, transactions, batches and streams. The maintained successor to
`cloud_firestore_odm`, with a codemod to migrate from it.

## Scope

- Owns the three pub.dev packages, the generated API, the example, the
  documentation site (GitHub Pages) and the release workflow.
- Targets the client SDK (`cloud_firestore`) on the platforms it supports.
  The Firebase Admin SDK and pure-Dart servers are not targets (#44).
- Does not own application schemas, Firebase projects or security rules.

## Delivery

- Required check: `ci-success` (pull request: Linux checks; merge queue:
  macOS/Windows tests and Firestore emulator tests).
- Release: a `v<version>` tag on `main` publishes all three packages, waits
  until pub.dev serves each version, and creates the GitHub release.
- Docs: a push to `main` that touches `docs/` deploys
  https://sylphxai.github.io/firestore_odm/.
- Published versions cannot be withdrawn, so problems are fixed forward with a
  new version.
