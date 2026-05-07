#!/bin/bash
# session-auto-resume.sh — Auto-Continuity Layer A (v7.1).
# SessionStart hook that detects when the previous session was auto-paused (or
# has a fresh turn-checkpoint) and emits a banner instructing Claude to invoke
# /apex:resume immediately on the new session.
#
# Wired as: SessionStart hook (after state-rebuild.sh, before verify-learnings).
#
# Why this is a SessionStart hook (not part of resume.md):
#   The user must not need to type anything for the autonomous-continuity loop
#   to close. SessionStart fires automatically on every fresh Claude Code
#   session — so this hook closes the auto-pause→auto-resume cycle without
#   manual intervention. The hook cannot itself invoke a slash command, but it
#   can write a banner that Claude sees in its initial context and acts on.
#
# Contract:
#   • exit 0 always — never blocks session start
#   • Side effects (only when auto-pause detected):
#       - .apex/SESSION_BOOT.md (replaces any prior content)
#       - stdout banner (visible to Claude in fresh context)
#       - .apex/event-log.jsonl: appends session_auto_resumed event
#   • No-op if .apex/STATE.json missing (no APEX project) or session not
#     marked auto_paused.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_require-jq.sh"
require_jq
# shellcheck disable=SC1091
source "$SCRIPT_DIR/_state-update.sh"

export APEX_HOOK_SOURCE="session-auto-resume"

STATE_FILE=".apex/STATE.json"
BUDGET_FILE=".apex/CONTEXT_BUDGET.json"
FRAMEWORK_BUDGET_FILE="$HOME/.claude/CONTEXT_BUDGET.default.json"
BOOT_FILE=".apex/SESSION_BOOT.md"
CHECKPOINT_FILE=".apex/TURN_CHECKPOINT.json"

# Fail-soft: no APEX state, nothing to do.
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Read auto-resume opt-in flag (default true)
AUTO_RESUME_ENABLED="true"
if [ -f "$BUDGET_FILE" ]; then
  V=$(jq -r '.auto_continuity.session_auto_resume // empty' "$BUDGET_FILE" 2>/dev/null)
  [ "$V" = "false" ] && AUTO_RESUME_ENABLED="false"
fi
if [ "$AUTO_RESUME_ENABLED" = "true" ] && [ -f "$FRAMEWORK_BUDGET_FILE" ]; then
  V=$(jq -r '.auto_continuity.session_auto_resume // empty' "$FRAMEWORK_BUDGET_FILE" 2>/dev/null)
  [ "$V" = "false" ] && AUTO_RESUME_ENABLED="false"
fi

# Read previous session state
AUTO_PAUSED=$(jq -r '.session.auto_paused // false' "$STATE_FILE" 2>/dev/null)
PAUSE_REASON=$(jq -r '.session.auto_pause_reason // "unknown"' "$STATE_FILE" 2>/dev/null)
LAST_TAG=$(jq -r '.session.last_checkpoint_tag // "אין"' "$STATE_FILE" 2>/dev/null)
TASKS_DONE=$(jq -r '.session.tasks_completed // 0' "$STATE_FILE" 2>/dev/null)
[ "$LAST_TAG" = "null" ] && LAST_TAG="אין"

# Read turn-checkpoint freshness (in minutes)
FRESHNESS_MIN=30
if [ -f "$BUDGET_FILE" ]; then
  V=$(jq -r '.auto_continuity.turn_checkpoint_freshness_minutes // empty' "$BUDGET_FILE" 2>/dev/null)
  [ -n "$V" ] && [ "$V" != "null" ] && FRESHNESS_MIN="$V"
fi

CKPT_TS=""
CKPT_TASK=""
CKPT_FRESH="false"
if [ -f "$CHECKPOINT_FILE" ]; then
  CKPT_TS=$(jq -r '.ts // empty' "$CHECKPOINT_FILE" 2>/dev/null)
  CKPT_TASK=$(jq -r '.task_id // empty' "$CHECKPOINT_FILE" 2>/dev/null)
  if [ -n "$CKPT_TS" ] && [ "$CKPT_TS" != "null" ]; then
    NOW_EPOCH=$(date +%s 2>/dev/null || echo 0)
    CKPT_EPOCH=$(date -d "$CKPT_TS" +%s 2>/dev/null || \
                 python -c "import sys,datetime;print(int(datetime.datetime.strptime(sys.argv[1].rstrip('Z'),'%Y-%m-%dT%H:%M:%S').timestamp()))" "$CKPT_TS" 2>/dev/null || \
                 echo 0)
    if [ "$NOW_EPOCH" -gt 0 ] && [ "$CKPT_EPOCH" -gt 0 ]; then
      AGE_MIN=$(( (NOW_EPOCH - CKPT_EPOCH) / 60 ))
      if [ "$AGE_MIN" -le "$FRESHNESS_MIN" ] 2>/dev/null; then
        CKPT_FRESH="true"
      fi
    fi
  fi
fi

# Bail out early if nothing actionable
if [ "$AUTO_PAUSED" != "true" ] && [ "$CKPT_FRESH" != "true" ]; then
  exit 0
fi

# Bail out if user disabled auto-resume — but still log a hint
if [ "$AUTO_RESUME_ENABLED" = "false" ]; then
  if [ "$AUTO_PAUSED" = "true" ]; then
    echo "ℹ️  [APEX] Previous session auto-paused (reason: $PAUSE_REASON). Type /apex:resume to continue. (auto-resume disabled in CONTEXT_BUDGET.json)" >&2
  fi
  exit 0
fi

NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)

# --- Write SESSION_BOOT.md banner ---
{
  printf '# APEX — Session Auto-Resume Boot Banner\n\n'
  printf '> Generated automatically by `session-auto-resume.sh` (SessionStart hook).\n'
  printf '> Read this banner and immediately invoke `/apex:resume`.\n\n'
  printf '## State Detected\n\n'
  if [ "$AUTO_PAUSED" = "true" ]; then
    printf -- '- **auto_paused:** ✅ true\n'
    printf -- '- **pause reason:** `%s`\n' "$PAUSE_REASON"
    printf -- '- **last checkpoint tag:** `%s`\n' "$LAST_TAG"
    printf -- '- **tasks completed before pause:** %s\n' "$TASKS_DONE"
  fi
  if [ "$CKPT_FRESH" = "true" ]; then
    printf -- '- **fresh turn-checkpoint:** ✅ task `%s` at `%s`\n' "$CKPT_TASK" "$CKPT_TS"
    printf -- '  → `/apex:recover` option 6 (continue-from-turn-checkpoint) is available\n'
  fi
  printf '\n## Recommended Action\n\n'
  if [ "$AUTO_PAUSED" = "true" ]; then
    printf '`/apex:resume` — clears `auto_paused`, restores memory primitives, resumes autopilot if enabled.\n'
  else
    printf '`/apex:resume` — review fresh turn-checkpoint, optionally `/apex:recover` for option 6.\n'
  fi
  printf '\n## Hebrew banner (proposals_mode-friendly)\n\n'
  printf 'הסשן הקודם הושהה אוטומטית.\n'
  printf 'סיבה: %s\n' "$PAUSE_REASON"
  printf 'נקודת שחזור אחרונה: %s\n' "$LAST_TAG"
  printf 'משימות שהושלמו לפני ההשהיה: %s\n' "$TASKS_DONE"
  printf '\n[recommended] /apex:resume — להמשיך עם קונטקסט נקי.\n'
  printf '[חלופה] /apex:recover — אם יש crash mid-task.\n'
  printf '[ביטול] /apex:status — לבדוק את המצב לפני שמחליטים.\n'
} > "$BOOT_FILE"

# --- Emit semantic event ---
_emit_apex_event session_auto_resumed .apex \
  reason "$PAUSE_REASON" \
  last_tag "$LAST_TAG" \
  tasks_done "$TASKS_DONE" \
  ckpt_fresh "$CKPT_FRESH"

# --- Echo banner to stdout (Claude reads this in fresh session context) ---
cat <<EOF
🔁 [APEX] Session boot detected pending auto-pause.
   Reason: $PAUSE_REASON
   Action: read .apex/SESSION_BOOT.md and invoke /apex:resume.
EOF
if [ "$CKPT_FRESH" = "true" ]; then
  echo "   Fresh turn-checkpoint available: task $CKPT_TASK ($CKPT_TS)"
fi

exit 0
