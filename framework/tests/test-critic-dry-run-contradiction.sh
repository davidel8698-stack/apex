#!/usr/bin/env bash
# R16-619 (F-619, IMP-019):
# critic STEP 4.5 DRY-RUN VS SIDE-EFFECT CONTRADICTION DETECTION test.
#
# Spec anchor (apex-spec.md after R16 amendment):
#   "framework/agents/critic.md חייב להצליב טענות dry run /
#    no actual change / didn't actually / test only ב-SUMMARY.md/
#    RESULT.json מול event-log; אם פועל side-effect (POST, PUT,
#    DELETE, push, publish, deploy) נמצא — סתירה → FAIL."
#
# This test is a static / prose-anchor verifier — it does NOT invoke
# the critic LLM agent (cost-prohibitive in CI). It verifies the
# prose in critic.md describes STEP 4.5 correctly and that adjacent
# contracts (do-not-touch zones, STEP ordering, false-positive carve-
# out, defensive skip path) are in place.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CRITIC="$REPO_ROOT/framework/agents/critic.md"

LOCAL_PASS=0
LOCAL_FAIL=0
LOCAL_SKIP=0
ok()   { echo "  ✅ $1"; LOCAL_PASS=$((LOCAL_PASS+1)); }
nope() { echo "  ❌ $1"; LOCAL_FAIL=$((LOCAL_FAIL+1)); }
skip() { echo "  ⏭  $1"; LOCAL_SKIP=$((LOCAL_SKIP+1)); }

echo "=== R16-619: critic STEP 4.5 dry-run-vs-side-effect contradiction test ==="

if [ ! -f "$CRITIC" ]; then
  nope "0: critic.md missing"
  echo "$LOCAL_PASS/$((LOCAL_PASS+LOCAL_FAIL)) passed (skipped: $LOCAL_SKIP)"
  exit 1
fi
ok "0: critic.md exists"

# --- A. STEP 4.5 header + section identity -------------------------
if grep -qE "^\*\*STEP 4\.5:" "$CRITIC"; then
  ok "A1: critic.md declares STEP 4.5 as a top-level review step"
else
  nope "A1: critic.md missing STEP 4.5 header"
fi
if grep -qE "DRY-RUN VS SIDE-EFFECT|dry-run vs side-effect" "$CRITIC"; then
  ok "A2: critic.md names the section (dry-run vs side-effect)"
else
  nope "A2: critic.md missing dry-run-vs-side-effect naming"
fi

# --- B. Four claim tokens (case-insensitive presence) -------------
if grep -qiE "dry[ _]run" "$CRITIC"; then
  ok "B1: claim token — dry run"
else
  nope "B1: claim token 'dry run' missing"
fi
if grep -qiE "no actual change" "$CRITIC"; then
  ok "B2: claim token — no actual change"
else
  nope "B2: claim token 'no actual change' missing"
fi
if grep -qiE "didn'?t actually" "$CRITIC"; then
  ok "B3: claim token — didn't actually"
else
  nope "B3: claim token \"didn't actually\" missing"
fi
if grep -qiE "test only" "$CRITIC"; then
  ok "B4: claim token — test only"
else
  nope "B4: claim token 'test only' missing"
fi

# --- C. Side-effect verb set (subset proof) -----------------------
if grep -qE "POST|PUT|DELETE" "$CRITIC"; then
  ok "C1: side-effect HTTP verbs (POST/PUT/DELETE) declared"
else
  nope "C1: HTTP side-effect verbs missing"
fi
if grep -qE 'git.{0,8}push' "$CRITIC"; then
  ok "C2: side-effect verb — git push"
else
  nope "C2: 'git push' side-effect verb missing"
fi
if grep -qE "publish|deploy" "$CRITIC"; then
  ok "C3: side-effect verbs — publish/deploy"
else
  nope "C3: publish/deploy verbs missing"
fi

# --- D. Event-log reference ---------------------------------------
if grep -qE "event-log|event_log|\.apex/event-log\.jsonl" "$CRITIC"; then
  ok "D1: critic.md reads event-log"
else
  nope "D1: critic.md missing event-log reference"
fi

# --- E. Contradiction → FAIL with reason string -------------------
if grep -qE "dry_run_contradicted" "$CRITIC"; then
  ok "E1: contradiction reason string declared"
else
  nope "E1: 'dry_run_contradicted' reason string missing"
fi
# Must not invent a fourth verdict level.
if grep -qE "^- DRY_RUN:|^DRY_RUN:" "$CRITIC"; then
  nope "E2: critic.md introduces forbidden fourth verdict level DRY_RUN"
else
  ok "E2: critic.md does not invent a fourth verdict level"
fi

# --- F. False-positive carve-out (identifier-only matches) ---------
if grep -qiE "identifier-only|test_dry_run|test name|carve-?out" "$CRITIC"; then
  ok "F1: false-positive carve-out documented"
else
  nope "F1: false-positive carve-out missing (would over-fire on test names)"
fi

# --- G. Defensive skip on missing event-log -----------------------
if grep -qE "SKIPPED \(no event-log\)" "$CRITIC"; then
  ok "G1: defensive skip path for absent event-log declared"
else
  nope "G1: defensive 'SKIPPED (no event-log)' skip path missing"
fi

# --- H. Ordering: STEP 4.5 must come after STEP 4 and before OUTPUT.
STEP_4_LINE=$(grep -nE "^\*\*STEP 4:" "$CRITIC" | head -1 | cut -d: -f1)
STEP_45_LINE=$(grep -nE "^\*\*STEP 4\.5:" "$CRITIC" | head -1 | cut -d: -f1)
OUTPUT_LINE=$(grep -nE "^## OUTPUT" "$CRITIC" | head -1 | cut -d: -f1)
if [ -n "$STEP_4_LINE" ] && [ -n "$STEP_45_LINE" ] && [ -n "$OUTPUT_LINE" ] \
   && [ "$STEP_4_LINE" -lt "$STEP_45_LINE" ] && [ "$STEP_45_LINE" -lt "$OUTPUT_LINE" ]; then
  ok "H1: ordering — STEP 4 ($STEP_4_LINE) < STEP 4.5 ($STEP_45_LINE) < OUTPUT ($OUTPUT_LINE)"
else
  nope "H1: STEP 4.5 ordering broken (4@$STEP_4_LINE, 4.5@$STEP_45_LINE, OUTPUT@$OUTPUT_LINE)"
fi

# --- I. Do-not-touch preservation (Wave 6 wins) -------------------
if grep -qE "STEP 1\.5" "$CRITIC" && grep -qE "GIT TRACE VERIFICATION" "$CRITIC"; then
  ok "I1: Wave 6 STEP 1.5 (R-603) intact"
else
  nope "I1: Wave 6 STEP 1.5 disturbed"
fi
if grep -qE "WHAT YOU NEVER RECEIVE" "$CRITIC"; then
  ok "I2: WHAT YOU NEVER RECEIVE preservation contract intact"
else
  nope "I2: WHAT YOU NEVER RECEIVE section missing"
fi

# --- Bridge to harness globals ----------------------------------
if declare -F harness_assert_corpus >/dev/null 2>&1; then
  LOCAL_TOTAL=$((LOCAL_PASS + LOCAL_FAIL))
  harness_assert_corpus "$LOCAL_PASS" "$LOCAL_TOTAL" "critic STEP 4.5 dry-run contradiction" 100
fi

LOCAL_TOTAL=$((LOCAL_PASS+LOCAL_FAIL))
echo ""
echo "$LOCAL_PASS/$LOCAL_TOTAL passed (skipped: $LOCAL_SKIP)"
[ "$LOCAL_FAIL" -eq 0 ]
