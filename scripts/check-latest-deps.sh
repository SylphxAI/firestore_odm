#!/usr/bin/env bash
# Resolve every package against the LATEST releases pub.dev allows (major
# versions included) in a scratch copy, then run what CI runs: generate,
# analyze, tests. The working tree is not touched.
#
# Needs flutter and melos on PATH and a bootstrapped checkout (CI runs
# .github/actions/setup-flutter first). Writes a Markdown report to
# $REPORT (default: latest-deps-report.md in the current directory) and exits
# non-zero when any step fails.
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
report="${REPORT:-$PWD/latest-deps-report.md}"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

cp -R "$root"/. "$scratch"/
cd "$scratch" || exit 2
rm -rf docs/node_modules

log="$scratch/.latest-deps.log"
: > "$log"
failed=""

step() { # step <name> <command...>
  local name="$1"; shift
  echo "::group::$name"
  "$@" 2>&1 | tee -a "$log" | tail -n 200
  if [ "${PIPESTATUS[0]}" -eq 0 ]; then
    echo "::endgroup::"
    return 0
  fi
  echo "::endgroup::"
  echo "::error::$name failed against the latest dependencies"
  failed="$name"
  return 1
}

# Keeps path overrides between the packages (pubspec_overrides.yaml, written
# by `melos bootstrap`), so only outside dependencies move.
run() {
  step "Upgrade to latest majors" melos exec -c 1 -- flutter pub upgrade --major-versions &&
  step "Generate code" melos run generate &&
  step "Analyze" melos run analyze --no-select &&
  step "Test" melos run test:all --no-select
}
run

versions="$(
  for p in cloud_firestore analyzer source_gen build_runner build analyzer_plugin; do
    v="$(awk -v p="  $p:" '$0 == p {on=1; next} on && /^  [^ ]/ {on=0} on && /^    version: / {gsub(/"/, "", $2); print $2}' \
      packages/*/pubspec.lock apps/*/pubspec.lock 2>/dev/null | sort -uV | tail -n 1)"
    [ -n "$v" ] && echo "| \`$p\` | $v |"
  done
)"

{
  if [ -n "$failed" ]; then
    echo "The \`$failed\` step fails when every dependency is raised to its latest release."
  else
    echo "Everything passes against the latest dependencies."
  fi
  echo
  echo "Resolved versions (highest across the packages):"
  echo
  echo "| Package | Version |"
  echo "| --- | --- |"
  echo "$versions"
  echo
  if [ -n "$failed" ]; then
    echo "Last lines of output:"
    echo
    echo '```'
    tail -n 60 "$log" | cut -c 1-400
    echo '```'
  fi
} > "$report"

[ -z "$failed" ]
