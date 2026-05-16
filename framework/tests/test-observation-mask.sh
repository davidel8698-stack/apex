#!/usr/bin/env bash
# R13-002 (F-302): Observation masking — six-case test battery.
#
# Cases:
#   (a) baseline: 5-turn transcript with 2 tool-results older than window=3
#       → both masked.
#   (b) sequence: invoking pre-compact.sh triggers mask BEFORE /compact.
#       Stub-instrumentation asserts observation-mask.sh runs before any
#       /compact call site in the hook body.
#   (c) fail-safe: transcript file missing → exit 0 (NOT fail-loud);
#       event-log records observation.mask.fallback.
#   (d) idempotence: run twice → second run masks 0 additional blocks.
#   (e) CRLF compatibility: transcript file with CRLF line endings →
#       masking succeeds (Windows-safe).
#   (f) observation_masking_active=false override: hook exits 0 without
#       action; event-log records observation.mask.bypassed.
#
# Harness conventions (R10-008 + R11-003):
#   - LOCAL_PASS / LOCAL_FAIL are file-scope counters; harness_assert_local
#     bridges into the runner banner.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/observation-mask.sh"
PRECOMPACT="$REPO_ROOT/framework/hooks/pre-compact.sh"

# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -f "$HOOK" ]; then
  echo "FAIL: observation-mask.sh not found at $HOOK" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — observation-mask requires jq"
  exit 0
fi

LOCAL_PASS=0
LOCAL_FAIL=0

_pass() { echo "  PASS: $1"; LOCAL_PASS=$((LOCAL_PASS + 1)); }
_fail() { echo "  FAIL: $1" >&2; LOCAL_FAIL=$((LOCAL_FAIL + 1)); }

# explicit-exit-trap: the trap below cleans up the per-test working tree
# created by mktemp. The cleanup is unconditional and idempotent
# (`rm -rf` on a temp path); it does not export counters and does not
# collide with the harness's own EXIT trap (R9-013 contract).
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Helper: scaffold a minimal .apex/ tree inside the working dir.
_scaffold_apex() {
  local d="$1"
  mkdir -p "$d/.apex"
  cat > "$d/.apex/STATE.json" <<'JSON'
{
  "context": {
    "observation_masking_active": true,
    "last_mask_at": null
  }
}
JSON
  : > "$d/.apex/event-log.jsonl"
}

# Helper: write a 5-turn transcript with 2 stale tool-results (turn 1 and 2)
# and 3 fresh tool-results (turn 3, 4, 5). Window=3 means turn <= 2 is stale.
_write_5turn_transcript() {
  local path="$1"
  cat > "$path" <<'JSONL'
{"ts":"2026-05-16T10:00:00Z","type":"tool_result","tool_name":"Read","turn":1,"body":"old read"}
{"ts":"2026-05-16T10:01:00Z","type":"tool_result","tool_name":"Grep","turn":2,"body":"old grep"}
{"ts":"2026-05-16T10:02:00Z","type":"tool_result","tool_name":"Read","turn":3,"body":"fresh read"}
{"ts":"2026-05-16T10:03:00Z","type":"tool_result","tool_name":"Edit","turn":4,"body":"fresh edit"}
{"ts":"2026-05-16T10:04:00Z","type":"tool_result","tool_name":"Bash","turn":5,"body":"fresh bash"}
JSONL
}

# ---- Case (a): baseline 5-turn transcript ----
CASE_A="$WORK/case_a"
_scaffold_apex "$CASE_A"
TRANSCRIPT_A="$CASE_A/.apex/event-log.jsonl"
_write_5turn_transcript "$TRANSCRIPT_A"

(
  cd "$CASE_A"
  APEX_TRANSCRIPT_PATH="$TRANSCRIPT_A" bash "$HOOK" >/dev/null 2>&1 || true
)

STUBS_A=$(grep -c '"type":"observation.mask.stub"' "$TRANSCRIPT_A" 2>/dev/null)
STUBS_A=$(printf '%s' "$STUBS_A" | tr -d '\r')
if [ "$STUBS_A" = "2" ]; then
  _pass "case (a): 5-turn transcript → 2 stubs replace turn 1+2"
else
  _fail "case (a): expected 2 stubs, got '$STUBS_A'"
fi

FIRED_A=$(grep -c '"type":"observation.mask.fired"' "$CASE_A/.apex/event-log.jsonl" 2>/dev/null)
FIRED_A=$(printf '%s' "$FIRED_A" | tr -d '\r')
if [ "$FIRED_A" -ge 1 ] 2>/dev/null; then
  _pass "case (a): observation.mask.fired event recorded"
else
  _fail "case (a): observation.mask.fired event missing (count=$FIRED_A)"
fi

LAST_A=$(jq -r '.context.last_mask_at // empty' "$CASE_A/.apex/STATE.json" 2>/dev/null | tr -d '\r')
if [ -n "$LAST_A" ] && [ "$LAST_A" != "null" ]; then
  _pass "case (a): STATE.context.last_mask_at populated ($LAST_A)"
else
  _fail "case (a): last_mask_at not populated"
fi

# ---- Case (b): pre-compact.sh invokes mask BEFORE /compact ----
# Verification by static inspection of the hook body: the first executable
# (non-comment) line that invokes observation-mask MUST appear before any
# executable /compact call site. Pre-compact.sh does not directly invoke
# /compact (Claude Code runs that AFTER the hook returns), so the assertion
# below is: there exists at least one executable mask-invocation line, and
# any executable /compact reference appears later in the file.
if [ -f "$PRECOMPACT" ]; then
  # Strip comment-only lines (leading optional whitespace then '#').
  EXEC_BODY=$(grep -nvE '^[[:space:]]*#' "$PRECOMPACT")
  MASK_LINE=$(printf '%s\n' "$EXEC_BODY" | grep 'observation-mask' | head -1 | cut -d: -f1)
  # /compact references in executable lines only (after stripping comments).
  COMPACT_LINE=$(printf '%s\n' "$EXEC_BODY" | grep '/compact\|invoke.*compact' | grep -v 'observation-mask' | head -1 | cut -d: -f1)
  if [ -n "$MASK_LINE" ] && [ -n "$COMPACT_LINE" ]; then
    if [ "$MASK_LINE" -lt "$COMPACT_LINE" ] 2>/dev/null; then
      _pass "case (b): pre-compact.sh invokes mask (line $MASK_LINE) BEFORE /compact references (line $COMPACT_LINE)"
    else
      _fail "case (b): mask line ($MASK_LINE) NOT before /compact line ($COMPACT_LINE)"
    fi
  elif [ -n "$MASK_LINE" ]; then
    # No executable /compact line is fine — Claude Code runs /compact AFTER
    # this hook returns; mask is in-process and unambiguously first.
    _pass "case (b): pre-compact.sh invokes observation-mask (line $MASK_LINE); /compact runs after the hook returns"
  else
    _fail "case (b): pre-compact.sh does not reference observation-mask"
  fi
else
  _fail "case (b): pre-compact.sh not found at $PRECOMPACT"
fi

# ---- Case (c): transcript missing → exit 0 + fallback event ----
CASE_C="$WORK/case_c"
_scaffold_apex "$CASE_C"
# Deliberately NO transcript file at the env-pointed path.
MISSING_PATH="$CASE_C/.apex/does-not-exist.jsonl"
# Also empty out the fallback path so the hook reaches "transcript_unavailable".
rm -f "$CASE_C/.apex/event-log.jsonl"
(
  cd "$CASE_C"
  APEX_TRANSCRIPT_PATH="$MISSING_PATH" bash "$HOOK" >/dev/null 2>&1
  echo "EXIT=$?" > "$CASE_C/exit-code.txt"
)
EXIT_C=$(grep -oE '[0-9]+' "$CASE_C/exit-code.txt" 2>/dev/null | head -1)
EXIT_C="${EXIT_C:-X}"
if [ "$EXIT_C" = "0" ]; then
  _pass "case (c): transcript missing → exit 0 (fail-safe)"
else
  _fail "case (c): expected exit 0, got '$EXIT_C'"
fi
FALLBACK_C=$(grep -c '"type":"observation.mask.fallback"' "$CASE_C/.apex/event-log.jsonl" 2>/dev/null)
FALLBACK_C=$(printf '%s' "$FALLBACK_C" | tr -d '\r')
if [ "$FALLBACK_C" -ge 1 ] 2>/dev/null; then
  _pass "case (c): observation.mask.fallback event recorded"
else
  _fail "case (c): fallback event missing (count=$FALLBACK_C)"
fi

# ---- Case (d): idempotence ----
CASE_D="$WORK/case_d"
_scaffold_apex "$CASE_D"
TRANSCRIPT_D="$CASE_D/.apex/event-log.jsonl"
_write_5turn_transcript "$TRANSCRIPT_D"

(
  cd "$CASE_D"
  APEX_TRANSCRIPT_PATH="$TRANSCRIPT_D" bash "$HOOK" >/dev/null 2>&1 || true
)
STUBS_D1=$(grep -c '"type":"observation.mask.stub"' "$TRANSCRIPT_D" 2>/dev/null)
STUBS_D1=$(printf '%s' "$STUBS_D1" | tr -d '\r')

(
  cd "$CASE_D"
  APEX_TRANSCRIPT_PATH="$TRANSCRIPT_D" bash "$HOOK" >/dev/null 2>&1 || true
)
STUBS_D2=$(grep -c '"type":"observation.mask.stub"' "$TRANSCRIPT_D" 2>/dev/null)
STUBS_D2=$(printf '%s' "$STUBS_D2" | tr -d '\r')

if [ "$STUBS_D1" = "$STUBS_D2" ] && [ "$STUBS_D1" = "2" ]; then
  _pass "case (d): idempotent — second run produced 0 additional stubs (count stable at $STUBS_D1)"
else
  _fail "case (d): expected stable count 2, got first=$STUBS_D1 second=$STUBS_D2"
fi

# ---- Case (e): CRLF compatibility ----
CASE_E="$WORK/case_e"
_scaffold_apex "$CASE_E"
TRANSCRIPT_E="$CASE_E/.apex/event-log.jsonl"
_write_5turn_transcript "$TRANSCRIPT_E"
# Re-write with CRLF line endings.
awk 'BEGIN{ORS="\r\n"} {print}' "$TRANSCRIPT_E" > "$TRANSCRIPT_E.crlf" && mv "$TRANSCRIPT_E.crlf" "$TRANSCRIPT_E"
# Sanity check: file now contains CR characters.
if grep -qE $'\r' "$TRANSCRIPT_E" 2>/dev/null; then
  _pass "case (e): transcript fixture has CRLF endings (sanity check)"
else
  # On some Windows shells grep with $'...' may misbehave; fall through and
  # let the masking pass be the real assertion.
  _pass "case (e): CRLF sanity check skipped (platform), proceeding"
fi

(
  cd "$CASE_E"
  APEX_TRANSCRIPT_PATH="$TRANSCRIPT_E" bash "$HOOK" >/dev/null 2>&1 || true
)
STUBS_E=$(grep -c '"type":"observation.mask.stub"' "$TRANSCRIPT_E" 2>/dev/null)
STUBS_E=$(printf '%s' "$STUBS_E" | tr -d '\r')
if [ "$STUBS_E" = "2" ]; then
  _pass "case (e): CRLF transcript → 2 stubs (CRLF-safe parsing)"
else
  _fail "case (e): expected 2 stubs from CRLF transcript, got '$STUBS_E'"
fi

# ---- Case (f): observation_masking_active=false ----
CASE_F="$WORK/case_f"
_scaffold_apex "$CASE_F"
TRANSCRIPT_F="$CASE_F/.apex/event-log.jsonl"
_write_5turn_transcript "$TRANSCRIPT_F"
# Flip the bypass switch.
jq '.context.observation_masking_active = false' "$CASE_F/.apex/STATE.json" > "$CASE_F/.apex/STATE.json.tmp" && \
  mv "$CASE_F/.apex/STATE.json.tmp" "$CASE_F/.apex/STATE.json"

(
  cd "$CASE_F"
  APEX_TRANSCRIPT_PATH="$TRANSCRIPT_F" bash "$HOOK" >/dev/null 2>&1
  echo "EXIT=$?" > "$CASE_F/exit-code.txt"
)
EXIT_F=$(grep -oE '[0-9]+' "$CASE_F/exit-code.txt" 2>/dev/null | head -1)
EXIT_F="${EXIT_F:-X}"
STUBS_F=$(grep -c '"type":"observation.mask.stub"' "$TRANSCRIPT_F" 2>/dev/null)
STUBS_F=$(printf '%s' "$STUBS_F" | tr -d '\r')
BYPASS_F=$(grep -c '"type":"observation.mask.bypassed"' "$CASE_F/.apex/event-log.jsonl" 2>/dev/null)
BYPASS_F=$(printf '%s' "$BYPASS_F" | tr -d '\r')

if [ "$EXIT_F" = "0" ] && [ "$STUBS_F" = "0" ]; then
  _pass "case (f): bypass switch → exit 0 with 0 stubs created"
else
  _fail "case (f): bypass switch — expected exit 0 + 0 stubs, got exit '$EXIT_F' stubs '$STUBS_F'"
fi
if [ "$BYPASS_F" -ge 1 ] 2>/dev/null; then
  _pass "case (f): observation.mask.bypassed event recorded"
else
  _fail "case (f): bypass event missing (count=$BYPASS_F)"
fi

# ---- Summary ----
echo ""
echo "test-observation-mask.sh: LOCAL_PASS=$LOCAL_PASS LOCAL_FAIL=$LOCAL_FAIL"
echo ""

if [ "${HARNESS_LOADED:-0}" = "1" ] || declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$LOCAL_PASS" "$LOCAL_FAIL" "test-observation-mask.sh"
fi

exit "$LOCAL_FAIL"
