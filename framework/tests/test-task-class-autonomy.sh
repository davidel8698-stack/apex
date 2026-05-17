#!/usr/bin/env bash
# Phase 12.02 — M08 task-class autonomy test.
#
# Verifies the v8 per-task-class ladder is wired structurally. The
# per-task-class ladder logic lives in framework/commands/apex/next.md
# (a markdown spec executed by Claude Code, not a runnable script), so
# this test asserts the *structural* contract: schemas, ladder blocks,
# migration coverage, and PLAN_META task_class population. Behavioural
# assertions ("5 A → advance to Trusted") are exercised end-to-end by
# self-test integration runs against the installed command, not here.
#
# Harness contract (R10-008): no file-scope shadowing of PASS / FAIL /
# TOTAL / SKIP. Assertions increment the harness globals directly via
# arithmetic.
#
# Spec anchor: apex-spec.md §"היכולות הנדרשות" + §"עקרונות העבודה".
# Source plan: .apex/phases/12-apex-evolution-v8/PLAN.md task 12.02.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_SCHEMA="$REPO_ROOT/framework/schemas/STATE.schema.json"
PLAN_META_SCHEMA="$REPO_ROOT/framework/schemas/PLAN_META.schema.json"
NEXT_MD="$REPO_ROOT/framework/commands/apex/next.md"
ARCHITECT_MD="$REPO_ROOT/framework/agents/architect.md"
RISK_KEYWORDS="$REPO_ROOT/framework/docs/RISK-KEYWORDS.md"
MIGRATE_SH="$REPO_ROOT/framework/scripts/migrate-plan-meta-v8.sh"
PHASE_12_META="$REPO_ROOT/.apex/phases/12-apex-evolution-v8/PLAN_META.json"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found at $SCRIPT_DIR/_harness.sh"
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.02 — M08 task-class autonomy structure ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required for this test"
  exit 1
fi

# --- C-1: STATE schema declares autonomy.by_task_class with all 4 tracks ---
TOTAL=$((TOTAL + 1))
if jq -e '
  .properties.autonomy.properties.by_task_class.properties
  | (has("A") and has("B") and has("C") and has("D"))
' "$STATE_SCHEMA" >/dev/null 2>&1; then
  echo "  ✅ C-1: STATE schema declares autonomy.by_task_class.{A,B,C,D}"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: STATE schema missing autonomy.by_task_class or its A/B/C/D entries"
  FAIL=$((FAIL + 1))
fi

# --- C-2: Each track declares level + consecutive_successes + high_rework_streak + critic_disagreements_recent ---
for track in A B C D; do
  TOTAL=$((TOTAL + 1))
  if jq -e --arg t "$track" '
    .properties.autonomy.properties.by_task_class.properties[$t].required
    | (index("level") != null and index("consecutive_successes") != null and
       index("high_rework_streak") != null and index("critic_disagreements_recent") != null)
  ' "$STATE_SCHEMA" >/dev/null 2>&1; then
    echo "  ✅ C-2/$track: track declares level + consecutive_successes + high_rework_streak + critic_disagreements_recent"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-2/$track: missing required fields on by_task_class.$track"
    FAIL=$((FAIL + 1))
  fi
done

# --- C-3: Track C and Track D level cap at 0 (no auto-escalation per PLAN.md §6) ---
for track in C D; do
  TOTAL=$((TOTAL + 1))
  MAX=$(jq -r --arg t "$track" '.properties.autonomy.properties.by_task_class.properties[$t].properties.level.maximum' "$STATE_SCHEMA")
  if [ "$MAX" = "0" ]; then
    echo "  ✅ C-3/$track: level.maximum = 0 (no auto-escalation)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-3/$track: level.maximum expected 0, got '$MAX'"
    FAIL=$((FAIL + 1))
  fi
done

# --- C-4: Track A and Track B level cap at 2 (Trusted) ---
for track in A B; do
  TOTAL=$((TOTAL + 1))
  MAX=$(jq -r --arg t "$track" '.properties.autonomy.properties.by_task_class.properties[$t].properties.level.maximum' "$STATE_SCHEMA")
  if [ "$MAX" = "2" ]; then
    echo "  ✅ C-4/$track: level.maximum = 2 (Trusted)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-4/$track: level.maximum expected 2, got '$MAX'"
    FAIL=$((FAIL + 1))
  fi
done

# --- C-5: PLAN_META schema declares task_class enum [A,B,C,D] ---
TOTAL=$((TOTAL + 1))
if jq -e '
  .properties.tasks.items.properties.task_class.enum
  | (index("A") != null and index("B") != null and index("C") != null and index("D") != null)
' "$PLAN_META_SCHEMA" >/dev/null 2>&1; then
  echo "  ✅ C-5: PLAN_META schema declares task_class enum [A,B,C,D]"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: PLAN_META schema missing task_class enum"
  FAIL=$((FAIL + 1))
fi

# --- C-6: next.md contains the TRACK D MODAL block ---
TOTAL=$((TOTAL + 1))
if grep -qE "TRACK D MODAL \[M08\.1" "$NEXT_MD"; then
  echo "  ✅ C-6: next.md wires TRACK D MODAL block"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: next.md missing TRACK D MODAL block"
  FAIL=$((FAIL + 1))
fi

# --- C-7: next.md contains the PER-TASK-CLASS LADDER UPDATE block ---
TOTAL=$((TOTAL + 1))
if grep -qE "PER-TASK-CLASS LADDER UPDATE \[M08" "$NEXT_MD"; then
  echo "  ✅ C-7: next.md wires PER-TASK-CLASS LADDER UPDATE on PASS"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: next.md missing PER-TASK-CLASS LADDER UPDATE block"
  FAIL=$((FAIL + 1))
fi

# --- C-8: next.md contains the PER-TASK-CLASS DE-ESCALATION block ---
TOTAL=$((TOTAL + 1))
if grep -qE "PER-TASK-CLASS DE-ESCALATION \[M08" "$NEXT_MD"; then
  echo "  ✅ C-8: next.md wires PER-TASK-CLASS DE-ESCALATION on FAIL"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: next.md missing PER-TASK-CLASS DE-ESCALATION block"
  FAIL=$((FAIL + 1))
fi

# --- C-9: next.md preserves by_verify_level fallback (backward compat) ---
TOTAL=$((TOTAL + 1))
if grep -qE "STATE\.autonomy\.by_verify_level\[verify_level\]" "$NEXT_MD"; then
  echo "  ✅ C-9: next.md preserves by_verify_level v7 fallback (backward compat)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: next.md missing by_verify_level fallback — backward compat broken"
  FAIL=$((FAIL + 1))
fi

# --- C-10: architect.md declares Step 1.10 task-class classification ---
TOTAL=$((TOTAL + 1))
if grep -qE "## STEP 1\.10: Task-Class Classification" "$ARCHITECT_MD"; then
  echo "  ✅ C-10: architect.md declares Step 1.10 task-class classification"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-10: architect.md missing Step 1.10 task-class classification"
  FAIL=$((FAIL + 1))
fi

# --- C-11: RISK-KEYWORDS.md exists and covers all 4 classes ---
TOTAL=$((TOTAL + 1))
if [ -f "$RISK_KEYWORDS" ] && \
   grep -q "## Class A" "$RISK_KEYWORDS" && \
   grep -q "## Class B" "$RISK_KEYWORDS" && \
   grep -q "## Class C" "$RISK_KEYWORDS" && \
   grep -q "## Class D" "$RISK_KEYWORDS"; then
  echo "  ✅ C-11: RISK-KEYWORDS.md exists with sections for all 4 classes"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: RISK-KEYWORDS.md missing or incomplete"
  FAIL=$((FAIL + 1))
fi

# --- C-12: migrate-plan-meta-v8.sh exists and is executable ---
TOTAL=$((TOTAL + 1))
if [ -x "$MIGRATE_SH" ]; then
  echo "  ✅ C-12: migrate-plan-meta-v8.sh exists and is executable"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-12: migrate-plan-meta-v8.sh missing or not executable"
  FAIL=$((FAIL + 1))
fi

# --- C-13: Phase 12 PLAN_META has task_class on every task ---
TOTAL=$((TOTAL + 1))
if [ -f "$PHASE_12_META" ]; then
  MISSING=$(jq '[.tasks[] | select(has("task_class") | not)] | length' "$PHASE_12_META")
  TOTAL_TASKS=$(jq '.tasks | length' "$PHASE_12_META")
  if [ "$MISSING" = "0" ] && [ "$TOTAL_TASKS" = "13" ]; then
    echo "  ✅ C-13: Phase 12 PLAN_META — all 13 tasks declare task_class"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-13: Phase 12 PLAN_META — $MISSING/$TOTAL_TASKS tasks missing task_class"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  ❌ C-13: Phase 12 PLAN_META not found at $PHASE_12_META"
  FAIL=$((FAIL + 1))
fi

# --- C-14: TRACK D DYNAMIC OVERRIDE wired (is_irreversible_now handling) ---
TOTAL=$((TOTAL + 1))
if grep -qE "TRACK D DYNAMIC OVERRIDE \[M08" "$NEXT_MD" && \
   grep -qE "is_irreversible_now" "$NEXT_MD"; then
  echo "  ✅ C-14: next.md handles is_irreversible_now dynamic Track D override"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-14: next.md missing is_irreversible_now override path"
  FAIL=$((FAIL + 1))
fi

# Standalone exit semantics
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
