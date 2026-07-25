#!/usr/bin/env bash
#
# Derive the &placeholder / RULE 10 scenarios (segman 2.2.0) from the
# reference/the-wildfire-v2.manuscript sample and append them to
# tests/scenarios.jsonl via the standard 03-add-scenario tool.
#
# scenarios.jsonl is never hand-edited (AGENTS.md). Same mechanics as
# add-command-scenarios.sh: (manuscript-from, manuscript-to) slice the
# context, (sentence-from, sentence-to) slice the expected segment within
# it. Re-runnable: the tool refuses exact duplicates.
#
# Run from the repo root:  bash tools/scenario-building/add-placeholder-scenarios.sh
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

echo "== Deriving &placeholder / RULE 10 scenarios into tests/scenarios.jsonl =="

# 1. Sole-line &placeholder is its own segment, even with an adjacent prose
#    line and sentence punctuation inside its {details} (RULE 9 + RULE 10).
add "&placeholder block" \
  '&placeholder#the-argument' 'The morning after, nobody spoke of it.' \
  '&placeholder#the-argument{paragraphs}' '{She confronts him. He deflects. Three beats, escalating.}'

# 2. Mid-line &placeholder stays inline; punctuation inside its {details}
#    does not split the host sentence (RULE 10).
add "&placeholder inline protected" \
  'She bought the ticket' 'The stationmaster remembered him.' \
  'She bought the ticket' 'The stationmaster remembered him.'

# 3. RULE 10 also protects &reference notes containing punctuation.
add "&reference notes protected" \
  'The bundle also cited' 'in a margin note.' \
  'The bundle also cited' 'in a margin note.'

exit $fail
