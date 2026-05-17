#!/usr/bin/env bash
# comprehension-gate.sh — M09 risk-based comprehension gate (Phase 12.05).
#
# Hook type: Command-Invoked (fired by /apex:next at phase boundary OR
# at the 60-90 min time mark, whichever comes first).
#
# Purpose
#   Replace the v7 LOC-based comprehension gate with a risk-weighted,
#   generation-then-comprehension protocol. R5 §3 (Anthropic RCT 86%
#   vs 24%) — the interaction pattern itself is the intervention.
#   The new gate mandates explanation rather than allowing silent
#   click-through.
#
# Spec anchors
#   apex-spec.md — `עקרונות העבודה` (cognitive-debt prevention).
#   .apex/phases/12-apex-evolution-v8/PLAN.md task 12.05 §§5-6.
#   R5 §3 (Anthropic generation-then-comprehension 86% recall vs 24% baseline).
#   R5 §4.3 (15-25 min refocus cost — gate fires at task boundary
#   when 60-min mark hits mid-task).
#
# Usage
#   bash framework/hooks/comprehension-gate.sh <phase> <task_class>
#
# Inputs
#   $1 phase       — current phase ID (e.g. "12")
#   $2 task_class  — A | B | C | D (drives gate DEPTH per M08)
#
# Depth by task_class (PLAN.md §5):
#   A → 0 mandatory files (skipped — Track A is low-risk)
#   B → 1 file: purpose + invariant + failure mode
#   C → 2 files + 1 integration point
#   D → 2 files + 1 integration point (same as C — Track D adds
#       irreversibility check via track-d-modal.sh elsewhere)
#
# File selection (PLAN.md §6 — criticality > LOC):
#   1. Tagged high-risk domain (auth/payments/migrations/schema —
#      from RISK-KEYWORDS.md Class C/D keywords)
#   2. Large semantic diff
#   3. Central to new architectural concept
#   4. Files where critic disagreed (from STATE.session.critic_disagreements[]
#      when M08 wires it; defensive default for now)
#
# Response modes (PLAN.md §6):
#   explain  → mandatory text input; saved to STATE.comprehension_gates
#   defer    → auto-fires at next phase boundary; STATE marks pending
#   skip     → requires --force flag; logs cognitive_debt.skip event
#              for User Decision #5 evaluation data
#
# Cadence: 60-90 min OR phase boundary, whichever first.
# Time cap: 10-15 min per gate is a UX target (logged, not hard-enforced).
#
# Exit codes
#   0 = gate passed (explain or successful defer)
#   1 = gate failed / skipped without --force
#   2 = invocation error (bad args, infrastructure failure)

set -uo pipefail

PHASE="${1:-}"
TASK_CLASS="${2:-B}"
FORCE_SKIP="${3:-}"

if [ -z "$PHASE" ]; then
  echo "🚫 comprehension-gate: usage: comprehension-gate.sh <phase> <task_class> [--force]" >&2
  exit 2
fi

# Validate task_class.
case "$TASK_CLASS" in
  A|B|C|D) ;;
  *) echo "🚫 comprehension-gate: task_class must be A | B | C | D" >&2; exit 2 ;;
esac

# Resolve depth.
case "$TASK_CLASS" in
  A) DEPTH=0 ;;
  B) DEPTH=1 ;;
  C|D) DEPTH=2 ;;
esac

# Class A → skip entirely (zero mandatory files).
if [ "$DEPTH" = "0" ]; then
  echo "✓ comprehension-gate: Track A — no mandatory files (DEPTH=0). Gate skipped."
  exit 0
fi

PHASE_DIR=".apex/phases/${PHASE}"
STATE_FILE=".apex/STATE.json"
NOW_ISO="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
GATE_ID="${PHASE}-$(date -u +%s)"

# Cadence check — only fire if (now - STATE.session.last_time_gate) >= 60 min
# OR this is being called for the phase-boundary reason.
# (Caller decides; this hook trusts its invocation. Cadence enforcement
# lives in /apex:next + decision-gate.sh which is the scheduler.)

# Render the gate frame.
cat <<GATE
═══════════════════════════════════════════════════════════════════════
🔎 COMPREHENSION GATE — Phase ${PHASE}, Track ${TASK_CLASS} (depth ${DEPTH})

Risk-based file selection (criticality > LOC):
  · High-risk-domain hits (auth/payments/migrations/schema) — see RISK-KEYWORDS.md
  · Large semantic diff
  · Central to new architectural concept
  · Files where critic disagreed

(File enumeration is handled by /apex:next using STATE.session
critic_disagreements + TDAD impact + risk-keyword tagging. This hook
renders the gate; the caller supplies the file list via stdin or via
\$APEX_GATE_FILES env var. When absent, the gate prompts the user for
file paths.)

For each selected file, answer the 4 questions (validated R5 §3 pattern):

  1. What does this code do?
  2. What invariant matters most?
  3. What could break?
  4. How would you modify it for [a plausible adjacent change]?

Time target: 10-15 min for the full gate (logged; not hard-enforced).

Responses:
  explain    → write your understanding (mandatory text input)
  defer      → auto-fires at next phase boundary; gate stays pending
  skip       → cognitive-debt risk; requires --force flag
               (NOT available for Track D — irreversibility blocks skip)

═══════════════════════════════════════════════════════════════════════
GATE

# Track D skip is structurally prohibited.
if [ "$TASK_CLASS" = "D" ] && [ "$FORCE_SKIP" = "--force" ]; then
  echo "🚫 comprehension-gate: --force skip is NOT available for Track D (irreversible). Use 'defer' to push to next boundary." >&2
  exit 1
fi

# Read response from stdin in both TTY and piped contexts. The prompt
# itself only shows in the TTY case; piped callers (heredoc, here-string,
# CI invocations) supply the response on stdin. Empty stdin → 'defer'
# default (safe — auto-fires at next phase boundary).
if [ -t 0 ]; then
  printf 'Response [explain/defer/skip, default=defer]: '
fi
IFS= read -r RESPONSE || RESPONSE=""
RESPONSE="${RESPONSE:-defer}"
RESPONSE="$(printf '%s' "$RESPONSE" | tr '[:upper:]' '[:lower:]')"

case "$RESPONSE" in
  explain)
    DECISION="explain"
    EXIT_CODE=0
    # Capture explanation text (caller manages the actual capture; this
    # hook records the response type only — text-capture is a follow-up
    # integration with the next.md gate-state persistence block).
    ;;
  defer)
    DECISION="defer"
    EXIT_CODE=0
    ;;
  skip)
    if [ "$FORCE_SKIP" != "--force" ]; then
      echo "🚫 comprehension-gate: 'skip' requires --force flag. Use 'defer' to push to next boundary." >&2
      exit 1
    fi
    DECISION="skip"
    EXIT_CODE=0
    ;;
  *)
    echo "🚫 comprehension-gate: invalid response '$RESPONSE'. Use explain | defer | skip." >&2
    exit 1
    ;;
esac

# Update STATE.comprehension_gates with the structured record.
# Schema field added by 12.05-B: STATE.comprehension_gates.phase_<N>[].
if command -v jq >/dev/null 2>&1 && [ -f "$STATE_FILE" ]; then
  TMP="$(mktemp)"
  jq --arg phase "phase_${PHASE}" \
     --arg gate_id "$GATE_ID" \
     --arg response "$DECISION" \
     --arg ts "$NOW_ISO" \
     --argjson depth "$DEPTH" \
     --arg track "$TASK_CLASS" \
     '
    .comprehension_gates = (.comprehension_gates // {current_gate_required: null}) |
    .comprehension_gates.history = (.comprehension_gates.history // []) +
      [{
        gate_id: $gate_id,
        phase: $phase,
        track: $track,
        depth: $depth,
        response: $response,
        timestamp: $ts,
        format: "gen-comp"
      }]
    ' "$STATE_FILE" > "$TMP" 2>/dev/null
  if [ -s "$TMP" ]; then
    mv "$TMP" "$STATE_FILE"
  else
    rm -f "$TMP"
  fi
fi

# Log to event-log + session log.
SESSION_LOG="${HOME}/.claude/hooks/session-log.sh"
[ -x "$SESSION_LOG" ] && bash "$SESSION_LOG" "comprehension_gate" "Phase ${PHASE} Track ${TASK_CLASS}: ${DECISION}"

EVENT_LOG="./.apex/event-log.jsonl"
mkdir -p "$(dirname "$EVENT_LOG")" 2>/dev/null
if [ "$DECISION" = "skip" ]; then
  # Cognitive-debt event for User Decision #5 data collection.
  printf '{"ts":"%s","severity":"MAJOR","hook":"comprehension-gate","type":"cognitive_debt.skip","phase":"%s","track":"%s","depth":%d}\n' \
    "$NOW_ISO" "$PHASE" "$TASK_CLASS" "$DEPTH" >> "$EVENT_LOG"
else
  printf '{"ts":"%s","severity":"MINOR","hook":"comprehension-gate","type":"gate.%s","phase":"%s","track":"%s","depth":%d}\n' \
    "$NOW_ISO" "$DECISION" "$PHASE" "$TASK_CLASS" "$DEPTH" >> "$EVENT_LOG"
fi

exit "$EXIT_CODE"
