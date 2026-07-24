#!/usr/bin/env bash
#
# Derive the &-command boundary scenarios (segman 1.2.0, RULE 9) from the
# reference/the-wildfire-v2.manuscript sample and append them to
# tests/scenarios.jsonl via the standard 03-add-scenario tool.
#
# scenarios.jsonl is never hand-edited (AGENTS.md). Each case is
# (manuscript-from, manuscript-to, sentence-from, sentence-to): the tool
# slices context = manuscript[mfrom..mto] and expected = context[sfrom..sto].
# The tool finds `sto` AFTER `sfrom`, so `sfrom`/`sto` must be DISTINCT,
# non-overlapping start/end fragments of the target segment. Re-runnable: the
# tool refuses exact duplicates, so a second run is a no-op.
#
# Run from the repo root:  bash tools/scenario-building/add-command-scenarios.sh
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

echo "== Deriving &-command scenarios into tests/scenarios.jsonl =="

# 1. &title is its own segment.
add "&title block" \
  '&title{The Wildfire}' '&part#p1{I.}{The Gathering}' \
  '&title{The' 'Wildfire}'

# 2. &part block.
add "&part block" \
  '&part#p1{I.}{The Gathering}' '&chapter#p1c1' \
  '&part#p1{I.}' '{The Gathering}'

# 3. &chapter block.
add "&chapter block" \
  '&chapter#p1c1{1.}{Smoke on the ridge}' 'The fire began' \
  '&chapter#p1c1{1.}' '{Smoke on the ridge}'

# 4. &chapter with the optional {desc} 3rd arg, context includes trailing prose.
add "&chapter with desc + trailing prose" \
  '&chapter#p1c1{1.}{Smoke on the ridge}' 'across the ridge before' \
  '&chapter#p1c1' '{Smoke on the ridge}'

# 5. &anchor ALONE on its line -> its own block segment.
add "&anchor alone -> block" \
  '&anchor#lookback{a still moment}' 'They spoke of the smoke' \
  '&anchor#lookback{' 'still moment}'

# 6. &anchor INLINE (mid-sentence) -> stays inside the host sentence.
add "&anchor inline -> host sentence" \
  'She walked the burned line' 'They spoke of the smoke' \
  'She walked the burned line' 'under her boots.'

# 7. &anchor inline with EMPTY arg mid-sentence -> host sentence intact.
add "&anchor#x{} inline empty arg" \
  'They spoke of the smoke' 'Smith & Sons rebuilt' \
  'The fire &anchor#firemark{}' 'people remembered.'

# 8. &chapter ... &anchor on the SAME line -> ONE segment. (Internal spacing
#    is collapsed to a single space by phase-3 normalization, so the sample
#    uses one space to match the produced segment exactly.)
add "&chapter + &anchor same line -> one segment" \
  '&chapter#p2c2{2.}{Threads} &anchor#thread{tie-off}' 'The letters came' \
  '&chapter#p2c2{2.}' '&anchor#thread{tie-off}'

# 9. &reference inline -> stays inside the host sentence.
add "&reference inline -> host sentence" \
  'befell them on the road north.' '&chapter#p2c2' \
  'See &reference#origin{the opening}' 'how it started.'

# 10. literal & in prose (Smith & Sons, R&D) -> no split at &.
add "literal & (Smith & Sons, R&D)" \
  'Smith & Sons rebuilt' '&part#p2{II.}{The Return}' \
  'Smith & Sons rebuilt' 'the burn scars.'

# 11. literal &chapter with NO delimiter -> prose, not a command.
add "literal &chapter (no delimiter)" \
  'A &chapter of accidents' 'See &reference#origin' \
  'A &chapter of accidents' 'the road north.'

# 12. # markdown header STILL works (additive; unchanged).
add "# markdown header still works" \
  '# An old markdown header' 'This paragraph still segments' \
  '# An old' 'markdown header'

echo "== tests/scenarios.jsonl now has $(wc -l < "$REPO/tests/scenarios.jsonl") scenarios. =="
exit $fail
