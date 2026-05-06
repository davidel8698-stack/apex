#!/bin/bash
# Hook type: Library — Sourced (helper invoked from /apex:next)
# R5-023 — Wraps memory-synthesis dream-cycle invocations with structured
# START / COMPLETE / FAIL events tied by a correlation id.
#
# Usage (sourced or invoked directly):
#   bash ~/.claude/hooks/_dream-cycle-emit.sh start  <reason>
#       → echoes a correlation id (capture into a shell var)
#   bash ~/.claude/hooks/_dream-cycle-emit.sh complete <correlation_id> <duration_ms> <result>
#   bash ~/.claude/hooks/_dream-cycle-emit.sh fail     <correlation_id> <reason>
#
# Spec anchor: "Memory Synthesis dream-cycle agent" + "Fail-loud,
# never fail-silent."
#
# Implementation: writes both a session-log.sh line (for SESSION-LOG.md
# human readability) and a structured JSONL row to .apex/event-log.jsonl
# directly (so state-rebuild.sh, R5-004, can consume the correlation id).
set -u

PHASE="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null || dirname "$0")"

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ
}

new_id() {
  # 16 hex chars; portable enough for our needs.
  if command -v od >/dev/null 2>&1; then
    od -An -N8 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n'
  else
    printf '%s%s' "$(date +%s)" "$$"
  fi
}

emit_jsonl() {
  local row="$1"
  mkdir -p .apex 2>/dev/null
  printf '%s\n' "$row" >> .apex/event-log.jsonl 2>/dev/null || true
}

case "$PHASE" in
  start)
    REASON="${2:-}"
    CID="$(new_id)"
    TS="$(iso_now)"
    SAFE_REASON=$(printf '%s' "$REASON" | tr '"' "'" | tr '\n' ' ')
    emit_jsonl "{\"ts\":\"$TS\",\"type\":\"dream_cycle_start\",\"event\":\"dream_cycle_start\",\"correlation_id\":\"$CID\",\"reason\":\"$SAFE_REASON\"}"
    bash "$SCRIPT_DIR/session-log.sh" "dream_cycle_start" "Dream-cycle START [$CID] — $REASON" >/dev/null 2>&1 || true
    # The caller captures the correlation id from stdout.
    printf '%s\n' "$CID"
    ;;
  complete)
    CID="${2:-}"
    DURATION_MS="${3:-0}"
    RESULT="${4:-ok}"
    TS="$(iso_now)"
    SAFE_RESULT=$(printf '%s' "$RESULT" | tr '"' "'" | tr '\n' ' ')
    emit_jsonl "{\"ts\":\"$TS\",\"type\":\"dream_cycle_complete\",\"event\":\"dream_cycle_complete\",\"correlation_id\":\"$CID\",\"duration_ms\":$DURATION_MS,\"result\":\"$SAFE_RESULT\"}"
    bash "$SCRIPT_DIR/session-log.sh" "dream_cycle_complete" "Dream-cycle COMPLETE [$CID] — ${DURATION_MS}ms — $RESULT" >/dev/null 2>&1 || true
    ;;
  fail)
    CID="${2:-}"
    REASON="${3:-unknown}"
    TS="$(iso_now)"
    SAFE_REASON=$(printf '%s' "$REASON" | tr '"' "'" | tr '\n' ' ')
    emit_jsonl "{\"ts\":\"$TS\",\"type\":\"dream_cycle_fail\",\"event\":\"dream_cycle_fail\",\"correlation_id\":\"$CID\",\"reason\":\"$SAFE_REASON\"}"
    bash "$SCRIPT_DIR/session-log.sh" "dream_cycle_fail" "Dream-cycle FAIL [$CID] — $REASON" >/dev/null 2>&1 || true
    ;;
  *)
    echo "_dream-cycle-emit: unknown phase '$PHASE' (expected: start | complete | fail)" >&2
    exit 1
    ;;
esac

exit 0
