#!/bin/bash
# Hook type: Auto-SessionStart (conditional) + Command-Invoked
# R5-004 — Reconstruct .apex/STATE.json from disk-resident artifacts:
#   - .apex/event-log.jsonl   (event-sourced telemetry, append-only)
#   - .apex/phases/<id>/SUMMARY.md  (phase ground-truth)
#
# Spec anchor: "State derives from disk."
#
# Triggering contract:
#   - SessionStart auto-fire: runs only when STATE.json is missing AND
#     event-log.jsonl is present. Fast-path exits 0 if STATE.json exists.
#   - Command-invocation: /apex:recover and /apex:resume call this hook
#     when STATE.json is missing.
#
# Determinism contract: same event log + same phase summaries → byte-identical
# STATE.json (jq is invoked with stable key ordering via jq -S).
#
# Preservation contract:
#   - The event-log.jsonl is read-only here. We never modify it.
#   - Unknown event types are no-ops (forward-compatible).
#   - This hook never overwrites an existing STATE.json.
set -u

source "$(dirname "$0")/_require-jq.sh"
require_jq

# Pass-through outside a git repo (e.g. generic Claude sessions).
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi
cd "$ROOT" || exit 0

STATE_FILE=".apex/STATE.json"
EVENT_LOG=".apex/event-log.jsonl"

# Fast-path: STATE.json exists → nothing to do.
if [ -f "$STATE_FILE" ]; then
  exit 0
fi

mkdir -p .apex 2>/dev/null

# Derive current_phase from the latest phase_set event (or fall back to "00").
CURRENT_PHASE="00"
DECISION_MODE="balanced"
COMPLEXITY_LEVEL=2
COMPLEXITY_NAME="Medium"

if [ -f "$EVENT_LOG" ]; then
  # current_phase: last `phase_set` event with .current_phase field.
  P=$(jq -rs '
    [ .[] | select((.type // "") == "phase_set") | (.current_phase // empty) ] | last // empty
  ' "$EVENT_LOG" 2>/dev/null)
  [ -n "$P" ] && CURRENT_PHASE="$P"

  # decision_mode: last `decision_mode_set` event with .decision_mode field.
  D=$(jq -rs '
    [ .[] | select((.type // "") == "decision_mode_set") | (.decision_mode // empty) ] | last // empty
  ' "$EVENT_LOG" 2>/dev/null)
  [ -n "$D" ] && DECISION_MODE="$D"

  # complexity: last `complexity_set` event.
  CL=$(jq -rs '
    [ .[] | select((.type // "") == "complexity_set") | (.complexity_level // empty) ] | last // empty
  ' "$EVENT_LOG" 2>/dev/null)
  CN=$(jq -rs '
    [ .[] | select((.type // "") == "complexity_set") | (.complexity_name // empty) ] | last // empty
  ' "$EVENT_LOG" 2>/dev/null)
  [ -n "$CL" ] && COMPLEXITY_LEVEL="$CL"
  [ -n "$CN" ] && COMPLEXITY_NAME="$CN"
fi

# Cross-check current_phase against the highest-numbered .apex/phases/<id>/SUMMARY.md
# (ground-truth from disk). Take the maximum of the two.
if [ -d ".apex/phases" ]; then
  HIGHEST=$(ls .apex/phases 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1 || true)
  if [ -n "${HIGHEST:-}" ] && [ -f ".apex/phases/$HIGHEST/SUMMARY.md" ]; then
    # If filesystem phase id sorts higher than event-log phase id, prefer disk.
    if [ "$HIGHEST" \> "$CURRENT_PHASE" ]; then
      CURRENT_PHASE="$HIGHEST"
    fi
  fi
fi

# Emit a minimal, deterministic STATE.json. Schema-completeness is NOT the goal;
# the goal is "STATE.json reproducible from disk" with the fields downstream
# tools (recover.md, resume.md, /apex:next pre-checks) actually read.
PROJECT_NAME="$(basename "$ROOT")"

jq -n -S \
  --arg project       "$PROJECT_NAME" \
  --arg current_phase "$CURRENT_PHASE" \
  --arg decision_mode "$DECISION_MODE" \
  --argjson complexity_level "$COMPLEXITY_LEVEL" \
  --arg complexity_name "$COMPLEXITY_NAME" \
  '{
    project: $project,
    current_phase: $current_phase,
    decision_mode: $decision_mode,
    complexity_level: $complexity_level,
    complexity_name: $complexity_name,
    rebuilt_from_event_log: true,
    rebuild_source: "state-rebuild.sh"
  }' > "$STATE_FILE" 2>/dev/null || {
    echo "state-rebuild: failed to write $STATE_FILE" >&2
    exit 0
  }

echo "state-rebuild: reconstructed $STATE_FILE (current_phase=$CURRENT_PHASE, decision_mode=$DECISION_MODE)" >&2
exit 0
