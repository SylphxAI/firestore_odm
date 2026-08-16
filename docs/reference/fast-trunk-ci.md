# Fast Trunk CI

## Authority split

| Concern | Owner |
| --- | --- |
| Work / claim / review | Git / native Codex coordination |
| Source history | Git |
| Source correctness | This repository CI (`ci-success`) |
| Package publication | This repository's release workflow + pub.dev |
| Hosted deploy / health / rollback | Not applicable: no hosted runtime surface |

## Paths

- **Internal agents:** small-batch non-force direct-trunk to default branch.
- **External contributors:** Pull Request presubmit feedback.
- **Merge Queue:** `merge_group` admission is enabled.

## CI scope

Blocking: formatting, analysis, package dry-run, affected tests, coverage,
documentation validation, narrow security, and the CI result fan-in. Performance
is a pull-request lane; the Firestore emulator is visible in CI and authoritative
before publication in the release workflow.

Not in source CI: production Docker/release image builds, serverless deployment,
or disposable ship binaries for ordinary tips. Package publication is a separate
release-layer action with exact pub.dev readback.
