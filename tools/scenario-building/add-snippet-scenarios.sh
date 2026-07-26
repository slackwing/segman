#!/usr/bin/env bash
#
# Derive the &snippet#id{label} scenarios (segman 2.4.0) from the reference
# v2 manuscript and append them to tests/scenarios.jsonl via the standard
# 03-add-scenario tool (scenarios.jsonl is never hand-edited — AGENTS.md).
# Re-runnable: the tool refuses exact duplicates.
#
# Run from the repo root:  bash tools/scenario-building/add-snippet-scenarios.sh
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

echo "== Deriving &snippet scenarios into tests/scenarios.jsonl =="

# 1. Sole-line &snippet#id{label} is its own block segment.
add "&snippet block" \
  '&chapter#p2c5' 'She practiced the words twice' \
  '&snippet#' 'k7f2m9q1aa{The proposal}'

# 2. Mid-sentence &snippet#id{label} stays inline (atomic within the sentence).
add "&snippet inline" \
  '&end#k7f2m9q1aa' 'The margin note' \
  'Deep in a sentence' 'like contraband.'

# 3. '&snippet#id' with no {label} group is not a token — stays prose.
add "&snippet bare-slug literal" \
  'like contraband.' 'nothing else that year.' \
  'The margin note read' 'nothing else that year.'

if [ "$fail" -ne 0 ]; then echo 'Some scenarios failed to add'; exit 1; fi
