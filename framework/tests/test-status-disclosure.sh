#!/usr/bin/env bash
# Phase 12.07 — M11 status progressive disclosure test.
#
# Verifies framework/commands/apex/status.md declares the M11
# progressive-disclosure contract structurally. status.md is a
# markdown command spec (executed by Claude Code), so this test
# asserts the *structural* contract: blocks present, branch logic
# named, auto-surface triggers enumerated, 5-signal view defined.
# Behavioural end-to-end (run /apex:status, see 5 lines) is exercised
# by integration runs against the installed command, not here.
#
# Harness contract (R10-008): arithmetic increment of PASS/FAIL/TOTAL
# globals only — no file-scope shadowing, no EXIT trap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATUS_MD="$REPO_ROOT/framework/commands/apex/status.md"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.07 — M11 status progressive disclosure ==="

# --- C-1: STATUS VIEW SELECTION block declared ---
TOTAL=$((TOTAL + 1))
if grep -qE '^## STATUS VIEW SELECTION \[M11' "$STATUS_MD"; then
  echo "  ✅ C-1: STATUS VIEW SELECTION block present"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: STATUS VIEW SELECTION block missing"
  FAIL=$((FAIL + 1))
fi

# --- C-2: 5-SIGNAL DEFAULT VIEW block declared ---
TOTAL=$((TOTAL + 1))
if grep -qE '^## 5-SIGNAL DEFAULT VIEW \(M11\)' "$STATUS_MD"; then
  echo "  ✅ C-2: 5-SIGNAL DEFAULT VIEW block present"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: 5-SIGNAL DEFAULT VIEW block missing"
  FAIL=$((FAIL + 1))
fi

# --- C-3: All 3 view modes named (default / detailed / verbose) ---
TOTAL=$((TOTAL + 1))
if grep -qE 'STATUS_VIEW=="default"' "$STATUS_MD" && \
   grep -qE 'STATUS_VIEW=="detailed"' "$STATUS_MD" && \
   grep -qE 'STATUS_VIEW=="verbose"' "$STATUS_MD"; then
  echo "  ✅ C-3: All 3 view modes (default/detailed/verbose) named in branch logic"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: One or more view modes missing"
  FAIL=$((FAIL + 1))
fi

# --- C-4: CLI flag wins over saved preference (documented contract) ---
TOTAL=$((TOTAL + 1))
if grep -qiE 'CLI flag always wins over saved preference' "$STATUS_MD"; then
  echo "  ✅ C-4: CLI flag precedence documented"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: CLI flag precedence rule missing"
  FAIL=$((FAIL + 1))
fi

# --- C-5: Auto-surface triggers enumerate at least 4 anomaly conditions ---
TOTAL=$((TOTAL + 1))
trigger_count=0
for sig in \
  'spec_drift_count > 0' \
  'circuit_breaker_triggers > 0' \
  'low_confidence_results > 0' \
  'consecutive_failures > 0' \
  'severity == "CRITICAL"'; do
  if grep -qF "$sig" "$STATUS_MD"; then
    trigger_count=$((trigger_count + 1))
  fi
done
if [ "$trigger_count" -ge 4 ]; then
  echo "  ✅ C-5: $trigger_count auto-surface triggers enumerated (≥4 required)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: only $trigger_count auto-surface triggers found (<4)"
  FAIL=$((FAIL + 1))
fi

# --- C-6: 5-signal view defines all 5 lines (Phase / Autonomy / Task / Last verify / Context) ---
TOTAL=$((TOTAL + 1))
sig_count=0
for line in 'Phase {STATE.current_phase' 'Autonomy:' 'Task: {STATE.current_unit' 'Last verify:' 'Context: {gauge_pct'; do
  if grep -qF "$line" "$STATUS_MD"; then
    sig_count=$((sig_count + 1))
  fi
done
if [ "$sig_count" = "5" ]; then
  echo "  ✅ C-6: all 5 signal lines defined in 5-SIGNAL DEFAULT VIEW"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: only $sig_count of 5 signal lines found in default view"
  FAIL=$((FAIL + 1))
fi

# --- C-7: STATUS_PREFS.json contract documented ---
TOTAL=$((TOTAL + 1))
if grep -qE 'STATUS_PREFS\.json' "$STATUS_MD" && \
   grep -qE 'default_view' "$STATUS_MD"; then
  echo "  ✅ C-7: STATUS_PREFS.json contract + default_view key documented"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: STATUS_PREFS.json contract missing or incomplete"
  FAIL=$((FAIL + 1))
fi

# --- C-8: Anomaly surface emits an explicit ALERT line (anomaly auto-surfaced marker) ---
# Pattern uses the substring rather than the bell glyph; grep across multibyte
# emojis is inconsistent across coreutils builds. The glyph is in the doc but
# we check the human-readable label that the renderer emits alongside it.
TOTAL=$((TOTAL + 1))
if grep -qE 'anomaly auto-surfaced' "$STATUS_MD"; then
  echo "  ✅ C-8: anomaly auto-surfaced marker documented"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: anomaly marker missing"
  FAIL=$((FAIL + 1))
fi

# --- C-9: Backward compat — existing-sections regression invariant preserved ---
TOTAL=$((TOTAL + 1))
if grep -qE 'Existing-sections regression invariant' "$STATUS_MD" || \
   grep -qE 'Cockpit Dashboard.*UNCHANGED' "$STATUS_MD"; then
  echo "  ✅ C-9: existing-sections regression invariant preserved (R13-006 contract)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: regression invariant statement missing — risk of silently breaking the cockpit"
  FAIL=$((FAIL + 1))
fi

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
