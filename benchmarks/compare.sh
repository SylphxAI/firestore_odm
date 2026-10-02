#!/usr/bin/env bash
# A/B check: fail when a firestore_odm metric in HEAD's results is worse than
# the merge-base's by more than the budget in budgets.json.
# Usage: benchmarks/compare.sh base.json head.json
set -euo pipefail
here=$(dirname "$(realpath "$0")")
base=$1 head=$2
jq -r -n --slurpfile b "$base" --slurpfile h "$head" --slurpfile g "$here/budgets.json" '
  def metrics($d):
    $d.projects.firestore_odm
    | ([.codegen | to_entries[] | {k: ("codegen." + .key), v: .value, kind: "codegen"}]
     + [.runtime.firestore_odm | to_entries[] | {k: ("runtime." + .key), v: .value, kind: "runtime"}]);
  ($b[0] | metrics(.)) as $bm
  | ($h[0] | metrics(.)) as $hm
  | $g[0] as $g
  | [ $hm[] | . as $m
      | ($bm[] | select(.k == $m.k)) as $o
      | {k: $m.k, base: $o.v, head: $m.v, ratio: (if $o.v > 0 then $m.v / $o.v else 1 end),
         budget: (if $m.kind == "codegen" then $g.codegen_ratio else $g.runtime_ratio end)} ]
  | .[] | "\(.k)\t\(.base)\t\(.head)\t\(.ratio * 100 | round / 100)\t\(.budget)\t\(if .ratio > .budget then "FAIL" else "ok" end)"' \
  | awk -F'\t' '
    BEGIN { print "| metric | merge-base | head | ratio | budget | |"; print "| --- | ---: | ---: | ---: | ---: | --- |" }
    { printf "| %s | %s | %s | %s | %s | %s |\n", $1, $2, $3, $4, $5, $6; if ($6 == "FAIL") bad = 1 }
    END { exit bad }'
