#!/usr/bin/env bash
# Benchmarks firestore_odm against cloud_firestore_odm and raw cloud_firestore:
# code generation time on 20 identical models, and runtime cost per operation
# on an in-memory Firestore. Prints a Markdown report.
#
# Usage: benchmarks/run.sh [model count, default 20]
# Needs Flutter on PATH. CI runs it with .github/workflows/benchmarks.yml.
set -euo pipefail

cd "$(dirname "$0")"
models="${1:-20}"
dart run generate_models.dart "$models" >&2

now() { date +%s.%N; }
elapsed() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f", b - a }'; }

build() {
  dart run build_runner build --delete-conflicting-outputs > /tmp/build.log 2>&1 \
    || { cat /tmp/build.log >&2; exit 1; }
}

declare -A cold full one
for project in firestore_odm cloud_firestore_odm; do
  (
    cd "$project"
    flutter pub get > /dev/null
    rm -rf .dart_tool/build
    start=$(now); build; end=$(now)
    echo "cold $(elapsed "$start" "$end")"
    for f in lib/models/*.dart; do echo "// edited" >> "$f"; done
    start=$(now); build; end=$(now)
    echo "full $(elapsed "$start" "$end")"
    echo "// edited" >> lib/models/model01.dart
    start=$(now); build; end=$(now)
    echo "one $(elapsed "$start" "$end")"
    flutter test test/runtime_test.dart 2>&1 | grep -o 'BENCH .*' || true
  ) > "/tmp/bench-$project.txt"
  grep -q '^BENCH' "/tmp/bench-$project.txt" \
    || { cat "/tmp/bench-$project.txt" >&2; echo "no runtime results for $project" >&2; exit 1; }
  cold[$project]=$(awk '$1 == "cold" { print $2 }' "/tmp/bench-$project.txt")
  full[$project]=$(awk '$1 == "full" { print $2 }' "/tmp/bench-$project.txt")
  one[$project]=$(awk '$1 == "one" { print $2 }' "/tmp/bench-$project.txt")
done

result() { awk -v v="$1" -v n="$2" '$2 == v && $3 == n { print $4 }' /tmp/bench-*.txt; }

cat <<EOF
### Code generation ($models models, seconds, lower is better)

| | firestore_odm | cloud_firestore_odm |
| --- | ---: | ---: |
| First build (includes compiling the build script) | ${cold[firestore_odm]} | ${cold[cloud_firestore_odm]} |
| Rebuild after editing every model | ${full[firestore_odm]} | ${full[cloud_firestore_odm]} |
| Rebuild after editing one model | ${one[firestore_odm]} | ${one[cloud_firestore_odm]} |

### Runtime (microseconds per operation, median of 7 rounds, lower is better)

| Operation | firestore_odm | raw cloud_firestore 6 | cloud_firestore_odm | raw cloud_firestore 5 |
| --- | ---: | ---: | ---: | ---: |
EOF
for op in set get query update mapping; do
  echo "| $op | $(result firestore_odm $op) | $(result raw-cf6 $op) | $(result cloud_firestore_odm $op) | $(result raw-cf5 $op) |"
done
cat <<EOF

Flutter $(flutter --version --machine | sed -n 's/.*"frameworkVersion": *"\([^"]*\)".*/\1/p'), $(uname -sm), $(nproc) CPUs.
EOF
