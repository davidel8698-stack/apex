#!/bin/bash
# Hook type: Auto-SessionStart (conditional) + Command-Invoked
# R5-004 — Reconstruct .apex/STATE.json from disk-resident artifacts:
#   - .apex/event-log.jsonl   (event-sourced telemetry, append-only)
#   - .apex/phases/<id>/SUMMARY.md  (phase ground-truth)
#
# R6-011 — Schema-complete rebuild via frozen template + overlay.
#   The 7-field jq construction is replaced by:
#     1. Read framework/templates/STATE-init.template.json (frozen copy of
#        the start.md STATE.json init block; mirror-warning lives in the
#        template's `_doc` field).
#     2. Strip the `_doc` field (template-only annotation, not part of
#        the canonical schema — schema declares additionalProperties:false).
#     3. Overlay event-log-derived semantic-event fields on top
#        (current_phase, decision_mode, complexity_level, complexity_name).
#     4. Override `project` from the basename of the repo root.
#     5. Write the merged STATE.json.
#   Result: schema-compatible STATE.json with sensible defaults for
#   non-derivable fields and recovered values for canonical fields.
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
#   - The R6-004 dual-emit logic in _state-update.sh is a producer; this
#     hook is a consumer of the semantic events it emits.
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

# Locate the frozen init template. It lives under framework/templates/ in
# the source tree and under ~/.claude/templates/ once delivered. Prefer
# the source tree if both are present (developer mode).
TEMPLATE=""
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
# Candidate 1: framework/templates/ relative to the hook's framework root.
CAND1="$(cd "$HOOK_DIR/.." 2>/dev/null && pwd)/templates/STATE-init.template.json"
# Candidate 2: claude-installed sibling (~/.claude/templates/).
CAND2="${HOME:-/}/.claude/templates/STATE-init.template.json"
# Candidate 3: repo-relative (running from a checkout that has framework/).
CAND3="$ROOT/framework/templates/STATE-init.template.json"
for c in "$CAND1" "$CAND2" "$CAND3"; do
  if [ -f "$c" ]; then
    TEMPLATE="$c"
    break
  fi
done

if [ -z "$TEMPLATE" ]; then
  echo "state-rebuild: STATE-init.template.json not found; cannot rebuild" >&2
  exit 0
fi

# Derive overlay values from the event log (semantic events emitted by R6-004).
CURRENT_PHASE=""
DECISION_MODE=""
COMPLEXITY_LEVEL=""
COMPLEXITY_NAME=""

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
    if [ -z "$CURRENT_PHASE" ] || [ "$HIGHEST" \> "$CURRENT_PHASE" ]; then
      CURRENT_PHASE="$HIGHEST"
    fi
  fi
fi

PROJECT_NAME="$(basename "$ROOT")"

# Build the merged STATE.json: template (minus _doc) overlaid with derived fields.
# jq -S enforces stable key ordering for byte-identical determinism.
jq -S \
  --arg project          "$PROJECT_NAME" \
  --arg current_phase    "$CURRENT_PHASE" \
  --arg decision_mode    "$DECISION_MODE" \
  --arg complexity_level "$COMPLEXITY_LEVEL" \
  --arg complexity_name  "$COMPLEXITY_NAME" \
  '
    # Start from template, drop the annotation field.
    del(._doc)
    # Always set project from repo basename.
    | .project = $project
    # Overlay current_phase if derived (else keep template default null).
    | (if ($current_phase | length) > 0 then .current_phase = $current_phase else . end)
    # Overlay decision_mode (template has no field; add optional sibling for downstream readers).
    | (if ($decision_mode | length) > 0 then .decision_mode = $decision_mode else . end)
    # Overlay complexity_level (integer); fall back to template value if empty.
    | (if ($complexity_level | length) > 0 then .complexity_level = ($complexity_level | tonumber) else . end)
    # Overlay complexity_name if derived (else keep template default "").
    | (if ($complexity_name | length) > 0 then .complexity_name = $complexity_name else . end)
    # Mark the rebuild origin for downstream tools / forensics.
    | .rebuilt_from_event_log = true
    | .rebuild_source = "state-rebuild.sh"
  ' "$TEMPLATE" > "$STATE_FILE" 2>/dev/null || {
    echo "state-rebuild: failed to write $STATE_FILE" >&2
    exit 0
  }

echo "state-rebuild: reconstructed $STATE_FILE (current_phase=${CURRENT_PHASE:-<default>}, decision_mode=${DECISION_MODE:-<default>})" >&2
exit 0
