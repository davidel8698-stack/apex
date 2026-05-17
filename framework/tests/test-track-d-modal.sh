#!/usr/bin/env bash
# Phase 12.02 — M08.1 track-d-modal.sh behaviour test.
#
# Verifies the plain-language Track D modal hook respects its design
# contract: safe default (Enter → לא, עצור / decline), rate-limit
# (1 modal / 30 min), batching to .apex/pending_track_d.json, digest
# mode after budget exceeded, and plain-language compliance (no
# dev-jargon tokens in the modal text).
#
# Harness contract (R10-008): no file-scope shadowing of PASS / FAIL /
# TOTAL / SKIP.
#
# Spec anchor: PLAN.md task 12.02 §5-§6 (M08.1 ideal functioning +
# right fix path); apex-spec.md §"עקרונות העבודה" (plain-language UX).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MODAL_SH="$REPO_ROOT/framework/hooks/track-d-modal.sh"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found at $SCRIPT_DIR/_harness.sh"
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.02 — M08.1 track-d-modal ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required for this test"
  exit 1
fi

# --- C-1: hook exists and is executable ---
TOTAL=$((TOTAL + 1))
if [ -x "$MODAL_SH" ]; then
  echo "  ✅ C-1: track-d-modal.sh exists and is executable"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: track-d-modal.sh missing or not executable at $MODAL_SH"
  exit 1
fi

# --- C-2: bash syntax valid ---
TOTAL=$((TOTAL + 1))
if bash -n "$MODAL_SH" 2>/dev/null; then
  echo "  ✅ C-2: track-d-modal.sh bash syntax valid"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: track-d-modal.sh bash syntax error"
  FAIL=$((FAIL + 1))
fi

# --- C-3: missing args → exit 3 (invocation error) ---
TOTAL=$((TOTAL + 1))
bash "$MODAL_SH" </dev/null >/dev/null 2>&1
RC=$?
if [ "$RC" = "3" ]; then
  echo "  ✅ C-3: missing args → exit 3 (invocation error)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: missing args expected exit 3, got $RC"
  FAIL=$((FAIL + 1))
fi

# Set up an isolated workdir so STATE writes don't touch the live project.
# NOTE: NO EXIT trap. The harness installs its own harness_export_counters
# EXIT trap (R9-013); a test-installed trap silently overwrites it and the
# per-file PASS/FAIL counters never reach the sidecar. Cleanup is left
# implicit (mktemp -d places sandbox under TMPDIR which the OS reaps).
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/.apex"
echo '{
  "autonomy": {
    "by_task_class": {
      "A": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0},
      "B": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0},
      "C": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0},
      "D": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0}
    },
    "track_d_modal_state": {
      "modals_today": 0,
      "last_modal_at": null,
      "pending_count": 0,
      "digest_mode": false
    }
  }
}' > "$SANDBOX/.apex/STATE.json"

# --- C-4: default-on-Enter (no TTY → no input) = decline (exit 1) ---
TOTAL=$((TOTAL + 1))
(
  cd "$SANDBOX"
  bash "$MODAL_SH" "12.99" "Test invocation — please decline" "false" </dev/null >/dev/null 2>&1
)
RC=$?
if [ "$RC" = "1" ]; then
  echo "  ✅ C-4: no-TTY default = decline (exit 1) — safe default honored"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: expected exit 1 on no-TTY default, got $RC"
  FAIL=$((FAIL + 1))
fi

# --- C-5: STATE.autonomy.track_d_modal_state.modals_today incremented to 1 ---
TOTAL=$((TOTAL + 1))
MODALS=$(jq -r '.autonomy.track_d_modal_state.modals_today' "$SANDBOX/.apex/STATE.json" 2>/dev/null)
if [ "$MODALS" = "1" ]; then
  echo "  ✅ C-5: STATE.autonomy.track_d_modal_state.modals_today incremented to 1 after first modal"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: expected modals_today=1, got '$MODALS'"
  FAIL=$((FAIL + 1))
fi

# --- C-6: STATE.autonomy.track_d_modal_state.last_modal_at populated ---
TOTAL=$((TOTAL + 1))
LAST_AT=$(jq -r '.autonomy.track_d_modal_state.last_modal_at' "$SANDBOX/.apex/STATE.json" 2>/dev/null)
if [ -n "$LAST_AT" ] && [ "$LAST_AT" != "null" ]; then
  echo "  ✅ C-6: last_modal_at set to RFC 3339 timestamp ($LAST_AT)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: last_modal_at not populated"
  FAIL=$((FAIL + 1))
fi

# --- C-7: 2nd call within 30 min is rate-limited (exit 2) and queued ---
TOTAL=$((TOTAL + 1))
(
  cd "$SANDBOX"
  bash "$MODAL_SH" "12.100" "Second event within 30 min — must batch" "false" </dev/null >/dev/null 2>&1
)
RC=$?
if [ "$RC" = "2" ]; then
  echo "  ✅ C-7: 2nd modal within 30 min → exit 2 (rate-limited / batched)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: expected exit 2 on rate-limit, got $RC"
  FAIL=$((FAIL + 1))
fi

# --- C-8: pending_track_d.json contains the queued event ---
TOTAL=$((TOTAL + 1))
QUEUE="$SANDBOX/.apex/pending_track_d.json"
if [ -f "$QUEUE" ]; then
  QUEUED=$(jq -r '[.events[] | select(.task_id == "12.100")] | length' "$QUEUE" 2>/dev/null)
  if [ "$QUEUED" = "1" ]; then
    echo "  ✅ C-8: pending_track_d.json contains the rate-limited event"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-8: expected 1 queued event for task 12.100, got '$QUEUED'"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  ❌ C-8: pending_track_d.json not created"
  FAIL=$((FAIL + 1))
fi

# --- C-9: is_irreversible_now=true bypasses rate-limit (immediate prompt, no batch) ---
TOTAL=$((TOTAL + 1))
(
  cd "$SANDBOX"
  bash "$MODAL_SH" "12.101" "Irreversible NOW — must NOT batch" "true" </dev/null >/dev/null 2>&1
)
RC=$?
# Default on Enter = decline → exit 1. Critical: NOT 2 (would mean batched).
if [ "$RC" = "1" ]; then
  echo "  ✅ C-9: is_irreversible_now=true bypasses batching (exit 1, not 2)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: is_irreversible_now=true should bypass batching; expected exit 1, got $RC"
  FAIL=$((FAIL + 1))
fi

# --- C-10: plain-language scan — modal output is Hebrew-framed, no dev jargon ---
TOTAL=$((TOTAL + 1))
# Reset state so the next modal isn't rate-limited.
echo '{
  "autonomy": {
    "by_task_class": {
      "A": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0},
      "B": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0},
      "C": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0},
      "D": {"level":0,"consecutive_successes":0,"high_rework_streak":0,"critic_disagreements_recent":0}
    },
    "track_d_modal_state": {
      "modals_today": 0,
      "last_modal_at": null,
      "pending_count": 0,
      "digest_mode": false
    }
  }
}' > "$SANDBOX/.apex/STATE.json"
MODAL_OUT=$(cd "$SANDBOX" && bash "$MODAL_SH" "12.102" "Run database backup" "false" </dev/null 2>/dev/null)
# Dev-jargon patterns that MUST NOT appear in the modal text.
JARGON_RE='verify_level|task_class|EFFECTIVE_LEVEL|autonomy.by_|cap=|consecutive_successes|by_verify_level'
if echo "$MODAL_OUT" | grep -qE "$JARGON_RE"; then
  echo "  ❌ C-10: modal output contains dev-jargon — failed plain-language scan"
  echo "       Offending lines:"
  echo "$MODAL_OUT" | grep -E "$JARGON_RE" | head -3 | sed 's/^/         /'
  FAIL=$((FAIL + 1))
else
  echo "  ✅ C-10: modal output is dev-jargon-free (plain-language compliant)"
  PASS=$((PASS + 1))
fi

# --- C-11: modal output contains Hebrew framing (פעולה, להמשיך, עצור) ---
TOTAL=$((TOTAL + 1))
if echo "$MODAL_OUT" | grep -q "פעולה" && echo "$MODAL_OUT" | grep -q "להמשיך"; then
  echo "  ✅ C-11: modal output contains Hebrew framing"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: modal output missing Hebrew framing"
  FAIL=$((FAIL + 1))
fi

# --- C-12: digest mode triggers after 3 modals in same UTC day ---
# Reset, fire 3 modals back-to-back with stale last_modal_at to defeat
# rate-limit (set last_modal_at to 2h ago via jq), then check digest_mode.
TOTAL=$((TOTAL + 1))
ANCIENT=$(date -u -d "2 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")
for i in 1 2 3; do
  # Reset last_modal_at to defeat rate-limit before each call.
  TMP=$(mktemp)
  jq --arg ts "$ANCIENT" '.autonomy.track_d_modal_state.last_modal_at = $ts' "$SANDBOX/.apex/STATE.json" > "$TMP" && mv "$TMP" "$SANDBOX/.apex/STATE.json"
  (cd "$SANDBOX" && bash "$MODAL_SH" "12.10$i" "Test digest trigger $i" "false" </dev/null >/dev/null 2>&1)
done
DIGEST=$(jq -r '.autonomy.track_d_modal_state.digest_mode' "$SANDBOX/.apex/STATE.json" 2>/dev/null)
MODALS_AFTER=$(jq -r '.autonomy.track_d_modal_state.modals_today' "$SANDBOX/.apex/STATE.json" 2>/dev/null)
if [ "$DIGEST" = "true" ] && [ "$MODALS_AFTER" = "3" ]; then
  echo "  ✅ C-12: digest_mode=true after 3 modals (modals_today=$MODALS_AFTER)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-12: expected digest_mode=true, modals_today=3; got digest=$DIGEST, modals=$MODALS_AFTER"
  FAIL=$((FAIL + 1))
fi

# Standalone exit semantics
if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
