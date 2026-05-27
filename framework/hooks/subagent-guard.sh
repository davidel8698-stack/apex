#!/bin/bash
set -u
# R16-618N (F-618, IMP-018): subagent-guard.sh — stateful context-aware
# detection of unattended-affirmation flags on destructive command families.
#
# Hook type: PreToolUse (Bash)
# Pairs with: destructive-guard.sh (R16-618D pure pattern half).
#
# Detection logic
#   Two-condition AND:
#     A. The Bash command contains an auto-yes flag in any of these forms:
#          --yes  |  -y (as a standalone token)  |  --auto-approve  |
#          --force-yes  |  --assume-yes  |  --no-confirm
#     B. The same command targets a known destructive family:
#          rm | rmdir | drop | delete | kill | shutdown | reboot |
#          truncate | format | mkfs | wipe | reset | purge |
#          terraform | kubectl
#
# Both must match in the SAME command segment so legitimate
# `apt-get install -y nginx` (auto-yes but non-destructive family) is
# allowed through, while `rm -rf /etc --yes` (auto-yes + destructive)
# blocks at exit 2.
#
# Carve-out: APEX_SUBAGENT_GUARD=off (emergency bypass — documented in
# framework/docs/SECURITY-RUNTIME.md).
#
# Exit codes
#   0 — clean (no destructive+yes correlation).
#   2 — blocked (correlation matched).

# Phase 8 R-P8-C4: canonical input extraction via shared helper.
# Closes F-006 (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

COMMAND=$(apex_hook_input_command "$@" 2>/dev/null || printf '%s' "${1:-}")

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Emergency bypass for test/sandbox fixtures.
if [ "${APEX_SUBAGENT_GUARD:-}" = "off" ]; then
  exit 0
fi

# Source the fix-plan emitter for structured failure output.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

# Quote-aware splitter (parity with destructive-guard.sh) so chained
# commands are evaluated per-segment. We reuse the same approach:
# track single/double quote context, split on unquoted && and ;.
_split_commands() {
  local cmd="$1"
  local len=${#cmd}
  local i=0
  local in_single=0
  local in_double=0
  local current=""

  while [ $i -lt $len ]; do
    local c="${cmd:$i:1}"
    local next="${cmd:$((i+1)):1}"

    if [ "$c" = "'" ] && [ $in_double -eq 0 ]; then
      in_single=$(( 1 - in_single ))
      current+="$c"
    elif [ "$c" = '"' ] && [ $in_single -eq 0 ]; then
      in_double=$(( 1 - in_double ))
      current+="$c"
    elif [ "$c" = "\\" ] && [ $in_single -eq 0 ] && [ $((i+1)) -lt $len ]; then
      current+="$c$next"
      i=$((i+1))
    elif [ $in_single -eq 0 ] && [ $in_double -eq 0 ]; then
      if [ "$c" = ";" ]; then
        echo "$current"
        current=""
      elif [ "$c" = "&" ] && [ "$next" = "&" ]; then
        echo "$current"
        current=""
        i=$((i+1))
      else
        current+="$c"
      fi
    else
      current+="$c"
    fi
    i=$((i+1))
  done
  [ -n "$current" ] && echo "$current"
}

check_segment() {
  local seg="$1"
  local norm
  norm=$(echo "$seg" | tr -s ' ' | sed 's/^ *//;s/ *$//')

  # Condition A: auto-yes flag present.
  local has_yes=0
  if echo "$norm" | grep -qiE "(^|[[:space:]])(--yes|--auto-approve|--force-yes|--assume-yes|--no-confirm)(\$|[[:space:]=])" 2>/dev/null; then
    has_yes=1
  fi
  # -y as standalone short flag (must be word-bounded so it doesn't match
  # tokens like -y2 or paths containing "y").
  if [ "$has_yes" -eq 0 ] && echo "$norm" | grep -qE "(^|[[:space:]])-y(\$|[[:space:]])" 2>/dev/null; then
    has_yes=1
  fi
  [ "$has_yes" -eq 0 ] && return 0

  # Condition B: command targets a destructive family.
  # Match against the first word OR any token that follows a destructive
  # subcommand verb (e.g., `kubectl delete`, `terraform destroy`).
  if echo "$norm" | grep -qiE "(^|[[:space:]])(rm|rmdir|drop|delete|kill|shutdown|reboot|truncate|format|mkfs|wipe|reset|purge)(\$|[[:space:]])" 2>/dev/null; then
    block "$seg" "auto-yes flag combined with destructive command family"
    return 1
  fi
  if echo "$norm" | grep -qiE "(^|[[:space:]])(terraform\s+destroy|kubectl\s+delete)" 2>/dev/null; then
    block "$seg" "auto-yes flag combined with infra-destructive command (terraform/kubectl)"
    return 1
  fi

  return 0
}

block() {
  echo "🛑 APEX SUBAGENT GUARD: BLOCKED" >&2
  echo "Command segment: $1" >&2
  echo "Matched: $2" >&2
  echo "" >&2
  echo "Unattended-affirmation flag (--yes / -y / --auto-approve / --force-yes)" >&2
  echo "combined with a destructive command family. Re-run interactively or" >&2
  echo "remove the auto-yes flag if you genuinely intend this operation." >&2
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "subagent-guard" \
      "Auto-yes flag combined with destructive command family blocked: $2" \
      "Blocked segment: $1" \
      "Re-run interactively (drop --yes / -y / --auto-approve)" \
      "/apex:recover -- decide whether the operation is genuinely intended" \
      2>/dev/null || true
  fi
}

BLOCKED=0
mapfile -t SEGMENTS < <(_split_commands "$COMMAND")
for seg in "${SEGMENTS[@]}"; do
  seg=$(echo "$seg" | sed 's/^ *//;s/ *$//')
  [ -z "$seg" ] && continue
  if ! check_segment "$seg"; then
    BLOCKED=1
    break
  fi
done

if [ "$BLOCKED" -eq 1 ]; then
  exit 2
fi

exit 0
