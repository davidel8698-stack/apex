#!/bin/bash
set -u
# APEX Session Guardian — session-log.sh
# Usage: bash ~/.claude/hooks/session-log.sh <event_type> <hebrew_message>
# Appends a single line to .apex/SESSION-LOG.md
# Called explicitly by /apex:next, NOT via settings.json matcher (zero overhead).

EVENT_TYPE="${1:-info}"
MESSAGE="${2:-}"
TIMESTAMP=$(date "+%H:%M")
DATE_HEADER=$(date "+%Y-%m-%d")

LOG_FILE=".apex/SESSION-LOG.md"

# Create file with header if new
if [ ! -f "$LOG_FILE" ]; then
  mkdir -p .apex
  cat > "$LOG_FILE" << 'HEADER'
# יומן סשן APEX
> קובץ זה מתעדכן אוטומטית. אפשר לפתוח ולרענן בכל רגע.

HEADER
fi

# Add date separator if new day
LAST_DATE=$(grep "^## " "$LOG_FILE" 2>/dev/null | tail -1 | sed 's/^## //')
if [ "$LAST_DATE" != "$DATE_HEADER" ]; then
  echo "" >> "$LOG_FILE"
  echo "## $DATE_HEADER" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
fi

# Event type to icon
case "$EVENT_TYPE" in
  checkpoint)      ICON="✅" ;;
  fail)            ICON="❌" ;;
  partial)         ICON="⚠️" ;;
  auto_pause)      ICON="🛑" ;;
  warning)         ICON="🟡" ;;
  rotate)          ICON="🔄" ;;
  wave_complete)   ICON="🌊" ;;
  phase_complete)  ICON="🏁" ;;
  coherence_fail)  ICON="💥" ;;
  phantom_fail)    ICON="👻" ;;
  resume)          ICON="▶️" ;;
  start)           ICON="🚀" ;;
  bypass)          ICON="⏩" ;;
  *)               ICON="📝" ;;
esac

echo "${TIMESTAMP} ${ICON} ${MESSAGE}" >> "$LOG_FILE"

exit 0