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
  # Files changed — reset no-change counter. Stamp tool_calls_at_last_change
  # (v8 CHECK 2 Probe 1) ONLY when git diff is genuinely non-empty — the
  # empty-diff "empty_<timestamp>" hash trick makes every empty-diff call
  # look like a change, which would defeat the stagnation probe.
  if [ -n "$GIT_DIFF_OUTPUT" ]; then
    CB_TC_NOW=$(jq -r '.circuit_breaker.total_tool_calls_this_task // 0' "$STATE_FILE" 2>/dev/null)
    case "$CB_TC_NOW" in ''|*[!0-9]*) CB_TC_NOW=0 ;; esac
    _state_update --arg hash "$CURRENT_HASH" --argjson tc "$CB_TC_NOW" \
       '.circuit_breaker.consecutive_no_change_actions = 0
        | .circuit_breaker.last_file_hash = $hash
        | .circuit_breaker.tool_calls_at_last_change = $tc
        | .circuit_breaker.triggered = false' "$STATE_FILE"
  else
    _state_update --arg hash "$CURRENT_HASH" \
       '.circuit_breaker.consecutive_no_change_actions = 0
        | .circuit_breaker.last_file_hash = $hash
        | .circuit_breaker.triggered = false' "$STATE_FILE"
  fi
fi

# === CHECK 2: v8 — Health-checkpoint tool-call cap (replaces v7 dumb counter) ===
# The cap is no longer a ceiling — it is a periodic health checkpoint. When
# reached, run a probe over CHECK 1/3/4 signals. Healthy → bump cap by 50%
# of cap_original and continue indefinitely (no extension ceiling).
# Unhealthy → fire as v7 did, with the specific failing probe in the reason.
# Stderr warnings at 50/75/90% of current cap (advisory only).
# Snapshot read + probe done in one jq invocation for atomicity.

# Atomic increment + snapshot cap_original on first use of this task.
_state_update \
   '.circuit_breaker.total_tool_calls_this_task = ((.circuit_breaker.total_tool_calls_this_task // 0) + 1)
    | .circuit_breaker.cap_original = (.circuit_breaker.cap_original // .circuit_breaker.max_tool_calls_per_task // 80)' \
   "$STATE_FILE"

# Single jq read for the probe inputs — race-free.
CB2_SNAPSHOT=$(jq -r '
  [
    (.circuit_breaker.total_tool_calls_this_task // 0),
    (.circuit_breaker.max_tool_calls_per_task   // 80),
    (.circuit_breaker.cap_original              // 80),
    (.circuit_breaker.cap_extensions_used       // 0),
    (.circuit_breaker.tool_calls_at_last_change // 0),
    (.circuit_breaker.last_warning_threshold    // 0),
    ([ .circuit_breaker.recent_error_hashes[]?.hash   ] | group_by(.) | map(length) | max // 0),
    ([ .circuit_breaker.recent_command_hashes[]?.hash ] | group_by(.) | map(length) | max // 0)
  ] | @tsv
' "$STATE_FILE" 2>/dev/null)

IFS=$'\t' read -r TOOL_CALLS SOFT_CAP CAP_ORIGINAL EXT_USED TC_AT_CHANGE LAST_WARN MAX_ERR_COUNT MAX_CMD_COUNT <<<"${CB2_SNAPSHOT:-0	80	80	0	0	0	0	0}"
for v in TOOL_CALLS SOFT_CAP CAP_ORIGINAL EXT_USED TC_AT_CHANGE MAX_ERR_COUNT MAX_CMD_COUNT; do
  eval "case \"\${$v:-0}\" in ''|*[!0-9]*) $v=0 ;; esac"
done
[ -z "${LAST_WARN:-}" ] && LAST_WARN=0

# --- Escalating stderr warnings (advisory, no block) ---
cb2_emit_warning() {
  local pct="$1" frac="$2" need_warn
  need_warn=$(awk -v tc="$TOOL_CALLS" -v cap="$SOFT_CAP" -v f="$frac" -v lw="$LAST_WARN" \
    'BEGIN { print ( (tc >= cap*f) && (lw < f) ) ? 1 : 0 }' 2>/dev/null || echo 0)
  if [ "$need_warn" = "1" ]; then
    echo "⚠️  CB CHECK 2 (advisory): ${pct}% of cap reached (${TOOL_CALLS}/${SOFT_CAP}). Extensions so far this task: ${EXT_USED}." >&2
    _state_update --arg f "$frac" '.circuit_breaker.last_warning_threshold = ($f | tonumber)' "$STATE_FILE"
    LAST_WARN="$frac"
  fi
}
cb2_emit_warning 50  0.5
cb2_emit_warning 75  0.75
cb2_emit_warning 90  0.9

# --- Cap reached? Probe + extend-or-fire decision. ---
if [ "$TOOL_CALLS" -ge "$SOFT_CAP" ]; then
  HEALTH_OK=1
  REASON=""

  # Probe 1: files moving in last 50 calls
  STALE_DELTA=$(( TOOL_CALLS - TC_AT_CHANGE ))
  if [ "$STALE_DELTA" -gt 50 ]; then
    HEALTH_OK=0
    REASON="no file changes in last ${STALE_DELTA} tool calls (stagnant)"
  fi

  # Probe 2: recurring error (earlier than CHECK 3's own threshold of 5)
  if [ "$HEALTH_OK" = "1" ] && [ "$MAX_ERR_COUNT" -ge 3 ]; then
    HEALTH_OK=0
    REASON="recurring error (same error hash ${MAX_ERR_COUNT} times in last 20 calls)"
  fi

  # Probe 3: result-fishing
  if [ "$HEALTH_OK" = "1" ] && [ "$MAX_CMD_COUNT" -ge 5 ]; then
    HEALTH_OK=0
    REASON="result-fishing (same tool+args ${MAX_CMD_COUNT} times in last 20 calls)"
  fi

  FIRE_REASON=""
  FIRE_MSG=""

  if [ "$HEALTH_OK" = "1" ]; then
    # Healthy → bump cap by 50% of ORIGINAL and continue. No upper bound on
    # extensions: as long as the trajectory stays healthy, the task runs.
    BASIS="$CAP_ORIGINAL"
    [ "$BASIS" -le 0 ] && BASIS="$SOFT_CAP"
    EXT_BUMP=$(( BASIS / 2 ))
    [ "$EXT_BUMP" -lt 1 ] && EXT_BUMP=1
    NEW_CAP=$(( SOFT_CAP + EXT_BUMP ))
    NEW_EXT=$(( EXT_USED + 1 ))

    _state_update --argjson nc "$NEW_CAP" --argjson ne "$NEW_EXT" \
       '.circuit_breaker.max_tool_calls_per_task = $nc
        | .circuit_breaker.cap_extensions_used   = $ne
        | .circuit_breaker.last_warning_threshold = 0' "$STATE_FILE"

    mkdir -p .apex 2>/dev/null
    {
      printf '[%s] task=%s ext=%d cap=%d->%d basis=%d reason=healthy probes=files_moving,no_recurring_err,no_fishing\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)" \
        "$(jq -r '.current_task // "unknown"' "$STATE_FILE" 2>/dev/null)" \
        "$NEW_EXT" "$SOFT_CAP" "$NEW_CAP" "$BASIS"
    } >> .apex/cb_extensions.log 2>/dev/null || true

    echo "♻️  CB CHECK 2: cap reached but trajectory healthy. Auto-extending ${SOFT_CAP} → ${NEW_CAP} (extension #${NEW_EXT}). Files moving, no recurring errors, no fishing. Will re-check at next cap." >&2
  else
    FIRE_REASON="tool_call_cap"
    FIRE_MSG="Tool-call cap reached AND health probe failed: ${REASON}. Cap=${SOFT_CAP}, calls=${TOOL_CALLS}, extensions so far=${EXT_USED}."
  fi

  if [ -n "$FIRE_REASON" ]; then
    mkdir -p .apex 2>/dev/null
    if command -v emit_fix_plan >/dev/null 2>&1; then
      emit_fix_plan \
        --also-write-recovery-menu \
        "circuit-breaker" \
        "Circuit breaker tripped: ${FIRE_MSG} R7: Failed trajectories cost 4x+ more tokens than successful ones." \
        "Trigger: ${FIRE_REASON} (count ${TOOL_CALLS}, cap ${SOFT_CAP}, ext ${EXT_USED})" \
        "/apex:forensics -- diagnose where the trajectory diverged. Use when you want a timeline of the runaway." \
        "/apex:rollback -- revert recent edits to the last green tag. Use when the task corrupted state you want to discard." \
        "/apex:recover -- reset and re-plan the unit. Use when you want to keep edits but retry with fresh context." \
        2>/dev/null || true
    else
      {
        echo "# Recovery Menu"
        echo ""
        echo "## Reason"
        echo "Circuit breaker tripped: ${FIRE_MSG}"
        echo ""
        echo "## Options"
        echo "- \`/apex:forensics\` — diagnose where the trajectory diverged."
        echo "- \`/apex:rollback\`  — revert recent edits."
        echo "- \`/apex:recover\`   — reset and re-plan."
      } > .apex/RECOVERY_MENU.md 2>/dev/null
    fi

    {
      echo "🛑 SAFETY-STOP FIRED (circuit breaker): ${FIRE_REASON}"
      echo "   ${FIRE_MSG}"
      echo ""
      echo "   Fix plan written to: .apex/FIX_PLAN.md (also mirrored to .apex/RECOVERY_MENU.md)"
      echo ""
      echo "   Options:"
      echo "   1. /apex:forensics — diagnose where it went off the rails (timeline reconstruction)"
      echo "   2. /apex:rollback  — revert recent edits"
      echo "   3. /apex:recover   — reset and re-plan"
    } >&2

    _state_update --arg r "$FIRE_REASON" \
       '.circuit_breaker.triggered = true | .circuit_breaker.trigger_reason = $r' "$STATE_FILE"
    exit 2
  fi
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
# from a non-Claude-Code context (CLI tests, or /apex:self-heal's post-wave
# breaker probe). `[ ! -t 0 ]` only distinguishes a TTY from a non-TTY — a
# non-TTY stdin can be a *closed* pipe (cat hits EOF, no-ops) OR an *open*
# pipe with no live writer (an unguarded `cat` would block indefinitely).
# A bounded `read` (timeout CB_STDIN_TIMEOUT seconds) prevents that hang: it
# drains whatever payload is present, and on a timeout treats stdin as
# no-payload AND emits a loud one-line diagnostic to stderr (fail-loud,
# never fail-silent). CB_STDIN_BUF is pre-initialized to "" so it is set on
# every path — `set -u` is satisfied and CHECK 4 can always reuse it.
CB_STDIN_BUF=""
CB_STDIN_TIMEOUT=3
if [ ! -t 0 ]; then
  if IFS= read -r -t "$CB_STDIN_TIMEOUT" -d '' CB_STDIN_BUF; then
    : # full payload drained on EOF (delimiter never seen) — CB_STDIN_BUF set
  else
    CB_STDIN_READ_RC=$?
    # read returns >128 on timeout, 1 on EOF-before-delimiter. On EOF the
    # partial input is still placed in CB_STDIN_BUF (bash semantics); only a
    # genuine timeout is the failure mode we must announce loudly.
    if [ "$CB_STDIN_READ_RC" -gt 128 ]; then
      CB_STDIN_BUF=""
      echo "circuit-breaker: stdin read timed out after ${CB_STDIN_TIMEOUT}s; treating as no-payload" >&2
    fi
  fi
fi
if [ ! -t 0 ]; then
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
        # === R17-640 (F-640, IMP-016): denied-class classifier ===
        # Inspect the lowercased error text against the six denied-class
        # tokens and, on a match, call _record_denied_error to populate
        # STATE.recent_denied_error_window for sequence-guard.sh's
        # consumer (IMP-016 writer-side). Placed OUTSIDE the
        # `[ -n "$CB_ERR_HASH" ]` block so hashing-utility absence (no
        # sha256sum / shasum on PATH) does NOT short-circuit the
        # classifier — recurring-error-hash and denied-class signals are
        # orthogonal. Categories map per _record_denied_error enum:
        # unauthorized / forbidden / 403 / 401 / denied / missing_token.
        CB_TOOL_NAME=$(echo "$CB_STDIN_BUF" | jq -r '.tool_name // empty' 2>/dev/null || true)
        CB_ERR_LC=$(printf '%s' "$CB_ERR_TEXT" | tr '[:upper:]' '[:lower:]')
        CB_DENIED_CAT=""
        case "$CB_ERR_LC" in
          *unauthorized*) CB_DENIED_CAT=unauthorized ;;
          *forbidden*)    CB_DENIED_CAT=forbidden ;;
          *403*)          CB_DENIED_CAT=403 ;;
          *401*)          CB_DENIED_CAT=401 ;;
          *"missing token"*|*"missing-token"*) CB_DENIED_CAT=missing_token ;;
          *denied*)       CB_DENIED_CAT=denied ;;
        esac
        if [ -n "$CB_DENIED_CAT" ]; then
          _record_denied_error "$CB_DENIED_CAT" "${CB_TOOL_NAME:-unknown}"
        fi
      fi
    fi
  fi
fi

# === CHECK 4: Result-fishing detection — same (command, args) repeating (R16-624, F-624, IMP-024) ===
# Reads the PreToolUse stdin envelope. sha256-hashes the canonical
# "<tool_name>|<sorted-args-json>" string and maintains a 20-call FIFO ring
# buffer in STATE.circuit_breaker.recent_command_hashes[]. When any one hash
# reaches >=5 occurrences in the window, the breaker ESCALATES (status
# banner + alternative-approach suggestion) — it does NOT halt (exit 2).
# This is the key difference from CHECK 3: result-fishing is a productivity
# warning, not a safety stop. The user/orchestrator should rethink the
# approach, but blocking would be over-firing on legitimate retry loops
# like `npm test`. CHECK 1 / 2 / 3 catch the safety-critical cases.
#
# CHECK 4 reuses the CB_STDIN_BUF captured by CHECK 3 when the envelope is
# present. Falls back to a fresh stdin read only if CHECK 3 did not run
# (e.g., PostToolUse fields were absent and the buffer was empty). The
# explicit `${CB_STDIN_BUF:-}` reference keeps `set -u` happy.
if [ ! -t 0 ]; then
  CB4_BUF="${CB_STDIN_BUF:-}"
  if [ -n "$CB4_BUF" ] && command -v jq >/dev/null 2>&1; then
    # PreToolUse envelope provides `tool_name` and `tool_input`. PostToolUse
    # provides the same plus `tool_response`. Either shape works for CHECK 4
    # — we only need the request side.
    CB4_TOOL=$(echo "$CB4_BUF" | jq -r '.tool_name // empty' 2>/dev/null || true)
    CB4_ARGS=$(echo "$CB4_BUF" | jq -cS '.tool_input // {}' 2>/dev/null || echo "{}")
    if [ -n "$CB4_TOOL" ]; then
      CB4_CANON="$CB4_TOOL|$CB4_ARGS"
      if command -v sha256sum >/dev/null 2>&1; then
        CB4_HASH=$(printf '%s' "$CB4_CANON" | sha256sum | cut -c1-16)
      elif command -v shasum >/dev/null 2>&1; then
        CB4_HASH=$(printf '%s' "$CB4_CANON" | shasum -a 256 | cut -c1-16)
      else
        CB4_HASH=""
      fi
      if [ -n "$CB4_HASH" ]; then
        CB4_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "1970-01-01T00:00:00Z")
        _state_update --arg h "$CB4_HASH" --arg t "$CB4_TS" \
           '.circuit_breaker.recent_command_hashes = (((.circuit_breaker.recent_command_hashes // []) + [{"hash":$h,"ts":$t}]) | .[(if length > 20 then length - 20 else 0 end):])' "$STATE_FILE"
        CB4_COUNT=$(jq --arg h "$CB4_HASH" -r '
          [ .circuit_breaker.recent_command_hashes[]? | select(.hash == $h) ] | length
        ' "$STATE_FILE" 2>/dev/null || echo 0)
        case "$CB4_COUNT" in ''|*[!0-9]*) CB4_COUNT=0 ;; esac
        if [ "$CB4_COUNT" -ge 5 ]; then
          # Escalate (warn, do not halt). Write a FIX_PLAN entry so the user
          # has the suggested alternative approach, but exit 0 so the
          # orchestrator continues — this is a productivity nudge, not a
          # destructive event.
          mkdir -p .apex 2>/dev/null
          if command -v emit_fix_plan >/dev/null 2>&1; then
            emit_fix_plan \
              "circuit-breaker" \
              "Result-fishing detected: the same (tool, arguments) call was issued $CB4_COUNT times in the last 20 tool calls (threshold: 5). Consider an alternative approach — re-running the same call rarely produces a different result." \
              "Trigger: result_fishing (tool=$CB4_TOOL hash=$CB4_HASH count=$CB4_COUNT)" \
              "/apex:forensics -- review what changed between the calls (if anything)" \
              "/apex:recover -- step back and try a different angle on this task" \
              "/apex:status -- check the status banner for the alternative approach suggestion" \
              2>/dev/null || true
          fi
          {
            echo "⚠️  APEX CIRCUIT BREAKER (advisory, CHECK 4): RESULT-FISHING DETECTED"
            echo "   Same (tool, args) hash ($CB4_HASH) seen $CB4_COUNT times in the last 20 calls."
            echo "   Threshold: 5. Consider an alternative approach — re-running rarely changes output."
            echo "   Suggestion: try a different tool, different arguments, or step back to /apex:recover."
          } >&2
          # No STATE flag write — the ring buffer itself is the persistent
          # signal (`/apex:status` can re-count). Adding a flag would also
          # require a schema entry; CHECK 4 is warn-only, so the stderr +
          # FIX_PLAN.md emission is the user-visible surface.
        fi
      fi
    fi
  fi
fi

exit 0