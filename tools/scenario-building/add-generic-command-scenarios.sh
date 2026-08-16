#!/usr/bin/env bash
#
# Derive the GENERIC &-command scenarios (segman 2.6.0) from the v2 test
# manuscript and append them via the standard 03-add-scenario tool
# (scenarios.jsonl is never hand-edited — AGENTS.md). v2.6.0 recognizes
# commands SYNTACTICALLY (& + [a-z]+ + #/{) — no keyword list — so unknown
# names like &fresco/&glaze/&carve segment by the default rules:
# block iff sole-line, inline otherwise, token atomic, bare & literal.
# Re-runnable: the tool refuses exact duplicates.
#
# Run from the repo root:  bash tools/scenario-building/add-generic-command-scenarios.sh
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

echo "== Deriving generic &-command scenarios into tests/scenarios.jsonl =="

# 1. Sole-line UNKNOWN command is its own block segment.
add "generic command block (sole-line)" \
  'no more after that.' 'The painter arrived' \
  '&fresco#' 'q2w3e4r5tt{The mural}'

# 2. Mid-sentence UNKNOWN command stays inline, token atomic.
add "generic command inline" \
  'what the wall would become.' 'The receipt was itemized' \
  'He left a note' 'beside the scaffold.'

# 3. Bare & and &name-without-brace remain literal prose.
add "generic name without token shape stays literal" \
  'touched nothing.' 'Then the wall said' \
  'The receipt was itemized' 'and nothing more.'
# 3b. '&name' followed by a space (no #/{) is literal too.
add "generic name without brace stays literal" \
  'touched nothing.' 'Then the wall said' \
  'A &fresco of accidents,' 'we let it stand.'

# 4. Sentence punctuation inside an unknown command's braces never splits it.
add "generic command token atomic across inner periods" \
  'we let it stand.' 'The scaffold came down' \
  'Then the wall said' 'only we could see.'

if [ "$fail" -ne 0 ]; then echo 'Some scenarios failed to add'; exit 1; fi
