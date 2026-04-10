#!/bin/bash
# v7: Hardened against bypass — normalized matching, chained command splitting [R1]
# R1: 10 documented destructive incidents, 0 vendor postmortems
# Hook type: PreToolUse (Bash)

COMMAND="$1"

# v7: Split chained commands and check each segment
# Handles: cmd1 && cmd2, cmd1 ; cmd2
check_segment() {
  local SEGMENT="$1"

  # v7.1 [B-7]: Strip quoted strings only from known-safe (read-only) commands.
  # This prevents false positives on echo "rm -rf /" or grep "DROP TABLE"
  # while preserving detection of psql -c "DROP TABLE users" (execution command).
  local STRIPPED="$SEGMENT"
  local FIRST_WORD
  FIRST_WORD=$(echo "$SEGMENT" | sed 's/^ *//' | cut -d' ' -f1)
  case "$FIRST_WORD" in
    echo|printf|grep|egrep|fgrep|rg|sed|awk|cat|head|tail|wc|sort|uniq|diff|test|\[)
      # Read-only commands: quoted args are data, not execution — safe to strip
      STRIPPED=$(echo "$SEGMENT" | sed 's/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g')
      ;;
  esac

  # Normalize: collapse whitespace, lowercase for matching
  local NORMALIZED
  NORMALIZED=$(echo "$STRIPPED" | tr -s ' ' | sed 's/^ *//;s/ *$//')

  # === DENY PATTERNS (exact and regex) ===

  # Destructive rm patterns — normalize flags then check for recursive+force combo
  if echo "$NORMALIZED" | grep -qiE "^rm\s+" 2>/dev/null; then
    local HAS_RECURSIVE=0 HAS_FORCE=0 HAS_DANGEROUS_TARGET=0
    # Check all flag forms: -r, -R, --recursive, embedded in combined flags like -rf
    if echo "$NORMALIZED" | grep -qiE "(-[a-zA-Z]*[rR]|--recursive)" 2>/dev/null; then HAS_RECURSIVE=1; fi
    if echo "$NORMALIZED" | grep -qiE "(-[a-zA-Z]*f|--force)" 2>/dev/null; then HAS_FORCE=1; fi
    if echo "$NORMALIZED" | grep -qE "\s(/|~|\.\.|\.|\*)" 2>/dev/null; then HAS_DANGEROUS_TARGET=1; fi
    if [ "$HAS_RECURSIVE" -eq 1 ] && [ "$HAS_FORCE" -eq 1 ] && [ "$HAS_DANGEROUS_TARGET" -eq 1 ]; then
      block "$SEGMENT" "rm with recursive+force on dangerous target"
      return 1
    fi
  fi

  # Git destructive operations
  if echo "$NORMALIZED" | grep -qiE "git\s+(reset\s+--hard|clean\s+-[a-zA-Z]*f)" 2>/dev/null; then
    block "$SEGMENT" "git reset --hard / git clean -f"
    return 1
  fi

  # v7: git push --force (all variants)
  if echo "$NORMALIZED" | grep -qiE "git\s+push\s+(-[a-zA-Z]*f|--force|--force-with-lease)" 2>/dev/null; then
    block "$SEGMENT" "git push --force"
    return 1
  fi

  # SQL destructive operations
  if echo "$NORMALIZED" | grep -qiE "(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX)|TRUNCATE\s+TABLE)" 2>/dev/null; then
    block "$SEGMENT" "SQL DROP/TRUNCATE"
    return 1
  fi

  # v7: ALTER TABLE DROP (column/constraint drops)
  if echo "$NORMALIZED" | grep -qiE "ALTER\s+TABLE\s+.*\s+DROP\s+" 2>/dev/null; then
    block "$SEGMENT" "ALTER TABLE DROP"
    return 1
  fi

  # v7: DELETE FROM without WHERE (mass deletion)
  if echo "$NORMALIZED" | grep -qiE "DELETE\s+FROM\s+" 2>/dev/null; then
    if ! echo "$NORMALIZED" | grep -qiE "WHERE\s+" 2>/dev/null; then
      block "$SEGMENT" "DELETE FROM without WHERE clause"
      return 1
    fi
  fi

  # Infrastructure destruction
  if echo "$NORMALIZED" | grep -qiE "(terraform\s+destroy|kubectl\s+delete\s+namespace)" 2>/dev/null; then
    block "$SEGMENT" "infrastructure destruction"
    return 1
  fi

  # System-level destruction
  if echo "$NORMALIZED" | grep -qiE "(docker\s+system\s+prune\s+-[a-zA-Z]*a[a-zA-Z]*f|chmod\s+-R\s+777|mkfs\.|>\s*/dev/sd|dd\s+if=/dev/zero)" 2>/dev/null; then
    block "$SEGMENT" "system-level destructive command"
    return 1
  fi

  # Fork bomb
  if echo "$NORMALIZED" | grep -q ':(){ :|:& };:' 2>/dev/null; then
    block "$SEGMENT" "fork bomb"
    return 1
  fi

  # rm -rf with parent directory traversal
  if echo "$NORMALIZED" | grep -qE "rm\s+(-[a-zA-Z]*r[a-zA-Z]*|--recursive)\s+\.\." 2>/dev/null; then
    block "$SEGMENT" "rm -rf with parent directory traversal"
    return 1
  fi

  return 0
}

block() {
  echo "🛑 APEX DESTRUCTIVE GUARD: BLOCKED"
  echo "Command segment: $1"
  echo "Matched: $2"
  echo ""
  echo "This command is on APEX's deny-list. It cannot be executed."
  echo "If you believe this is a false positive, use the manual terminal."
}

# v7: Split on && and ; — check each segment independently
# This prevents bypass via: innocent_cmd && rm -rf /
# Note: pipes (|) are data flow, not command chains — not split
#
# v7.1 [B-7]: Quote-aware splitting. Naive sed split on && and ; breaks
# inside quoted strings (e.g., echo "a && b" would be split incorrectly).
# Solution: pure-bash state machine that tracks single/double quote context.
BLOCKED=0

# Quote-aware command splitter: splits on unquoted && and ;
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
      # Escaped character — skip next char
      current+="$c$next"
      i=$((i+1))
    elif [ $in_single -eq 0 ] && [ $in_double -eq 0 ]; then
      if [ "$c" = ";" ]; then
        echo "$current"
        current=""
      elif [ "$c" = "&" ] && [ "$next" = "&" ]; then
        echo "$current"
        current=""
        i=$((i+1))  # skip second &
      else
        current+="$c"
      fi
    else
      current+="$c"
    fi
    i=$((i+1))
  done
  # Emit last segment
  [ -n "$current" ] && echo "$current"
}

mapfile -t SEGMENT_ARRAY < <(_split_commands "$COMMAND")

for segment in "${SEGMENT_ARRAY[@]}"; do
  segment=$(echo "$segment" | sed 's/^ *//;s/ *$//')
  [ -z "$segment" ] && continue
  if ! check_segment "$segment"; then
    BLOCKED=1
    break
  fi
done

if [ "$BLOCKED" -eq 1 ]; then
  exit 2
fi

exit 0