#!/usr/bin/env bash
# Benchmarks firestore_odm against cloud_firestore_odm and raw cloud_firestore:
# code generation time on 20 identical models, and runtime cost per operation
# on an in-memory Firestore. Prints a Markdown report.
#
# Usage: benchmarks/run.sh [model count, default 20]
# Needs Flutter on PATH. CI runs it with .github/workflows/benchmarks.yml.
#
# Environment:
#   BENCH_JSON      write a machine-readable results file to this path
#   BENCH_PROJECTS  projects to measure (default "firestore_odm cloud_firestore_odm");
#                   with only firestore_odm the Markdown report is skipped
set -euo pipefail
export LC_ALL=C

cd "$(dirname "$0")"
models="${1:-20}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
dart run generate_models.dart "$models" >&2

now() { date +%s.%N; }
elapsed() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.1f", b - a }'; }

build() {
  dart run build_runner build --delete-conflicting-outputs > "$work/build.log" 2>&1 \
    || { cat "$work/build.log" >&2; exit 1; }
}

declare -A cold full one
for project in ${BENCH_PROJECTS:-firestore_odm cloud_firestore_odm}; do
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
    # Capture the producer status before extracting rows: a test can print
    # valid measurements and then fail. Never publish those as a valid run.
    rc=0
    flutter test test/runtime_test.dart > "$work/runtime-$project.log" 2>&1 || rc=$?
    if (( rc != 0 )); then
      cat "$work/runtime-$project.log" >&2
      exit "$rc"
    fi
    # No rows is a validation failure, not an unsupported/zero measurement.
    # Keep the first marker so joined rows cannot hide an earlier invalid
    # measurement; the extra fields then fail exact-row validation.
    awk 'match($0, /BENCH/) { print substr($0, RSTART) }' "$work/runtime-$project.log"
  ) > "$work/bench-$project.txt"
  raw='raw-cf6'
  [[ "$project" == cloud_firestore_odm ]] && raw='raw-cf5'
  awk -v project="$project" -v raw="$raw" -f validate.awk "$work/bench-$project.txt" \
    || { cat "$work/runtime-$project.log" >&2; exit 1; }
  cold[$project]=$(awk '$1 == "cold" { print $2 }' "$work/bench-$project.txt")
  full[$project]=$(awk '$1 == "full" { print $2 }' "$work/bench-$project.txt")
  one[$project]=$(awk '$1 == "one" { print $2 }' "$work/bench-$project.txt")
done

json_projects() {
  local first=1 project raw
  for project in ${BENCH_PROJECTS:-firestore_odm cloud_firestore_odm}; do
    raw='raw-cf6'
    [[ "$project" == cloud_firestore_odm ]] && raw='raw-cf5'
    (( first )) || printf ','
    first=0
    printf '"%s":{"codegen":{"cold":%s,"full":%s,"one":%s},"runtime":{' \
      "$project" "${cold[$project]}" "${full[$project]}" "${one[$project]}"
    for variant in "$project" "$raw"; do
      [[ "$variant" == "$project" ]] || printf ','
      printf '"%s":{' "$variant"
      awk -v v="$variant" '$1 == "BENCH" && $2 == v { printf "%s\"%s\":%s", (n++ ? "," : ""), $3, $4 }' \
        "$work/bench-$project.txt"
      printf '}'
    done
    printf '}}'
  done
}
if [[ -n "${BENCH_JSON:-}" ]]; then
  printf '{"models":%s,"projects":{%s}}\n' "$models" "$(json_projects)" > "$BENCH_JSON"
fi
[[ "${BENCH_PROJECTS:-}" != "firestore_odm" ]] || exit 0

result() { awk -v v="$1" -v n="$2" '$2 == v && $3 == n { print $4 }' "$work"/bench-*.txt; }

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
