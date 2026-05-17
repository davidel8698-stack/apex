#!/usr/bin/env bash
# Phase 12.06 — M10 severity-tier emitter test.
#
# Verifies the structural contract of _emit_apex_event.sh +
# background-digest-hook.sh + the SEVERITY-REGISTRY.md, plus
# end-to-end behaviour of the emitter in a sandbox project root.
#
# Harness contract (R10-008): arithmetic increment of PASS/FAIL/TOTAL.
# No EXIT trap (would overwrite harness_export_counters).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EMIT_LIB="$REPO_ROOT/framework/hooks/_emit_apex_event.sh"
DIGEST_SH="$REPO_ROOT/framework/hooks/background-digest-hook.sh"
REGISTRY="$REPO_ROOT/framework/docs/SEVERITY-REGISTRY.md"
STATE_SCHEMA="$REPO_ROOT/framework/schemas/STATE.schema.json"
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.06 — M10 severity tiers ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required for this test"
  exit 1
fi

# --- C-1: _emit_apex_event.sh exists and is sourceable ---
TOTAL=$((TOTAL + 1))
if [ -f "$EMIT_LIB" ] && bash -n "$EMIT_LIB" 2>/dev/null; then
  echo "  ✅ C-1: _emit_apex_event.sh exists and has valid bash syntax"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: _emit_apex_event.sh missing or syntax-invalid"
  exit 1
fi

# --- C-2: sourcing the library defines apex_emit_event ---
TOTAL=$((TOTAL + 1))
OUT=$(bash -c "source '$EMIT_LIB' && type apex_emit_event 2>&1")
if echo "$OUT" | grep -q "apex_emit_event is a function"; then
  echo "  ✅ C-2: sourcing defines apex_emit_event function"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: apex_emit_event not defined after source"
  echo "       Got: $OUT"
  FAIL=$((FAIL + 1))
fi

# --- C-3: invalid severity → exit 2 ---
TOTAL=$((TOTAL + 1))
bash -c "source '$EMIT_LIB' && apex_emit_event INVALID test 'what' 'where' 'why'" >/dev/null 2>&1
RC=$?
if [ "$RC" = "2" ]; then
  echo "  ✅ C-3: invalid severity → exit 2 (rejected)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: expected exit 2 on invalid severity, got $RC"
  FAIL=$((FAIL + 1))
fi

# --- C-4: missing required args → exit 2 ---
TOTAL=$((TOTAL + 1))
bash -c "source '$EMIT_LIB' && apex_emit_event CRITICAL" >/dev/null 2>&1
RC=$?
if [ "$RC" = "2" ]; then
  echo "  ✅ C-4: missing required args → exit 2"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: expected exit 2 on missing args, got $RC"
  FAIL=$((FAIL + 1))
fi

# Set up a sandbox project to exercise emit + log behavior.
SANDBOX=$(mktemp -d)
mkdir -p "$SANDBOX/.apex"
echo '{
  "autonomy": {"by_verify_level": {"A":{"level":0,"consecutive_successes":0},"B":{"level":0,"consecutive_successes":0},"C":{"level":0,"consecutive_successes":0},"D":{"level":0,"consecutive_successes":0}}},
  "severity": {"critical_budget_window": [], "digest_state": {"last_digest_at": null, "pending_minor_count": 0}}
}' > "$SANDBOX/.apex/STATE.json"

# --- C-5: CRITICAL emit writes to stdout + event-log + bumps budget ---
# Use a substring grep that avoids multibyte glyph matching inconsistency
# across coreutils builds. The glyph is present; we check the literal
# "CRITICAL [hook]" structural label which is also human-readable.
TOTAL=$((TOTAL + 1))
OUT=$(cd "$SANDBOX" && bash -c "source '$EMIT_LIB' && apex_emit_event CRITICAL phantom-check 'fake-completion language detected' 'SUMMARY.md' 'verdict wrong, retry needed'" 2>/dev/null)
if printf '%s' "$OUT" | grep -q 'CRITICAL \[phantom-check\]'; then
  echo "  ✅ C-5: CRITICAL emit produces stdout line"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: CRITICAL stdout line not emitted"
  echo "       Got: $OUT"
  FAIL=$((FAIL + 1))
fi

# --- C-6: event-log.jsonl gained one entry ---
TOTAL=$((TOTAL + 1))
LOG="$SANDBOX/.apex/event-log.jsonl"
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -ge 1 ]; then
  echo "  ✅ C-6: event-log.jsonl gained at least 1 entry"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: event-log.jsonl missing or empty"
  FAIL=$((FAIL + 1))
fi

# --- C-7: event has all required fields (ts, severity, hook, what, where, why, dedup_key, next_actions, count) ---
TOTAL=$((TOTAL + 1))
if [ -f "$LOG" ]; then
  REQUIRED_KEYS=$(head -1 "$LOG" | jq -r 'keys | join(",")' 2>/dev/null)
  needed="count,dedup_key,hook,next_actions,severity,ts,what,where,why"
  if [ "$REQUIRED_KEYS" = "$needed" ]; then
    echo "  ✅ C-7: event JSON contains all required fields"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-7: event keys mismatch — got '$REQUIRED_KEYS' expected '$needed'"
    FAIL=$((FAIL + 1))
  fi
else
  echo "  ❌ C-7: event-log absent for key check"
  FAIL=$((FAIL + 1))
fi

# --- C-8: STATE.severity.critical_budget_window incremented to 1 ---
TOTAL=$((TOTAL + 1))
BUDGET_LEN=$(jq -r '.severity.critical_budget_window | length' "$SANDBOX/.apex/STATE.json" 2>/dev/null)
if [ "$BUDGET_LEN" = "1" ]; then
  echo "  ✅ C-8: critical_budget_window length = 1 after first CRITICAL"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: expected critical_budget_window length=1, got '$BUDGET_LEN'"
  FAIL=$((FAIL + 1))
fi

# --- C-9: MAJOR emit is silent on stdout but appends event-log ---
TOTAL=$((TOTAL + 1))
LOG_LEN_BEFORE=$(wc -l < "$LOG")
OUT=$(cd "$SANDBOX" && bash -c "source '$EMIT_LIB' && apex_emit_event MAJOR ci-scan 'advisory finding' 'src/auth.ts:42' 'review at next boundary' 'ci-scan-advisory-1'" 2>/dev/null)
LOG_LEN_AFTER=$(wc -l < "$LOG")
if [ -z "$OUT" ] && [ "$LOG_LEN_AFTER" -gt "$LOG_LEN_BEFORE" ]; then
  echo "  ✅ C-9: MAJOR emit is silent on stdout but appends event-log"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: MAJOR contract violated (stdout='$OUT', log grew by $((LOG_LEN_AFTER - LOG_LEN_BEFORE)))"
  FAIL=$((FAIL + 1))
fi

# --- C-10: MINOR emit is silent on stdout but appends event-log ---
TOTAL=$((TOTAL + 1))
LOG_LEN_BEFORE=$(wc -l < "$LOG")
OUT=$(cd "$SANDBOX" && bash -c "source '$EMIT_LIB' && apex_emit_event MINOR post-write 'style fixups applied' 'src/api.ts' 'routine'" 2>/dev/null)
LOG_LEN_AFTER=$(wc -l < "$LOG")
if [ -z "$OUT" ] && [ "$LOG_LEN_AFTER" -gt "$LOG_LEN_BEFORE" ]; then
  echo "  ✅ C-10: MINOR emit is silent on stdout but appends event-log"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-10: MINOR contract violated"
  FAIL=$((FAIL + 1))
fi

# --- C-11: dedup window — repeat of same (hook, severity, dedup_key) within 5 min is suppressed ---
TOTAL=$((TOTAL + 1))
LOG_LEN_BEFORE=$(wc -l < "$LOG")
# Repeat the same MAJOR emit immediately.
(cd "$SANDBOX" && bash -c "source '$EMIT_LIB' && apex_emit_event MAJOR ci-scan 'advisory finding' 'src/auth.ts:42' 'review at next boundary' 'ci-scan-advisory-1'" >/dev/null 2>&1)
LOG_LEN_AFTER=$(wc -l < "$LOG")
if [ "$LOG_LEN_AFTER" = "$LOG_LEN_BEFORE" ]; then
  echo "  ✅ C-11: dedup window suppresses same (hook, severity, dedup_key) within 5 min"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: dedup failed — log grew by $((LOG_LEN_AFTER - LOG_LEN_BEFORE)) on repeat"
  FAIL=$((FAIL + 1))
fi

# --- C-12: SEVERITY-REGISTRY.md exists with 3-tier framing ---
TOTAL=$((TOTAL + 1))
if [ -f "$REGISTRY" ] && \
   grep -q "### CRITICAL" "$REGISTRY" && \
   grep -q "### MAJOR" "$REGISTRY" && \
   grep -q "### MINOR" "$REGISTRY"; then
  echo "  ✅ C-12: SEVERITY-REGISTRY.md present with CRITICAL/MAJOR/MINOR sections"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-12: SEVERITY-REGISTRY.md missing or incomplete"
  FAIL=$((FAIL + 1))
fi

# --- C-13: STATE schema declares severity.critical_budget_window + severity.digest_state ---
TOTAL=$((TOTAL + 1))
if jq -e '
  .properties.severity.properties.critical_budget_window.type == "array" and
  .properties.severity.properties.digest_state.type == "object"
' "$STATE_SCHEMA" >/dev/null 2>&1; then
  echo "  ✅ C-13: STATE schema declares severity.critical_budget_window + severity.digest_state"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-13: STATE schema severity block missing or malformed"
  FAIL=$((FAIL + 1))
fi

# --- C-14: background-digest-hook.sh exists and is syntax-valid ---
TOTAL=$((TOTAL + 1))
if [ -x "$DIGEST_SH" ] && bash -n "$DIGEST_SH" 2>/dev/null; then
  echo "  ✅ C-14: background-digest-hook.sh exists and is executable"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-14: background-digest-hook.sh missing or syntax-invalid"
  FAIL=$((FAIL + 1))
fi

# --- C-15: digest hook produces a digest line on the sandbox event log ---
TOTAL=$((TOTAL + 1))
DIGEST_OUT=$(cd "$SANDBOX" && bash "$DIGEST_SH" --since "1970-01-01T00:00:00Z" 2>&1)
if echo "$DIGEST_OUT" | grep -qE 'MINOR digest'; then
  echo "  ✅ C-15: background-digest-hook emits digest banner"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-15: digest hook did not emit expected banner"
  echo "       Got: $DIGEST_OUT"
  FAIL=$((FAIL + 1))
fi

# --- C-16: HOOK-CLASSIFICATION.md lists both new Phase 12.06 hooks ---
TOTAL=$((TOTAL + 1))
if grep -q '_emit_apex_event.sh' "$HOOK_CLASS" && \
   grep -q 'background-digest-hook.sh' "$HOOK_CLASS"; then
  echo "  ✅ C-16: HOOK-CLASSIFICATION.md lists _emit_apex_event.sh and background-digest-hook.sh"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-16: one or both new hooks missing from HOOK-CLASSIFICATION.md"
  FAIL=$((FAIL + 1))
fi

# Cleanup
rm -rf "$SANDBOX"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
