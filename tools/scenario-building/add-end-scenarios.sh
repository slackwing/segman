#!/usr/bin/env bash
#
# Derive the &end#slug scenarios (segman 2.3.0) from the reference
# v2 manuscript and append them to tests/scenarios.jsonl via the standard
# 03-add-scenario tool (scenarios.jsonl is never hand-edited — AGENTS.md).
# Re-runnable: the tool refuses exact duplicates.
#
# Run from the repo root:  bash tools/scenario-building/add-end-scenarios.sh
set -euo pipefail

cd "$(dirname "$0")/../.."
REPO="$PWD"
export SENSEG_SCENARIOS_MANUSCRIPT="$REPO/reference/the-wildfire-v2.manuscript"

mkdir -p "$REPO/dist"
( cd "$REPO/tools/scenario-building/03-add-scenario" && go build -o "$REPO/dist/03-add-scenario" . )

fail=0
add() {
  local desc="$1" mfrom="$2" mto="$3" sfrom="$4" sto="$5" out
  out=$( cd "$REPO/tests" && "$REPO/dist/03-add-scenario" \
      --manuscript-from "$mfrom" --manuscript-to "$mto" \
      --sentence-from "$sfrom" --sentence-to "$sto" 2>&1 || true )
  if echo "$out" | grep -q '"expected"'; then echo "  added:   $desc"
  elif echo "$out" | grep -q duplicate; then echo "  present: $desc"
  else echo "  MISS:    $desc -> $out"; fail=1; fi
}

echo "== Deriving &end scenarios into tests/scenarios.jsonl =="

# 1. Sole-line bare &end#slug (no brace groups) is its own segment.
add "&end block" \
  'The music was loud' 'Later they found the notes.' \
  '&end#' 'kegparty'

# 2. Literal '&end' without #/{ delimiter stays prose.
add "&end literal prose" \
  'Later they found the notes.' 'The &end of that story stayed unwritten.' \
  'The &end of that' 'story stayed unwritten.'

exit $fail
