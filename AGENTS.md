# firestore_odm

Goal: the type-safe Firestore ODM for Flutter and Dart, so a misspelled field or
wrong value type is a compile error and every call means exactly what
`cloud_firestore` means. Three pub.dev packages (`firestore_odm`,
`firestore_odm_annotation`, `firestore_odm_builder`) share one version and are
released by pushing a `v<version>` tag. [CONTRIBUTING.md](CONTRIBUTING.md) has
the layout, commands and release steps; [PROJECT.md](PROJECT.md) the scope;
[ADR 0002](docs/adr/0002-semantics-contract-v5.md) the semantics contract.

## Hard lines

- Test behaviour through the generated API in `apps/flutter_example/test`: a
  test that reads source text passes while the behaviour is broken.
- Code from a new builder must compile against the same-version runtime only,
  because builder and runtime ship together.
- Public text (README, docs site, dartdoc, changelog) uses plain customer
  terms, without decision-record numbers or internal jargon, because
  developers read it on pub.dev.
- Generated `*.g.dart` files are not committed; run `melos run generate`
  before analyzing or testing.

## Judged by

- `ci-success`: pull request runs format, generate, analyze, `melos run
  test:all`, API docs, publish dry run, pana score and the docs site build; the
  merge queue adds macOS/Windows tests and the emulator tests
  (`melos run test:e2e`).
- The fake Firestore does not model every query (for example filtering by a
  `DocumentReference`); cover those in `integration_test/`.
- `benchmarks/run.sh` for generation and runtime cost; `python3 brand/build.py
  --check` for brand files.
- A behaviour change carries a test and a package `CHANGELOG.md` line.
