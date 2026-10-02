#!/bin/sh
# The root README is also the pub.dev page (packages/firestore_odm/README.md links to it).
# pub.dev and GitHub resolve relative URLs differently, so every link and image must be absolute.
set -eu
cd "$(dirname "$0")/.."
bad=$(grep -nE '(src|href)="[^"]*"|\]\([^)[:space:]]*' README.md \
  | grep -oE '^[0-9]+:|(src|href)="[^"]*"|\]\([^)[:space:]]*' \
  | awk '/^[0-9]+:$/ {line=$0; next} {u=$0; sub(/^(src|href)="/,"",u); sub(/"$/,"",u); sub(/^\]\(/,"",u); if (u != "" && u !~ /^(https?:|#|mailto:)/) print "README.md:" line " relative link " u}')
if [ -n "$bad" ]; then
  echo "$bad" >&2
  echo "Use absolute URLs in README.md (pub.dev page)." >&2
  exit 1
fi
echo "README links are absolute"
