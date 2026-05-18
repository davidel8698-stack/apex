#!/bin/bash
set -u
# v7: Added total tool-call cap per task + enhanced loop detection [R1, R7]
# R1: GSD Issue #456 (infinite loops), Superpowers recursive subagent
# R7: Retry limited to 3 (diminishing returns). Failed trajectories cost 4x+ tokens.
# Called after each tool use by executor
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_require-git.sh"
source "$(dirname "$0")/_state-update.sh"
# R5-014: circuit-breaker now writes FIX_PLAN.md via the shared helper.
# RECOVERY_MENU.md is preserved as a backward-compat alias (W1 R5-005
# contract: /apex:recover reads either file). Detection logic and exit
# codes below are unchanged.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

export APEX_HOOK_SOURCE="circuit-breaker"

# G-2: Ensure CWD is project root so .apex/ paths resolve.
# Outside a git repo (e.g. generic Claude sessions): pass through silently — not our concern.
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi
cd "$ROOT" || exit 0

STATE_FILE=".apex/STATE.json"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# === CHECK 1: Consecutive no-change actions ===
GIT_DIFF_OUTPUT=$(git diff HEAD --stat 2>/dev/null)
if [ -z "$GIT_DIFF_OUTPUT" ]; then
  CURRENT_HASH="empty_$(date +%s%N)"
else
  CURRENT_HASH=$(echo "$GIT_DIFF_OUTPUT" | shasum -a 256 2>/dev/null | cut -d' ' -f1 || echo "$GIT_DIFF_OUTPUT" | md5sum 2>/dev/null | cut -d' ' -f1)
fi
LAST_HASH=$(jq -r '.circuit_breaker.last_file_hash // ""' "$STATE_FILE" 2>/dev/null)
MAX_NO_CHANGE=$(jq -r '.circuit_breaker.max_allowed // 3' "$STATE_FILE" 2>/dev/null)

if [ "$CURRENT_HASH" = "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
  # Atomic increment — avoids read-modify-write race condition
  _state_update \
     '.circuit_breaker.consecutive_no_change_actions = ((.circuit_breaker.consecutive_no_change_actions // 0) + 1)' "$STATE_FILE"
  COUNT=$(jq -r '.circuit_breaker.consecutive_no_change_actions // 0' "$STATE_FILE" 2>/dev/null)

  if [ "$COUNT" -ge "$MAX_NO_CHANGE" ]; then
    # R5-005 → R5-014: Write structured FIX_PLAN.md via the shared helper
    # so every blocking guard speaks the same fix-plan format. The
    # `--also-write-recovery-menu` flag mirrors the file at
    # .apex/RECOVERY_MENU.md to preserve the W1 contract that
    # /apex:recover reads RECOVERY_MENU.md when present.
    mkdir -p .apex 2>/dev/null
    if command -v emit_fix_plan >/dev/null 2>&1; then
      emit_fix_plan \
        --also-write-recovery-menu \
        "circuit-breaker" \
        "Circuit breaker tripped: NO-CHANGE LOOP. $COUNT consecutive actions without file changes — likely stuck in a loop." \
        "Trigger: no_change_loop (consecutive count $COUNT, threshold $MAX_NO_CHANGE)" \
        "/apex:forensics -- diagnose what happened (timeline + last actions). Use when you don't know why the loop started." \
        "/apex:rollback -- revert to the last known-good state. Use when the recent edits caused the loop." \
        "/apex:recover -- reset reflexion counter and re-plan. Use when you want to retry the unit from a clean slate." \
        2>/dev/null || true
    else
      # Degraded-install fallback: keep the W1 RECOVERY_MENU.md inline
      # write so /apex:recover continues to find a menu file even when
      # the helper is missing. Identical content shape to the helper.
      {
        echo "# Recovery Menu"
        echo ""
        echo "## Reason"
        echo "Circuit breaker tripped: NO-CHANGE LOOP."
        echo "$COUNT consecutive actions without file changes — likely stuck in a loop."
        echo ""
        echo "## Options"
        echo "- \`/apex:forensics\` — diagnose what happened (timeline + last actions). Use when you don't know why the loop started."
        echo "- \`/apex:rollback\` — revert to the last known-good state. Use when the recent edits caused the loop."
        echo "- \`/apex:recover\` — reset reflexion counter and re-plan. Use when you want to retry the unit from a clean slate."
      } > .apex/RECOVERY_MENU.md 2>/dev/null
    fi

    {
      echo "🛑 SAFETY-STOP FIRED (circuit breaker): STUCK LOOP — NO FILE CHANGES"
      echo "   $COUNT consecutive actions without file changes."
      echo "   Likely stuck in a loop."
      echo ""
      echo "   Fix plan written to: .apex/FIX_PLAN.md (also mirrored to .apex/RECOVERY_MENU.md)"
      echo ""
      echo "   Options:"
      echo "   1. /apex:forensics — diagnose what happened (timeline reconstruction)"
      echo "   2. /apex:rollback  — revert to last known-good state"
      echo "   3. /apex:recover   — reset and re-plan"
    } >&2

    _state_update '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = "no_change_loop"' "$STATE_FILE"
    exit 2
  fi
else
  # Files changed — reset no-change counter
  _state_update --arg hash "$CURRENT_HASH" \
     '.circuit_breaker.consecutive_no_change_actions = 0 | .circuit_breaker.last_file_hash = $hash | .circuit_breaker.triggered = false' "$STATE_FILE"
fi

# === CHECK 2: v7 — Total tool calls per task (prevents token spirals) ===
# Executor maxTurns = 40. Cap at 80 (2x) to catch spiraling tasks.
MAX_TOOL_CALLS=$(jq -r '.circuit_breaker.max_tool_calls_per_task // 80' "$STATE_FILE" 2>/dev/null)

# Atomic increment — avoids read-modify-write race condition
_state_update \
   '.circuit_breaker.total_tool_calls_this_task = ((.circuit_breaker.total_tool_calls_this_task // 0) + 1)' "$STATE_FILE"
TOOL_CALLS=$(jq -r '.circuit_breaker.total_tool_calls_this_task // 0' "$STATE_FILE" 2>/dev/null)

if [ "$TOOL_CALLS" -ge "$MAX_TOOL_CALLS" ]; then
  # R5-005 → R5-014: Write structured FIX_PLAN.md via the shared helper
  # (with RECOVERY_MENU.md alias for backward compat).
  mkdir -p .apex 2>/dev/null
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      --also-write-recovery-menu \
      "circuit-breaker" \
      "Circuit breaker tripped: TOOL-CALL CAP REACHED. $TOOL_CALLS tool calls on this task (cap: $MAX_TOOL_CALLS). R7: Failed trajectories cost 4x+ more tokens than successful ones." \
      "Trigger: tool_call_cap (count $TOOL_CALLS, cap $MAX_TOOL_CALLS)" \
      "/apex:forensics -- diagnose where the trajectory diverged. Use when you want a timeline of the runaway." \
      "/apex:rollback -- revert recent edits to the last green tag. Use when the task corrupted state you want to discard." \
      "/apex:recover -- reset and re-plan the unit. Use when you want to keep edits but retry with fresh context." \
      2>/dev/null || true
  else
    # Degraded-install fallback: identical content shape to the helper.
    {
      echo "# Recovery Menu"
      echo ""
      echo "## Reason"
      echo "Circuit breaker tripped: TOOL-CALL CAP REACHED."
      echo "$TOOL_CALLS tool calls on this task (cap: $MAX_TOOL_CALLS). Failed trajectories cost 4x+ more tokens than successful ones."
      echo ""
      echo "## Options"
      echo "- \`/apex:forensics\` — diagnose where the trajectory diverged. Use when you want a timeline of the runaway."
      echo "- \`/apex:rollback\` — revert recent edits to the last green tag. Use when the task corrupted state you want to discard."
      echo "- \`/apex:recover\` — reset and re-plan the unit. Use when you want to keep edits but retry with fresh context."
    } > .apex/RECOVERY_MENU.md 2>/dev/null
  fi

  {
    echo "🛑 SAFETY-STOP FIRED (circuit breaker): TOO MANY TOOL CALLS (tool-call cap reached)"
    echo "   $TOOL_CALLS tool calls on this task (cap: $MAX_TOOL_CALLS)."
    echo "   R7: Failed trajectories cost 4x+ more tokens than successful ones."
    echo ""
    echo "   Fix plan written to: .apex/FIX_PLAN.md (also mirrored to .apex/RECOVERY_MENU.md)"
    echo ""
    echo "   Options:"
    echo "   1. /apex:forensics — diagnose where it went off the rails (timeline reconstruction)"
    echo "   2. /apex:rollback  — revert recent edits"
    echo "   3. /apex:recover   — reset and re-plan"
  } >&2

  _state_update '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = "tool_call_cap"' "$STATE_FILE"
  exit 2
fi

# === CHECK 3: Recurring-error hash (R16-605, F-605, IMP-007) ===
# Reads the PostToolUse stdin envelope for `tool_response.is_error == true`
# tool results, sha256-hashes the first 200 chars of the error payload, and
# maintains a 20-call FIFO ring buffer in STATE.circuit_breaker.recent_error_hashes[].
# When any single hash reaches >=5 occurrences in the window, the breaker
# fires with trigger_reason='stuck_on_recurring_error' and RESULT.status
# (set by executor on next write) is widened by R-606 to accept this outcome.
#
# Pairs with R16-610 exfil-guard (which reads STATE.tool_failure_count, a
# coarser sibling counter) — they do not interfere; one counts *any* error,
# the other detects *repeating* errors.
#
# Carve-out: PostToolUse envelope MAY be absent when this hook is invoked
# from a non-Claude-Code context (CLI tests). In that case, stdin is empty
# and CHECK 3 silently no-ops.
if [ ! -t 0 ]; then
  CB_STDIN_BUF=$(cat 2>/dev/null || true)
  if [ -n "$CB_STDIN_BUF" ] && command -v jq >/dev/null 2>&1; then
    CB_IS_ERROR=$(echo "$CB_STDIN_BUF" | jq -r '.tool_response.is_error // false' 2>/dev/null || echo "false")
    if [ "$CB_IS_ERROR" = "true" ]; then
      # Extract error text; fall back to stringified tool_response when no
      # explicit error field exists.
      CB_ERR_TEXT=$(echo "$CB_STDIN_BUF" | jq -r '
        (.tool_response.content[0].text // empty)
        // (.tool_response.error // empty)
        // (.tool_response | tostring)
      ' 2>/dev/null || true)
      if [ -n "$CB_ERR_TEXT" ]; then
        # Hash first 200 chars (per IMP-007 spec).
        CB_ERR_HEAD=$(printf '%s' "$CB_ERR_TEXT" | head -c 200)
        if command -v sha256sum >/dev/null 2>&1; then
          CB_ERR_HASH=$(printf '%s' "$CB_ERR_HEAD" | sha256sum | cut -c1-16)
        elif command -v shasum >/dev/null 2>&1; then
          CB_ERR_HASH=$(printf '%s' "$CB_ERR_HEAD" | shasum -a 256 | cut -c1-16)
        else
          CB_ERR_HASH=""
        fi
        if [ -n "$CB_ERR_HASH" ]; then
          CB_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "1970-01-01T00:00:00Z")
          # Append + FIFO-cap at 20, atomically.
          _state_update --arg h "$CB_ERR_HASH" --arg t "$CB_TS" \
             '.circuit_breaker.recent_error_hashes = (((.circuit_breaker.recent_error_hashes // []) + [{"hash":$h,"ts":$t}]) | .[(if length > 20 then length - 20 else 0 end):])' "$STATE_FILE"
          # Count occurrences of this hash in the window.
          CB_COUNT=$(jq --arg h "$CB_ERR_HASH" -r '
            [ .circuit_breaker.recent_error_hashes[]? | select(.hash == $h) ] | length
          ' "$STATE_FILE" 2>/dev/null || echo 0)
          case "$CB_COUNT" in ''|*[!0-9]*) CB_COUNT=0 ;; esac
          if [ "$CB_COUNT" -ge 5 ]; then
            mkdir -p .apex 2>/dev/null
            if command -v emit_fix_plan >/dev/null 2>&1; then
              emit_fix_plan \
                --also-write-recovery-menu \
                "circuit-breaker" \
                "Circuit breaker tripped: STUCK ON RECURRING ERROR. The same error hash appeared $CB_COUNT times in the last 20 tool calls (threshold: 5). The executor is retrying the same failing action." \
                "Trigger: stuck_on_recurring_error (hash $CB_ERR_HASH count=$CB_COUNT)" \
                "/apex:forensics -- diagnose the recurring error and its trigger" \
                "/apex:rollback -- revert recent edits if they caused the loop" \
                "/apex:recover -- reset and re-plan with a different approach" \
                2>/dev/null || true
            else
              {
                echo "# Recovery Menu"
                echo ""
                echo "## Reason"
                echo "Circuit breaker tripped: STUCK ON RECURRING ERROR."
                echo "Same error hash appeared $CB_COUNT times in the last 20 tool calls (threshold: 5)."
                echo ""
                echo "## Options"
                echo "- \`/apex:forensics\` — diagnose the recurring error."
                echo "- \`/apex:rollback\` — revert recent edits if they caused the loop."
                echo "- \`/apex:recover\` — reset and re-plan with a different approach."
              } > .apex/RECOVERY_MENU.md 2>/dev/null
            fi
            {
              echo "🛑 SAFETY-STOP FIRED (circuit breaker): STUCK ON RECURRING ERROR"
              echo "   Same error hash ($CB_ERR_HASH) appeared $CB_COUNT times in the last 20 tool calls."
              echo "   Threshold: 5. The executor is retrying the same failing action."
              echo ""
              echo "   Fix plan written to: .apex/FIX_PLAN.md (also mirrored to .apex/RECOVERY_MENU.md)"
            } >&2
            _state_update '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = "stuck_on_recurring_error"' "$STATE_FILE"
            exit 2
          fi
        fi
      fi
    fi
  fi
fi

exit 0