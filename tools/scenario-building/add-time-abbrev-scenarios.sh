#!/usr/bin/env bash
#
# Derive the a.m./p.m. boundary scenarios (segman 2.6.1) from the
# reference/time-abbrev.manuscript sample and append them to
# tests/scenarios.jsonl via the standard 03-add-scenario tool.
#
# The rule: "m." (a.m./p.m.) is only a SOFT abbreviation — a following
# lowercase word continues the sentence; a following CAPITAL is a real
# boundary ("almost 10 A. M. And the stale heat…" — the capital is the
# giveaway).
#
# scenarios.jsonl is never hand-edited (AGENTS.md). Re-runnable: the tool
# refuses exact duplicates, so a second run is a no-op.
#
# Run from the repo root:  bash tools/scenario-building/add-time-abbrev-scenarios.sh
set -euo pipefail

cd "$(dirname "$0")/../.."
REPO="$PWD"
export SENSEG_SCENARIOS_MANUSCRIPT="$REPO/reference/time-abbrev.manuscript"

mkdir -p "$REPO/dist"
( cd "$REPO/tools/scenario-building/03-add-scenario" && go build -o "$REPO/dist/03-add-scenario" . )

fail=0
add() {
  local desc="$1" mfrom="$2" mto="$3" sfrom="$4" sto="$5" out
  out=$( cd "$REPO/tests" && "$REPO/dist/03-add-scenario" \
      --manuscript-from "$mfrom" --manuscript-to "$mto" \
      --sentence-from "$sfrom" --sentence-to "$sto" 2>&1 || true )
  if echo "$out" | grep -q '"expected"'; then echo "  added:   $desc"
  elif echo "$out" | grep -qi 'duplicate'; then echo "  skipped: $desc (already present)"
  else echo "  FAILED:  $desc"; echo "$out" | sed 's/^/    /'; fail=1
  fi
}

add "A. M. + capital ends the sentence" \
  "But it was" "settled in." "But it was" "10 A. M."
add "capital after A. M. starts the next sentence" \
  "But it was" "settled in." "And the stale" "settled in."
add "a.m. + lowercase continues the sentence" \
  "We had left" "gave out." "We had left" "gave out."
add "p.m. + capital ends the sentence" \
  "The bus was" "meet it." "The bus was" "9 p.m."
add "a.m. + lowercase adjective continues the sentence" \
  "The timers" "6 a.m. sharp." "The timers" "sharp."

exit $fail
