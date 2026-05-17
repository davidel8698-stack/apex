#!/usr/bin/env bash
# Phase 12.05 — M09 comprehension gate test.
#
# Verifies:
#   C-1: comprehension-gate.sh exists + executable + syntax-valid.
#   C-2: missing args → exit 2.
#   C-3: invalid task_class → exit 2.
#   C-4: Track A → depth 0 → skipped (exit 0, no prompt).
#   C-5: Track D skip with --force → exit 1 (structurally prohibited).
#   C-6: defer (default on no-TTY) → exit 0.
#   C-7: STATE.comprehension_gates.history entry appended.
#   C-8: skip event logged at MAJOR severity to event-log.jsonl
#        (cognitive_debt.skip type for User Decision #5 data).
#   C-9: STATE schema declares comprehension_gates.history array with
#        the required per-entry fields.
#   C-10: next.md replaced LOC-based gate with M09 dispatch
#         (no more "LARGEST_DIFFS" or "top 3 changed files").
#   C-11: next.md invokes comprehension-gate.sh via the new block.
#
# Harness contract (R10-008): arithmetic globals, no EXIT trap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GATE_SH="$REPO_ROOT/framework/hooks/comprehension-gate.sh"
NEXT_MD="$REPO_ROOT/framework/commands/apex/next.md"
STATE_SCHEMA="$REPO_ROOT/framework/schemas/STATE.schema.json"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.05 — M09 comprehension gate ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required"
  exit 1
fi

# --- C-1: hook exists + executable + syntax-valid ---
TOTAL=$((TOTAL + 1))
if [ -x "$GATE_SH" ] && bash -n "$GATE_SH" 2>/dev/null; then
  echo "  ✅ C-1: comprehension-gate.sh exists, executable, syntax-valid"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: comprehension-gate.sh missing or broken"
  exit 1
fi

# --- C-2: missing args → exit 2 ---
TOTAL=$((TOTAL + 1))
bash "$GATE_SH" </dev/null >/dev/null 2>&1
RC=$?
if [ "$RC" = "2" ]; then
  echo "  ✅ C-2: missing args → exit 2"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: expected exit 2 on missing args, got $RC"
  FAIL=$((FAIL + 1))
fi

# --- C-3: invalid task_class → exit 2 ---
TOTAL=$((TOTAL + 1))
bash "$GATE_SH" "12" "Z" </dev/null >/dev/null 2>&1
RC=$?
if [ "$RC" = "2" ]; then
  echo "  ✅ C-3: invalid task_class → exit 2"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: expected exit 2 on invalid task_class, got $RC"
  FAIL=$((FAIL + 1))
fi

# Sandbox for state writes.
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/.apex"
echo '{
  "comprehension_gates": {"current_gate_required": null}
}' > "$SANDBOX/.apex/STATE.json"

# --- C-4: Track A → exit 0, no prompt (DEPTH=0 skip) ---
TOTAL=$((TOTAL + 1))
OUT=$(cd "$SANDBOX" && bash "$GATE_SH" "12" "A" </dev/null 2>&1)
RC=$?
if [ "$RC" = "0" ] && echo "$OUT" | grep -q "Track A"; then
  echo "  ✅ C-4: Track A → exit 0 + skipped message"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: expected exit 0 with skip message; got rc=$RC, out=$OUT"
  FAIL=$((FAIL + 1))
fi

# --- C-5: Track D + --force skip → exit 1 (structurally prohibited) ---
TOTAL=$((TOTAL + 1))
(cd "$SANDBOX" && bash "$GATE_SH" "12" "D" "--force" </dev/null >/dev/null 2>&1)
RC=$?
if [ "$RC" = "1" ]; then
  echo "  ✅ C-5: Track D --force skip → exit 1 (structurally prohibited)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: Track D --force skip should be exit 1, got $RC"
  FAIL=$((FAIL + 1))
fi

# --- C-6: Track B no-TTY default = defer → exit 0 ---
TOTAL=$((TOTAL + 1))
(cd "$SANDBOX" && bash "$GATE_SH" "12" "B" </dev/null >/dev/null 2>&1)
RC=$?
if [ "$RC" = "0" ]; then
  echo "  ✅ C-6: Track B no-TTY default = defer (exit 0)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: expected exit 0 for defer default, got $RC"
  FAIL=$((FAIL + 1))
fi

# --- C-7: STATE.comprehension_gates.history populated after the Track B defer ---
TOTAL=$((TOTAL + 1))
HIST_LEN=$(jq -r '.comprehension_gates.history | length' "$SANDBOX/.apex/STATE.json" 2>/dev/null)
if [ "$HIST_LEN" = "1" ]; then
  echo "  ✅ C-7: comprehension_gates.history has 1 entry after defer"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: expected history length 1, got '$HIST_LEN'"
  FAIL=$((FAIL + 1))
fi

# --- C-8: skip event logged with cognitive_debt.skip type ---
# Use Track C (skip is allowed with --force) to exercise the path.
TOTAL=$((TOTAL + 1))
EVENT_LOG="$SANDBOX/.apex/event-log.jsonl"
(cd "$SANDBOX" && bash "$GATE_SH" "12" "C" "--force" <<< "skip" >/dev/null 2>&1)
if [ -f "$EVENT_LOG" ] && grep -q '"type":"cognitive_debt.skip"' "$EVENT_LOG"; then
  echo "  ✅ C-8: cognitive_debt.skip event logged to event-log.jsonl at MAJOR severity"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: cognitive_debt.skip event missing from event-log"
  FAIL=$((FAIL + 1))
fi

# --- C-9: STATE schema declares comprehension_gates.history with required fields ---
TOTAL=$((TOTAL + 1))
if jq -e '
  .properties.comprehension_gates.properties.history.type == "array" and
  (.properties.comprehension_gates.properties.history.items.required
    | (index("gate_id") != null and index("phase") != null and index("track") != null
       and index("depth") != null and index("response") != null and index("timestamp") != null
       and index("format") != null))
' "$STATE_SCHEMA" >/dev/null 2>&1; then
  echo "  ✅ C-9: STATE schema declares comprehension_gates.history with all 7 required fields"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: STATE schema comprehension_gates.history schema incomplete"
  FAIL=$((FAIL + 1))
fi

# --- C-10: next.md replaced LOC-based gate with M09 dispatch ---
TOTAL=$((TOTAL + 1))
# The old LOC selection language ("LARGEST_DIFFS = top 3 changed files by diff size")
# must be gone; the new M09 block must be present.
if ! grep -q 'LARGEST_DIFFS = top 3 changed files by diff size' "$NEXT_MD" && \
   grep -q 'COMPREHENSION GATE \[M09' "$NEXT_MD"; then
  echo "  ✅ C-10: next.md replaced LOC-based gate with M09 risk-based dispatch"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-10: next.md still references LOC-based gate OR missing M09 header"
  FAIL=$((FAIL + 1))
fi

# --- C-11: next.md invokes comprehension-gate.sh ---
TOTAL=$((TOTAL + 1))
if grep -qE 'bash.*hooks/comprehension-gate\.sh' "$NEXT_MD"; then
  echo "  ✅ C-11: next.md invokes comprehension-gate.sh"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: next.md does not invoke comprehension-gate.sh"
  FAIL=$((FAIL + 1))
fi

# Cleanup
rm -rf "$SANDBOX"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
