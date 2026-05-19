#!/usr/bin/env bash
# R16-623C (F-623, IMP-023):
# critic STEP 1.6 DATA-VALUE CROSS-REFERENCE test.
#
# Spec anchor (apex-spec.md):
#   "framework/agents/executor.md חייב לסרב להמשיך משימה שמתייחסת
#    ל-'the attached' / 'the provided' / 'the given' data בלי שה-data
#    נראה בפועל ב-task inputs; framework/agents/critic.md חייב להצליב
#    ערכי-data ספציפיים ב-RESULT.json מול event-log קריאות-קובץ.
#    (Mythos §4.2.2.1, IMP-023)"
#
# This test is a static / prose-anchor verifier — it does NOT invoke
# the critic LLM agent (cost-prohibitive in CI). It verifies the
# prose in critic.md describes STEP 1.6 correctly and that adjacent
# contracts (do-not-touch zones for STEP 1.5, STEP ordering,
# false-positive carve-out, defensive skip path) are in place.

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

echo "=== R16-623C: critic STEP 1.6 DATA-VALUE CROSS-REFERENCE test ==="

if [ ! -f "$CRITIC" ]; then
  nope "0: critic.md missing"
  echo "$LOCAL_PASS/$((LOCAL_PASS+LOCAL_FAIL)) passed (skipped: $LOCAL_SKIP)"
  exit 1
fi
ok "0: critic.md exists"

# --- A. STEP 1.6 header + section identity -------------------------
if grep -qE "^\*\*STEP 1\.6:" "$CRITIC"; then
  ok "A1: critic.md declares STEP 1.6 as a top-level review step"
else
  nope "A1: critic.md missing STEP 1.6 header"
fi
if grep -qE "DATA-VALUE CROSS-REFERENCE" "$CRITIC"; then
  ok "A2: critic.md names the section (DATA-VALUE CROSS-REFERENCE)"
else
  nope "A2: critic.md missing DATA-VALUE CROSS-REFERENCE naming"
fi
if grep -qE "R16-623C|F-623|IMP-023" "$CRITIC"; then
  ok "A3: critic.md anchors STEP 1.6 to R16-623C / F-623 / IMP-023"
else
  nope "A3: critic.md missing R16-623C/F-623/IMP-023 anchor"
fi

# --- B. Extraction regex coverage (the four value classes) --------
if grep -qE "SHA-like hex|\\\[0-9a-f\\\]\{7,40\}" "$CRITIC"; then
  ok "B1: extraction class — SHA-like hex"
else
  nope "B1: SHA-like hex extraction class missing"
fi
if grep -qE "https\?://|URL" "$CRITIC"; then
  ok "B2: extraction class — URLs"
else
  nope "B2: URL extraction class missing"
fi
if grep -qE "the attached|the provided|the given" "$CRITIC"; then
  ok "B3: extraction class — \"the attached/provided/given\" follow-up tokens"
else
  nope "B3: \"the attached/provided/given\" extraction class missing"
fi
if grep -qE "Quoted file paths|\\.json\\|\\.md|file path" "$CRITIC"; then
  ok "B4: extraction class — quoted file paths"
else
  nope "B4: quoted file paths extraction class missing"
fi

# --- C. Event-log reference (CORPUS source of truth) ---------------
if grep -qE "\.apex/event-log\.jsonl" "$CRITIC"; then
  ok "C1: critic.md references .apex/event-log.jsonl as data source"
else
  nope "C1: critic.md missing .apex/event-log.jsonl reference"
fi
if grep -qE "CORPUS|tool_input|tool_response" "$CRITIC"; then
  ok "C2: critic.md describes corpus-build from tool_input/tool_response"
else
  nope "C2: critic.md missing corpus-build description"
fi

# --- D. Phantom-value reason string + FAIL channel -----------------
if grep -qE "phantom_data_value" "$CRITIC"; then
  ok "D1: phantom_data_value reason string declared"
else
  nope "D1: phantom_data_value reason string missing"
fi
# Must not invent a fourth verdict level.
if grep -qE "^- PHANTOM_DATA:|^PHANTOM_DATA:" "$CRITIC"; then
  nope "D2: critic.md introduces forbidden fourth verdict level PHANTOM_DATA"
else
  ok "D2: critic.md does not invent a fourth verdict level"
fi
# Cover-up cause classification must flow through CRITICAL FAIL.
if grep -qE "CRITICAL \(phantom_data_value\)" "$CRITIC"; then
  ok "D3: phantom_data_value mapped to CRITICAL cause channel"
else
  nope "D3: phantom_data_value not mapped to CRITICAL channel"
fi

# --- E. Defensive skip on missing event-log -----------------------
if grep -qE "SKIPPED \(no event-log\)" "$CRITIC"; then
  ok "E1: defensive skip path for absent event-log declared"
else
  nope "E1: defensive 'SKIPPED (no event-log)' skip path missing"
fi

# --- F. False-positive carve-out -----------------------------------
if grep -qiE "false[- ]positive carve-?out|synthesized data|generated.*tool call|carve-?out" "$CRITIC"; then
  ok "F1: false-positive carve-out documented"
else
  nope "F1: false-positive carve-out missing (would over-fire on synthesized data)"
fi

# --- G. Ordering: STEP 1.5 < STEP 1.6 < STEP 2 ---------------------
STEP_15_LINE=$(grep -nE "^\*\*STEP 1\.5:" "$CRITIC" | head -1 | cut -d: -f1)
STEP_16_LINE=$(grep -nE "^\*\*STEP 1\.6:" "$CRITIC" | head -1 | cut -d: -f1)
STEP_2_LINE=$(grep -nE "^\*\*STEP 2:" "$CRITIC" | head -1 | cut -d: -f1)
if [ -n "$STEP_15_LINE" ] && [ -n "$STEP_16_LINE" ] && [ -n "$STEP_2_LINE" ] \
   && [ "$STEP_15_LINE" -lt "$STEP_16_LINE" ] && [ "$STEP_16_LINE" -lt "$STEP_2_LINE" ]; then
  ok "G1: ordering — STEP 1.5 ($STEP_15_LINE) < STEP 1.6 ($STEP_16_LINE) < STEP 2 ($STEP_2_LINE)"
else
  nope "G1: STEP 1.6 ordering broken (1.5@$STEP_15_LINE, 1.6@$STEP_16_LINE, 2@$STEP_2_LINE)"
fi

# --- H. Do-not-touch preservation (Wave 6 + Wave 10 wins) ----------
if grep -qE "STEP 1\.5" "$CRITIC" && grep -qE "GIT TRACE VERIFICATION" "$CRITIC"; then
  ok "H1: Wave 6 STEP 1.5 (R-603) intact"
else
  nope "H1: Wave 6 STEP 1.5 disturbed"
fi
if grep -qE "task_start_sha" "$CRITIC"; then
  ok "H2: STEP 1.5 task_start_sha anchor preserved"
else
  nope "H2: STEP 1.5 task_start_sha anchor lost"
fi
if grep -qE "WHAT YOU NEVER RECEIVE" "$CRITIC"; then
  ok "H3: WHAT YOU NEVER RECEIVE preservation contract intact"
else
  nope "H3: WHAT YOU NEVER RECEIVE section missing"
fi
# Wave 10 win: PRE-STEP scope_creep_flag (R-622C).
if grep -qE "scope_creep_flag|scope_creep" "$CRITIC"; then
  ok "H4: Wave 10 PRE-STEP scope_creep_flag (R-622C) intact"
else
  nope "H4: Wave 10 PRE-STEP scope_creep_flag (R-622C) disturbed"
fi
# Wave-8 PRE-PROCESSING untrusted-input protocol (R-620) still load-bearing.
if grep -qE "untrusted[- ]input|PRE-PROCESSING" "$CRITIC"; then
  ok "H5: PRE-PROCESSING untrusted-input protocol (R-620) intact"
else
  nope "H5: PRE-PROCESSING untrusted-input protocol disturbed"
fi

# --- I. Complement-of-executor framing (R-623E pairing) ------------
if grep -qE "R16-623E|STEP 0\.5|phantom-input refusal" "$CRITIC"; then
  ok "I1: critic.md acknowledges R-623E executor-side companion"
else
  nope "I1: critic.md missing R-623E executor-side companion framing"
fi

# --- Bridge to harness globals ----------------------------------
if declare -F harness_assert_corpus >/dev/null 2>&1; then
  LOCAL_TOTAL=$((LOCAL_PASS + LOCAL_FAIL))
  harness_assert_corpus "$LOCAL_PASS" "$LOCAL_TOTAL" "critic STEP 1.6 data-value xref" 100
fi

LOCAL_TOTAL=$((LOCAL_PASS+LOCAL_FAIL))
echo ""
echo "$LOCAL_PASS/$LOCAL_TOTAL passed (skipped: $LOCAL_SKIP)"
[ "$LOCAL_FAIL" -eq 0 ]
