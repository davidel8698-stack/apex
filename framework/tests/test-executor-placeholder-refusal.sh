#!/usr/bin/env bash
# R16-627 (F-627, IMP-027):
# executor PRE-EXECUTION PREMISE GUARD — placeholder scan test.
#
# Spec anchor (apex-spec.md after R16 amendment):
#   "framework/agents/executor.md (טרום-execution check) חייב לחסום
#    משימה שב-task XML שלה placeholders."
#
# This test is a static / prose-anchor verifier — it does NOT invoke
# the executor LLM agent. It verifies the placeholder scan prose,
# the eight-family regex set, the refusal path with
# reason=placeholder_in_task_xml, co-location with R-623E's
# phantom-input guard, scope guard against XML tag false-positives,
# and Wave 6 / earlier-wave preservation.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXECUTOR="$REPO_ROOT/framework/agents/executor.md"

LOCAL_PASS=0
LOCAL_FAIL=0
LOCAL_SKIP=0
ok()   { echo "  ✅ $1"; LOCAL_PASS=$((LOCAL_PASS+1)); }
nope() { echo "  ❌ $1"; LOCAL_FAIL=$((LOCAL_FAIL+1)); }
skip() { echo "  ⏭  $1"; LOCAL_SKIP=$((LOCAL_SKIP+1)); }

echo "=== R16-627: executor PLACEHOLDER SCAN refusal test ==="

if [ ! -f "$EXECUTOR" ]; then
  nope "0: executor.md missing"
  echo "$LOCAL_PASS/$((LOCAL_PASS+LOCAL_FAIL)) passed (skipped: $LOCAL_SKIP)"
  exit 1
fi
ok "0: executor.md exists"

# --- A. Section identity and co-location with R-623E ---------------
if grep -qE "PLACEHOLDER SCAN" "$EXECUTOR"; then
  ok "A1: executor.md declares PLACEHOLDER SCAN subsection"
else
  nope "A1: executor.md missing PLACEHOLDER SCAN subsection"
fi
if grep -qE "PRE-EXECUTION PREMISE GUARD" "$EXECUTOR"; then
  ok "A2: PLACEHOLDER SCAN co-located under PRE-EXECUTION PREMISE GUARD"
else
  nope "A2: PRE-EXECUTION PREMISE GUARD parent subsection missing"
fi
if grep -qE "R16-627" "$EXECUTOR"; then
  ok "A3: R16-627 anchor stamped in executor.md"
else
  nope "A3: R16-627 anchor missing"
fi

# --- B. Refusal path with reason=placeholder_in_task_xml ----------
if grep -qE "placeholder_in_task_xml" "$EXECUTOR"; then
  ok "B1: refusal reason 'placeholder_in_task_xml' declared"
else
  nope "B1: refusal reason 'placeholder_in_task_xml' missing"
fi
if grep -qE "issues_found" "$EXECUTOR"; then
  ok "B2: refusal records issues_found[] entry"
else
  nope "B2: issues_found[] recording missing"
fi

# --- C. Eight-family placeholder regex set (per IMP-027) ----------
# Family 1: angle-bracket all-caps
if grep -qE 'FEATURE_NAME|API_KEY|<\[A-Z' "$EXECUTOR"; then
  ok "C1: family — angle-bracket all-caps placeholder"
else
  nope "C1: family — angle-bracket all-caps placeholder missing"
fi
# Family 2: mustache
if grep -qE 'mustache|\{\{[A-Z_]' "$EXECUTOR"; then
  ok "C2: family — mustache-style placeholder"
else
  nope "C2: family — mustache-style placeholder missing"
fi
# Family 3: shell ${...}
if grep -qE 'shell-style|\$\{[A-Z_]' "$EXECUTOR"; then
  ok "C3: family — shell-style \${...} placeholder"
else
  nope "C3: family — shell-style placeholder missing"
fi
# Family 4: [INSERT
if grep -qE '\[INSERT' "$EXECUTOR"; then
  ok "C4: family — [INSERT marker"
else
  nope "C4: family — [INSERT marker missing"
fi
# Family 5: [PLACEHOLDER
if grep -qE '\[PLACEHOLDER' "$EXECUTOR"; then
  ok "C5: family — [PLACEHOLDER marker"
else
  nope "C5: family — [PLACEHOLDER marker missing"
fi
# Family 6: [TODO (input form) AND XXX AND FIXME
if grep -qE '\[TODO' "$EXECUTOR"; then
  ok "C6: family — [TODO input marker"
else
  nope "C6: family — [TODO input marker missing"
fi
if grep -qE '\bXXX\b' "$EXECUTOR"; then
  ok "C7: family — XXX word-boundary marker"
else
  nope "C7: family — XXX marker missing"
fi
if grep -qE 'FIXME' "$EXECUTOR"; then
  ok "C8: family — FIXME word-boundary marker"
else
  nope "C8: family — FIXME marker missing"
fi

# --- D. Scope guard (must not false-block legitimate XML tags) ----
if grep -qE "scope guard|XML.tag false-positive|tag header|text node" "$EXECUTOR"; then
  ok "D1: scope guard against XML tag false-positives documented"
else
  nope "D1: scope guard missing — \`<ACTION>\` etc. would false-block"
fi
# Documented exemption for ${HOME} / ${PWD} etc. in <verify_command>.
if grep -qE 'HOME|PWD|CURRENT_PHASE|TASK_ID' "$EXECUTOR"; then
  ok "D2: shell-variable exemption documented (HOME/PWD/CURRENT_PHASE/TASK_ID)"
else
  nope "D2: shell-variable exemption missing"
fi

# --- E. Co-located scan pass with phantom-input guard -------------
if grep -qE "one scan pass|share one scan|same scan|union" "$EXECUTOR"; then
  ok "E1: union scan with phantom-input guard documented (single pass)"
else
  nope "E1: shared scan-pass design not documented"
fi
# Precedence rule (phantom-input wins on collision).
if grep -qE "phantom-input takes precedence|precedence" "$EXECUTOR"; then
  ok "E2: collision precedence rule documented"
else
  nope "E2: collision precedence rule missing"
fi

# --- F. Ordering: PLACEHOLDER SCAN must appear AFTER STEP 0 anchor
#     and BEFORE BEFORE WRITING CODE. -----------------------------
STEP_0_LINE=$(grep -nE "## STEP 0 — ANCHOR CAPTURE" "$EXECUTOR" | head -1 | cut -d: -f1)
PLACEHOLDER_LINE=$(grep -nE "PLACEHOLDER SCAN" "$EXECUTOR" | head -1 | cut -d: -f1)
BEFORE_WRITING_LINE=$(grep -nE "^## BEFORE WRITING CODE" "$EXECUTOR" | head -1 | cut -d: -f1)
if [ -n "$STEP_0_LINE" ] && [ -n "$PLACEHOLDER_LINE" ] && [ -n "$BEFORE_WRITING_LINE" ] \
   && [ "$STEP_0_LINE" -lt "$PLACEHOLDER_LINE" ] && [ "$PLACEHOLDER_LINE" -lt "$BEFORE_WRITING_LINE" ]; then
  ok "F1: ordering — STEP 0 ($STEP_0_LINE) < PLACEHOLDER SCAN ($PLACEHOLDER_LINE) < BEFORE WRITING ($BEFORE_WRITING_LINE)"
else
  nope "F1: ordering broken (STEP 0@$STEP_0_LINE, PLACEHOLDER@$PLACEHOLDER_LINE, BEFORE WRITING@$BEFORE_WRITING_LINE)"
fi

# --- G. Preservation of earlier waves' wins ----------------------
# R-602 (STEP 0 anchor capture)
if grep -qE "ANCHOR CAPTURE" "$EXECUTOR"; then
  ok "G1: R-602 STEP 0 ANCHOR CAPTURE preserved"
else
  nope "G1: R-602 STEP 0 ANCHOR CAPTURE missing — preservation broken"
fi
# R-623E (phantom-input guard)
if grep -qE "the attached|the provided|the given" "$EXECUTOR"; then
  ok "G2: R-623E phantom-input regex preserved"
else
  nope "G2: R-623E phantom-input regex disturbed"
fi
if grep -qE "missing_referenced_data" "$EXECUTOR"; then
  ok "G3: R-623E refusal reason 'missing_referenced_data' preserved"
else
  nope "G3: R-623E refusal reason missing"
fi
# R-607 (TERMINATION OUTCOME CLASSIFIER)
if grep -qE "TERMINATION OUTCOME CLASSIFIER" "$EXECUTOR"; then
  ok "G4: R-607 TERMINATION OUTCOME CLASSIFIER preserved"
else
  nope "G4: R-607 outcome classifier disturbed"
fi
# R-641E (overrefusal categories)
if grep -qE "Expected overrefusal" "$EXECUTOR"; then
  ok "G5: R-641E overrefusal categories preserved"
else
  nope "G5: R-641E overrefusal categories missing"
fi

# --- H. Refusal contract integrity --------------------------------
# RESULT.json on refusal must have status=failure, files_modified=[],
# unverified_criteria=full done list (mirroring R-623E pattern).
if grep -qE '"status":\s*"failure"|status.*failure' "$EXECUTOR"; then
  ok "H1: refusal RESULT.json status=failure declared"
else
  nope "H1: refusal status=failure declaration missing"
fi
if grep -qE 'files_modified.*\[\]|"files_modified":\s*\[\]' "$EXECUTOR"; then
  ok "H2: refusal files_modified=[] declared (no writes on refusal)"
else
  nope "H2: refusal files_modified=[] declaration missing"
fi

# --- Bridge to harness globals ----------------------------------
if declare -F harness_assert_corpus >/dev/null 2>&1; then
  LOCAL_TOTAL=$((LOCAL_PASS + LOCAL_FAIL))
  harness_assert_corpus "$LOCAL_PASS" "$LOCAL_TOTAL" "executor placeholder-refusal scan" 100
fi

LOCAL_TOTAL=$((LOCAL_PASS+LOCAL_FAIL))
echo ""
echo "$LOCAL_PASS/$LOCAL_TOTAL passed (skipped: $LOCAL_SKIP)"
[ "$LOCAL_FAIL" -eq 0 ]
