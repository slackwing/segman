#!/usr/bin/env bash
#
# Derive the &sketch#id{label} scenarios (segman 2.5.0) from the reference
# v2 manuscript and append them to tests/scenarios.jsonl via the standard
# 03-add-scenario tool (scenarios.jsonl is never hand-edited — AGENTS.md).
# &sketch is the successor spelling of &snippet (manuscript-studio renamed
# snippet→sketch); both parse identically, so the scenarios mirror 084-086.
# Re-runnable: the tool refuses exact duplicates.
#
# Run from the repo root:  bash tools/scenario-building/add-sketch-scenarios.sh
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

echo "== Deriving &sketch scenarios into tests/scenarios.jsonl =="

# 1. Sole-line &sketch#id{label} is its own block segment.
add "&sketch block" \
  '&chapter#p2c6' 'He said it plainly' \
  '&sketch#' 'b8d4n2v6qq{The confession}'

# 2. Mid-sentence &sketch#id{label} stays inline (atomic within the sentence).
add "&sketch inline" \
  '&end#b8d4n2v6qq' 'The ledger listed' \
  'Halfway through' 'two commas.'

# 3. '&sketch#id' with no {label} group is not a token — stays prose.
add "&sketch bare-slug literal" \
  'two commas.' 'no more after that.' \
  'The ledger listed' 'no more after that.'

if [ "$fail" -ne 0 ]; then echo 'Some scenarios failed to add'; exit 1; fi
