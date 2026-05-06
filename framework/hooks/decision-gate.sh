#!/bin/bash
# decision-gate.sh — User-visible 60/90-minute decision gate (R5-016).
#
# Hook type: Command-Invoked (from /apex:next at top of cycle)
#
# Purpose
#   Spec anchor: "Decision gates פר 60-90 דקות." A user-visible
#   checkpoint that surfaces "we have been working for N minutes —
#   here is a summary; continue?" prevents runaway sessions and
#   reinforces the predictability brand commitment.
#
# Contract
#   - Reads .apex/STATE.json:
#       .session.started_at        — session epoch / ISO 8601
#       .session.last_time_gate    — last gate fire time (debounce)
#       .complexity_level          — drives the cadence threshold
#   - Cadence (from next.md TIME-BASED DECISION GATE prose, R5-016
#     formalizes it in code):
#       complexity 1, 2 → 90 minutes
#       complexity 3    → 75 minutes
#       complexity 4+   → 60 minutes
#       absent          → 60 minutes
#   - Gate fires when ELAPSED_MINUTES (since session.started_at)
#     >= 60 AND MINUTES_SINCE_LAST_GATE >= GATE_INTERVAL.
#   - On fire:
#       1. Update STATE.session.last_time_gate = now (debounce).
#       2. Emit `.apex/FIX_PLAN.md` via _fix-plan-emit.sh with three
#          options (continue / pause / wrap-up).
#       3. Exit 1 — caller (next.md) presents the FIX_PLAN.md to the
#          user and awaits their choice.
#   - On non-fire: exit 0 silently.
#
# Failure mode
#   Best-effort. Missing STATE.json or jq → exit 0 (do not block).
#   Filesystem write failure → log to stderr, still exit 0/1.
#
# Three-places contract (REMEDIATION-STYLE)
#   1. This file's `# Hook type:` header above.
#   2. `framework/commands/apex/next.md` — invocation site at the top
#      of every cycle.
#   3. `framework/HOOK-CLASSIFICATION.md` — Command-Invoked table row.

set -u

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

# R6-003: parse_epoch is sourced from the canonical helper instead of
# being defined inline. Mirrors the pattern used by phase-tag.sh and
# verify-learnings.sh — single source for cross-platform date parsing.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_date-parse.sh" ]; then
  source "$(dirname "$0")/_date-parse.sh"
fi

# === Locate STATE.json ===
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

REPO_ROOT=""
if command -v git >/dev/null 2>&1; then
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
fi
if [ -z "$REPO_ROOT" ]; then
  REPO_ROOT="$(pwd)"
fi

STATE_JSON="${APEX_STATE_FILE:-$REPO_ROOT/.apex/STATE.json}"
if [ ! -f "$STATE_JSON" ]; then
  exit 0
fi

# === Read inputs ===
STARTED_AT=$(jq -r '.session.started_at // empty' "$STATE_JSON" 2>/dev/null || true)
if [ -z "$STARTED_AT" ]; then
  # No session started_at — gate cannot compute elapsed time.
  exit 0
fi

LAST_GATE=$(jq -r '.session.last_time_gate // empty' "$STATE_JSON" 2>/dev/null || true)
COMPLEXITY=$(jq -r '.complexity_level // empty' "$STATE_JSON" 2>/dev/null || true)

# === Compute elapsed + cadence ===
# parse_epoch is provided by _date-parse.sh sourced above (R6-003).

START_EPOCH=$(parse_epoch "$STARTED_AT")
if [ -z "$START_EPOCH" ]; then
  # Could not parse session.started_at — best-effort, do not block.
  exit 0
fi

NOW_EPOCH="${APEX_NOW_EPOCH:-$(date +%s 2>/dev/null || echo 0)}"
if [ "$NOW_EPOCH" -le 0 ] 2>/dev/null; then
  exit 0
fi

ELAPSED_MINUTES=$(( (NOW_EPOCH - START_EPOCH) / 60 ))

LAST_GATE_EPOCH="$START_EPOCH"
if [ -n "$LAST_GATE" ]; then
  LG=$(parse_epoch "$LAST_GATE")
  if [ -n "$LG" ]; then
    LAST_GATE_EPOCH="$LG"
  fi
fi
MINUTES_SINCE_GATE=$(( (NOW_EPOCH - LAST_GATE_EPOCH) / 60 ))

# Cadence by complexity.
GATE_INTERVAL=60
case "$COMPLEXITY" in
  1|2) GATE_INTERVAL=90 ;;
  3)   GATE_INTERVAL=75 ;;
  4)   GATE_INTERVAL=60 ;;
  *)   GATE_INTERVAL=60 ;;
esac

# === Decide ===
if [ "$ELAPSED_MINUTES" -lt 60 ] || [ "$MINUTES_SINCE_GATE" -lt "$GATE_INTERVAL" ]; then
  exit 0
fi

# === Fire ===
# Update last_time_gate (debounce). Write atomically via a temp file
# so a partial write cannot leave STATE.json unparseable.
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date 2>/dev/null || echo "$NOW_EPOCH")
TMP_STATE="$STATE_JSON.decision-gate.tmp"
if jq --arg ts "$NOW_ISO" '.session.last_time_gate = $ts' "$STATE_JSON" > "$TMP_STATE" 2>/dev/null; then
  mv "$TMP_STATE" "$STATE_JSON" 2>/dev/null || rm -f "$TMP_STATE" 2>/dev/null || true
else
  rm -f "$TMP_STATE" 2>/dev/null || true
fi

REASON="Time-based decision gate at ${ELAPSED_MINUTES} minutes (cadence: every ${GATE_INTERVAL} minutes for complexity ${COMPLEXITY:-default})."
CONTEXT="Session started ${ELAPSED_MINUTES} minutes ago. Last gate fired ${MINUTES_SINCE_GATE} minutes ago. Decision gates fire every 60-90 minutes per spec."

if command -v emit_fix_plan >/dev/null 2>&1; then
  emit_fix_plan \
    "decision-gate" \
    "$REASON" \
    "$CONTEXT" \
    "continue -- keep working in this session (recommended if focus is intact)" \
    "/apex:pause -- save state and stop for a break" \
    "/apex:resume -- start a fresh session with clean context (wrap up)" \
    2>/dev/null || true
fi

# Surface to stderr too — tests + CLI users see the fire signal even
# when the FIX_PLAN.md write fails.
echo "APEX DECISION GATE: ${ELAPSED_MINUTES} minutes elapsed (cadence ${GATE_INTERVAL}m). Three options written to .apex/FIX_PLAN.md." >&2

exit 1
