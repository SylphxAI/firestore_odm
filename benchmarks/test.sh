#!/usr/bin/env bash
# Exercise the actual runner, but only in disposable projects with inert SDKs.
set -euo pipefail
here=$(dirname "$(realpath "$0")")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/benchmarks" "$work/bin"
cp "$here/run.sh" "$here/validate.awk" "$work/benchmarks/"
cp "$here/fixtures/flutter" "$here/fixtures/dart" "$work/bin/"
chmod +x "$work/bin/flutter" "$work/bin/dart"
export PATH="$work/bin:$PATH"

for project in firestore_odm cloud_firestore_odm; do
  for scenario in happy failure-after-row empty missing duplicate nan infinity overflow negative malformed unexpected extra-field malformed-marker; do
    rc=0
    # Match the workflow pipeline, including tee. Both producers are inert.
    SCENARIO="$scenario" FAULT_PROJECT="$project" bash "$work/benchmarks/run.sh" \
      2> "$work/error" | tee "$work/report" > /dev/null || rc=$?
    if [[ "$scenario" == happy ]]; then
      [[ "$rc" == 0 ]]
      [[ $(grep -c '^| .* | 1.25 | 1.25 | 1.25 | 1.25 |$' "$work/report") == 5 ]]
      grep -q 'Flutter fixture' "$work/report"
    else
      [[ "$rc" != 0 && ! -s "$work/report" ]]
      if [[ "$scenario" == failure-after-row ]]; then
        [[ "$rc" == 23 ]]
        grep -q 'fixture producer failed' "$work/error"
      else
        grep -q 'measurement\|malformed' "$work/error"
      fi
    fi
    printf 'PASS %s %s\n' "$project" "$scenario"
  done
done

# Build timings are validated as well as runtime rows.
for value in NaN Infinity 1e999 -1 nope; do
  rc=0
  printf 'cold %s\nfull 1\none 1\n' "$value" | \
    awk -v project=firestore_odm -v raw=raw-cf6 -f "$here/validate.awk" \
    > /dev/null 2> "$work/error" || rc=$?
  [[ "$rc" != 0 ]]
  grep -q 'malformed build row' "$work/error"
done
printf 'PASS invalid build timings\n'
