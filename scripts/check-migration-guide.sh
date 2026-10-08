#!/usr/bin/env bash
# Exercise the guide's sample through the CLI, generated API and fake Firestore.
set -euo pipefail
root="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"
sample="$(mktemp -d "${TMPDIR:-/tmp}/odm-migration-guide.XXXXXX")"
trap 'rm -rf -- "$sample"' EXIT
flutter create --project-name odm_migration_sample "$sample" --no-pub
rm -- "$sample/test/widget_test.dart"
printf 'void main() {}\n' > "$sample/lib/main.dart"
python3 -I - "$root" "$sample" <<'PY'
import pathlib
import re
import sys
root, sample = map(pathlib.Path, sys.argv[1:])
guide = (root / 'docs/guide/migrate-from-cloud-firestore-odm.md').read_text()
blocks = dict(re.findall(r'```(?:dart|yaml)\n(?://|#) migration-sample: ([^\n]+)\n(.*?)\n```', guide, re.S))
(sample / 'lib/movie.dart').write_text(blocks['old-model'] + '\n')
(sample / 'test/migration_test.dart').write_text(blocks['verification'] + '\n')
deps = blocks['dependencies'].replace('dependencies:\n', 'dependencies:\n  flutter:\n    sdk: flutter\n', 1)
deps = deps.replace('dev_dependencies:\n', 'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n', 1)
(sample / 'pubspec.yaml').write_text("name: odm_migration_sample\nenvironment:\n  sdk: '>=3.8.1 <4.0.0'\n" + deps + '\n')
PY
cp "$sample/pubspec.yaml" "$sample/pubspec.before"
cp "$sample/lib/movie.dart" "$sample/movie.before"
(cd "$root/packages/firestore_odm_builder" && dart run bin/migrate.dart "$sample")
cmp "$sample/pubspec.before" "$sample/pubspec.yaml"
cmp "$sample/movie.before" "$sample/lib/movie.dart"
(cd "$root/packages/firestore_odm_builder" && dart run bin/migrate.dart --apply "$sample")
# Test the unpublished head rather than the last pub.dev release. Customers do
# not need these overrides; the guide uses the published packages.
printf '\ndependency_overrides:\n  firestore_odm:\n    path: %s/packages/firestore_odm\n  firestore_odm_annotation:\n    path: %s/packages/firestore_odm_annotation\n  firestore_odm_builder:\n    path: %s/packages/firestore_odm_builder\n' "$root" "$root" "$root" >> "$sample/pubspec.yaml"
(cd "$sample" && flutter pub add dev:fake_cloud_firestore && dart run build_runner build --delete-conflicting-outputs && dart format lib test && flutter analyze && flutter test)
