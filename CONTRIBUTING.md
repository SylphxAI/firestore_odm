# Contributing

Issues and pull requests are welcome. For a bug, include the model, the
generated code or the error, and the versions of firestore_odm,
cloud_firestore and Flutter.

## Setup

You need Flutter 3.44 (the version CI pins in
`.github/actions/setup-flutter/action.yml`).

```sh
git clone https://github.com/SylphxAI/firestore_odm.git
cd firestore_odm
dart pub global activate melos
melos bootstrap
melos run check      # format, generate, analyze, test: what the pull request check runs
```

## Layout

| Path | What it is |
| --- | --- |
| `packages/firestore_odm` | runtime: collections, queries, updates, transactions, batches |
| `packages/firestore_odm_annotation` | `@firestoreOdm`, `@Schema`, `@Collection`, `@DocumentIdField` |
| `packages/firestore_odm_builder` | the code generator, and the `migrate` codemod (`bin/migrate.dart`) |
| `packages/firestore_odm/example` | the README example, tested |
| `apps/flutter_example` | models covering every supported shape, and the test suite (in-memory Firestore in `test/`, Firestore emulator in `integration_test/`) |
| `benchmarks` | code generation and runtime benchmarks (`benchmarks/run.sh`) |
| `docs` | the documentation site (VitePress) |

## Commands

| Command | Does |
| --- | --- |
| `melos run generate` | runs build_runner wherever it is used |
| `melos run analyze` | static analysis of the packages (after `generate`) |
| `melos run test:all` | codemod unit tests and the generated-code tests |
| `melos run test:e2e` | tests against the Firestore emulator (needs Java 21 and Node) |
| `benchmarks/run.sh` | benchmarks; prints a Markdown report |
| `cd docs && npm ci && npm run dev` | the documentation site with live reload |

A behaviour change comes with a test in `apps/flutter_example/test` that calls
the generated API, and a line in the package `CHANGELOG.md`.

## CI

Pull requests run format, analysis, tests, API docs, the publish dry run, the
pub.dev score check and the docs site build, on our own Linux runners. The
macOS and Windows tests and the emulator tests (a Windows desktop app) are off
until we host those systems. `ci-success` is the required check.

## Releasing

The three packages share one version.

1. Set `version:` in the three `pubspec.yaml` files and
   `firestoreOdmConstraint` in
   `packages/firestore_odm_builder/lib/src/migrate/cloud_firestore_odm_migration.dart`.
   Raise the `firestore_odm_annotation` constraints only when the release
   needs new annotation API (the pub.dev score check resolves dependencies
   from pub.dev, so an unpublished constraint fails it until release).
2. Add the version's section to each package `CHANGELOG.md`; merge.
3. Tag the merged commit: `git tag v5.1.0 && git push origin v5.1.0`.

The Release workflow checks the tag matches the versions and is on `main`,
publishes the annotation, runtime and builder packages in that order, waits
until pub.dev serves each version, and creates the GitHub release from the
changelog. It publishes through pub.dev automated publishing (GitHub OIDC),
which each package's pub.dev admin page must allow for this repository with
the tag pattern `v{{version}}`; until then it uses the `PUB_CREDENTIALS`
secret.
