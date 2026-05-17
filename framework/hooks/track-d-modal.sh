#!/usr/bin/env bash
# track-d-modal.sh — M08.1 plain-language modal for Track D events.
#
# Hook type: Command-Invoked (called by framework/commands/apex/next.md
# STEP G when task_class == "D" — see TRACK D MODAL block).
#
# Purpose
#   Render a plain-language Hebrew/English modal for irreversible
#   (Track D) actions so a non-programmer user can grant or deny
#   approval. Track D events route through THIS hook, not through the
#   default y/n prompt — the surface is intentionally different
#   (plain language, default-to-stop, batching, rate-limit) so the
#   user's attention lands on Track D specifically instead of being
#   drowned in routine prompts.
#
#   See `.apex/phases/12-apex-evolution-v8/PLAN.md` task 12.02 §5-§6
#   ("Ideal functioning" + "Right fix path" for M08.1) for the design
#   contract.
#
# Spec anchor
#   apex-spec.md — `היכולות הנדרשות` (risk-aware autonomy) +
#   `עקרונות העבודה` (plain-language UX for non-programmers).
#
# Usage
#   bash framework/hooks/track-d-modal.sh <task_id> <description> [is_irreversible_now]
#
# Inputs
#   $1 task_id              e.g. 12.02 — used for logging + dedupe key.
#   $2 description          plain-language description of the action
#                           (architect-authored task.description from
#                           PLAN_META.json). May be English; the hook
#                           frames it in Hebrew.
#   $3 is_irreversible_now  "true" → bypass batching + rate-limit.
#                           Anything else → eligible for batching.
#
# Exit codes
#   0 = user said `כן` (yes, proceed)
#   1 = user said `לא` (no, stop) — safe default on Enter
#   2 = modal deferred (batched OR rate-limited — caller treats as stop)
#   3 = invocation error (bad args, infrastructure failure)
#
# Output contract
#   Stdout: the rendered modal (caller may capture for transcripting).
#   Stderr: one-line status events (route to event-log.jsonl).
#   State writes (when STATE.json present and writable):
#     - autonomy.track_d_modal_state.modals_today      (counter)
#     - autonomy.track_d_modal_state.last_modal_at     (RFC 3339)
#     - autonomy.track_d_modal_state.pending_count     (queue depth)
#     - autonomy.track_d_modal_state.digest_mode       (boolean)
#   Queue file (when batching): .apex/pending_track_d.json

set -uo pipefail

TASK_ID="${1:-}"
DESCRIPTION="${2:-}"
IRREVERSIBLE_NOW="${3:-false}"

if [ -z "$TASK_ID" ] || [ -z "$DESCRIPTION" ]; then
  echo "🚫 track-d-modal: usage: track-d-modal.sh <task_id> <description> [is_irreversible_now]" >&2
  exit 3
fi

# Resolve STATE.json — prefer .apex/STATE.json in the cwd; fall back to
# the script's repo root if absent (matches the project-root convention
# used by agent-lint.sh and migrate-plan-meta-v8.sh).
STATE_FILE=""
for candidate in "./.apex/STATE.json" "${APEX_STATE_FILE:-}"; do
  [ -z "$candidate" ] && continue
  if [ -f "$candidate" ]; then
    STATE_FILE="$candidate"
    break
  fi
done

if [ -z "$STATE_FILE" ]; then
  echo "⚠️ track-d-modal: STATE.json not found — proceeding without rate-limit tracking" >&2
fi

# Helper: safe jq with state file.
jq_state() {
  if [ -z "$STATE_FILE" ]; then return 0; fi
  jq -r "$@" "$STATE_FILE" 2>/dev/null
}

# Helper: write STATE.json subfield (jq + atomic move).
write_state() {
  # $1 = jq filter applied to STATE.json
  if [ -z "$STATE_FILE" ]; then return 0; fi
  local tmp
  tmp="$(mktemp)"
  jq "$1" "$STATE_FILE" > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1; }
  if [ -s "$tmp" ]; then
    mv "$tmp" "$STATE_FILE"
  else
    rm -f "$tmp"
    return 1
  fi
}

NOW_ISO="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
NOW_EPOCH="$(date -u +%s)"

# --- Read current modal state ---
LAST_MODAL_AT="$(jq_state '.autonomy.track_d_modal_state.last_modal_at // ""')"
MODALS_TODAY="$(jq_state '.autonomy.track_d_modal_state.modals_today // 0')"
DIGEST_MODE="$(jq_state '.autonomy.track_d_modal_state.digest_mode // false')"

# Defensive defaults if STATE lacks v8 fields (legacy STATE).
: "${MODALS_TODAY:=0}"
: "${DIGEST_MODE:=false}"

# --- Rate-limit gate (≤1 modal / 30 min) ---
# Skipped when is_irreversible_now=true (bypass batching per PLAN.md §6).
if [ "$IRREVERSIBLE_NOW" != "true" ] && [ -n "$LAST_MODAL_AT" ]; then
  # Compute elapsed seconds since last_modal_at.
  if LAST_EPOCH="$(date -u -d "$LAST_MODAL_AT" +%s 2>/dev/null)"; then
    ELAPSED=$(( NOW_EPOCH - LAST_EPOCH ))
    if [ "$ELAPSED" -lt 1800 ]; then
      # Rate-limited — batch this event.
      QUEUE_FILE="./.apex/pending_track_d.json"
      mkdir -p "$(dirname "$QUEUE_FILE")" 2>/dev/null
      if [ ! -f "$QUEUE_FILE" ]; then
        echo '{"events":[]}' > "$QUEUE_FILE"
      fi
      local_tmp="$(mktemp)"
      jq --arg id "$TASK_ID" --arg desc "$DESCRIPTION" --arg ts "$NOW_ISO" \
         '.events += [{task_id: $id, description: $desc, queued_at: $ts}]' \
         "$QUEUE_FILE" > "$local_tmp" 2>/dev/null && mv "$local_tmp" "$QUEUE_FILE" || rm -f "$local_tmp"
      PENDING_COUNT=$(jq '.events | length' "$QUEUE_FILE" 2>/dev/null || echo 0)
      write_state ".autonomy.track_d_modal_state.pending_count = $PENDING_COUNT"
      echo "⏸ track-d-modal: rate-limited (≤1 modal / 30 min) — batched to $QUEUE_FILE (queue depth: $PENDING_COUNT)" >&2
      exit 2
    fi
  fi
fi

# --- Digest-mode gate (≥3 modals in 4 hours → digest mode) ---
# Skipped when is_irreversible_now=true (bypass batching).
if [ "$IRREVERSIBLE_NOW" != "true" ] && [ "$DIGEST_MODE" = "true" ]; then
  echo "📋 track-d-modal: digest mode active — Track D event logged to event-log.jsonl as MAJOR" >&2
  # Log MAJOR event (M10 severity tier — feeds into Phase 12.06's central emitter).
  EVENT_LOG="./.apex/event-log.jsonl"
  mkdir -p "$(dirname "$EVENT_LOG")" 2>/dev/null
  printf '{"ts":"%s","severity":"MAJOR","hook":"track-d-modal","task_id":"%s","description":"%s","digest_mode":true}\n' \
    "$NOW_ISO" "$TASK_ID" "$DESCRIPTION" >> "$EVENT_LOG"
  exit 2
fi

# --- Render the plain-language modal ---
# Hebrew framing, English description (architect output may be either).
# Default Enter = STOP (safe — opposite of micro mode which defaults to proceed).
cat <<MODAL
🛑 פעולה לא הפיכה (Track D): ${TASK_ID}

${DESCRIPTION}

האם להמשיך?
  [k] כן, המשך       (yes, proceed)
  [l] לא, עצור       (no, stop) — default if you press Enter
  [e] הסבר עוד       (explain more — opens task PLAN.md section)
MODAL

# Read user input. Default on Enter = "l" (lo, stop) — the safe default.
# This is opposite to /apex:fast micro mode (which defaults to "כן, proceed").
# When stdin is not a TTY (CI / hook chain context), default to "l".
if [ -t 0 ]; then
  IFS= read -r -p "Choice [k/l/e, default=l]: " CHOICE
else
  CHOICE=""
fi
CHOICE="${CHOICE:-l}"
CHOICE="$(printf '%s' "$CHOICE" | tr '[:upper:]' '[:lower:]')"

case "$CHOICE" in
  k|y|yes|כן)
    DECISION="approved"
    EXIT_CODE=0
    ;;
  e|explain|הסבר)
    # Surface PLAN.md task section path so user can read context.
    echo "→ See .apex/phases/<phase>/PLAN.md — task ${TASK_ID} ecosystem analysis §§1-10" >&2
    echo "After review, re-run /apex:next to re-fire this modal." >&2
    DECISION="explain_more"
    EXIT_CODE=2
    ;;
  *)
    DECISION="declined"
    EXIT_CODE=1
    ;;
esac

# --- Update STATE counters ---
NEW_MODALS_TODAY=$(( MODALS_TODAY + 1 ))
# Switch to digest mode if budget exceeded (3 modals in any 4h rolling window —
# approximated here as 3+ in the SAME UTC day for v0; full rolling-window
# accounting deferred to a follow-up).
if [ "$NEW_MODALS_TODAY" -ge 3 ] && [ "$IRREVERSIBLE_NOW" != "true" ]; then
  NEW_DIGEST_MODE="true"
  echo "⚠️ track-d-modal: 3rd Track D modal today — switching to digest mode (subsequent events log to event-log.jsonl)" >&2
else
  NEW_DIGEST_MODE="$DIGEST_MODE"
fi

write_state "
  .autonomy.track_d_modal_state.modals_today = $NEW_MODALS_TODAY |
  .autonomy.track_d_modal_state.last_modal_at = \"$NOW_ISO\" |
  .autonomy.track_d_modal_state.digest_mode = $NEW_DIGEST_MODE
"

# --- Session log + event log ---
SESSION_LOG="${HOME}/.claude/hooks/session-log.sh"
if [ -x "$SESSION_LOG" ]; then
  bash "$SESSION_LOG" "track_d_modal" "Task ${TASK_ID}: ${DECISION} (modals_today=${NEW_MODALS_TODAY})"
fi

EVENT_LOG="./.apex/event-log.jsonl"
mkdir -p "$(dirname "$EVENT_LOG")" 2>/dev/null
printf '{"ts":"%s","severity":"CRITICAL","hook":"track-d-modal","task_id":"%s","decision":"%s","irreversible_now":%s,"modals_today":%d}\n' \
  "$NOW_ISO" "$TASK_ID" "$DECISION" "$IRREVERSIBLE_NOW" "$NEW_MODALS_TODAY" >> "$EVENT_LOG"

exit "$EXIT_CODE"
