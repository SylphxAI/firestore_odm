# Agent Instructions

Engineering doctrine: https://github.com/SylphxAI/doctrine

Before changing behavior, read `PROJECT.md`, `.doctrine/project.json`, the
central doctrine entry points, and triggered doctrine standards. This file is a
thin runtime adapter; keep enterprise policy in doctrine.

## Local Commands

- `melos bootstrap` - bootstrap workspace packages.
- `melos run check --no-select` - format, analyze, and tests.
- `melos run publish:dry-run --no-select` - validate pub.dev publishability.
- `melos run generate` - generate code where needed.

## Local Hazards

- Firestore ODM is a public Dart/Flutter code-generation package ecosystem.
  Builder output, annotations, generated APIs, and Firestore write semantics are
  public contracts.
- pub.dev package publishes are forward-fix-only.
- Example app and generated-code tests may need Flutter/Firebase context.

## Reporting

Separate local diff, PR state, CI state, merge state, pub.dev publish state,
docs publish state, and package readback proof.
