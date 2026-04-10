#!/bin/bash
set -u
# v7: Tiered enforcement + type-specific decay + write gates [R6]
# Validates citations, enforces HOT tier ceiling, decay-class-aware staleness

LEARNINGS=~/.claude/apex-learnings.md
STALE=0
DECAYED=0
HOT_COUNT=0
WARM_COUNT=0
CURRENT_SECTION=""
CURRENT_DECAY=""
CURRENT_ENTRY=""
NOW_EPOCH=$(date +%s)

[ ! -f "$LEARNINGS" ] && exit 0

# v7 [R6]: Map decay class to max days
decay_max_days() {
  case "$1" in
    safety)        echo 999999 ;;
    architectural) echo 365 ;;
    bug)           echo 180 ;;
    framework)     echo 90 ;;
    project)       echo 30 ;;
    *)             echo 90 ;;
  esac
}

while IFS= read -r line; do
  # Track which section we're in
  if [[ "$line" =~ ^##[[:space:]]HOT ]]; then
    CURRENT_SECTION="HOT"
  elif [[ "$line" =~ ^##[[:space:]]WARM ]]; then
    CURRENT_SECTION="WARM"
  elif [[ "$line" =~ ^##[[:space:]]COLD ]]; then
    CURRENT_SECTION="COLD"
  elif [[ "$line" =~ ^##[[:space:]] ]]; then
    CURRENT_SECTION="OTHER"
  fi

  # Count entries per tier and track current entry name
  if [[ "$line" =~ ^###[[:space:]]\[ ]]; then
    CURRENT_ENTRY="$line"
    CURRENT_DECAY=""
    case "$CURRENT_SECTION" in
      HOT) HOT_COUNT=$((HOT_COUNT + 1)) ;;
      WARM) WARM_COUNT=$((WARM_COUNT + 1)) ;;
    esac
  fi

  # v7 [R6]: Read decay class from entry
  if [[ "$line" =~ \*\*Decay:\*\*[[:space:]]*([a-z]+) ]]; then
    CURRENT_DECAY="${BASH_REMATCH[1]}"
  fi

  # v7 [R6]: Check date-based staleness with decay-class-aware thresholds
  if [[ "$line" =~ \*\*Verified:\*\*[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}) ]] || \
     [[ "$line" =~ \*\*Citation:\*\*.*([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    ENTRY_DATE="${BASH_REMATCH[1]}"
    if date -d "$ENTRY_DATE" +%s &>/dev/null; then
      ENTRY_EPOCH=$(date -d "$ENTRY_DATE" +%s)
      DAYS_OLD=$(( (NOW_EPOCH - ENTRY_EPOCH) / 86400 ))
      MAX_DAYS=$(decay_max_days "$CURRENT_DECAY")
      if [ "$DAYS_OLD" -gt "$MAX_DAYS" ] && [ "$CURRENT_SECTION" != "COLD" ]; then
        echo "⏰ DECAYED: $CURRENT_ENTRY (${DAYS_OLD}d old, decay=$CURRENT_DECAY, max=${MAX_DAYS}d)"
        DECAYED=$((DECAYED + 1))
      fi
    fi
  fi

  # Check citations — extract file:line patterns from citation text
  if [[ "$line" =~ \*\*Citation:\*\*[[:space:]]*([^:]+):([0-9]+) ]]; then
    RAW_REF="${BASH_REMATCH[1]}"
    # Extract just the filename: last space-separated token that looks like a path
    # Handles "Round 3.2 C-3 — critic.md" → "critic.md"
    FILE=$(echo "$RAW_REF" | grep -oE '[^ ]*\.[a-zA-Z]+$' || echo "$RAW_REF")
    # Skip template/example citations (contain placeholder text)
    if [[ "$FILE" == *"project-"* ]] || [[ "$FILE" == *"["*"]"* ]]; then
      continue
    fi
    # Resolve paths: check relative, src/, project, and framework (~/.claude/) locations
    EXPANDED_FILE="${FILE/#\~/$HOME}"
    if [ ! -f "$FILE" ] && [ ! -f "src/$FILE" ] && [ ! -f "./$FILE" ] \
       && [ ! -f "$EXPANDED_FILE" ] \
       && [ ! -f "$HOME/.claude/agents/$FILE" ] \
       && [ ! -f "$HOME/.claude/commands/apex/$FILE" ]; then
      echo "⚠️ STALE CITATION: $CURRENT_ENTRY — $FILE (file not found)"
      STALE=$((STALE + 1))
    fi
  fi
done < "$LEARNINGS"

# v7: Tier enforcement
if [ "$HOT_COUNT" -gt 30 ]; then
  echo "⚠️ HOT tier over capacity: $HOT_COUNT entries (max: 30). Demote least-used to WARM."
fi

if [ "$WARM_COUNT" -gt 100 ]; then
  echo "⚠️ WARM tier over capacity: $WARM_COUNT entries (max: 100). Archive oldest to COLD."
fi

# Report
ISSUES=$((STALE + DECAYED))
if [ "$ISSUES" -gt 0 ]; then
  [ "$STALE" -gt 0 ] && echo "⚠️ $STALE stale citations. Review apex-learnings.md."
  [ "$DECAYED" -gt 0 ] && echo "⏰ $DECAYED entries past decay threshold. Move to COLD."
else
  echo "✅ All citations valid | HOT: $HOT_COUNT/30 | WARM: $WARM_COUNT/100"
fi

if [ "$ISSUES" -gt 0 ] || [ "$HOT_COUNT" -gt 30 ] || [ "$WARM_COUNT" -gt 100 ]; then exit 1; fi
exit 0