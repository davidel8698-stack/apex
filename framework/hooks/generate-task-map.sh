#!/bin/bash
source "$(dirname "$0")/_require-jq.sh"
require_jq
source "$(dirname "$0")/_require-git.sh"

# G-2: Ensure CWD is project root so .apex/ paths resolve
cd "$(git rev-parse --show-toplevel)" || exit 2

TASK_ID=${1:-"current"}
PHASE=$(cat .apex/STATE.json 2>/dev/null | jq -r '.current_phase // empty')

if [ -z "$PHASE" ]; then
  echo "⚠️  TASK MAP: no current phase in STATE.json — skipping map generation" >&2
  exit 0
fi

META_FILE=".apex/phases/$PHASE/PLAN_META.json"
OUT_FILE=".apex/TASK_MAP.md"

cat > "$OUT_FILE" << MAPHEADER
# Task-Specific Repository Map: $TASK_ID
Generated: $(date)

## Explicitly Required Files
MAPHEADER

CONTENT_WRITTEN=0

# [שיפור 21] Read files from PLAN_META.json instead of regex parsing
if [ -f "$META_FILE" ]; then
  EXPLICIT_FILES=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .files[]" "$META_FILE" 2>/dev/null)

  if [ -n "$EXPLICIT_FILES" ]; then
    CONTENT_WRITTEN=1
    for file in $EXPLICIT_FILES; do
      if [ -f "$file" ]; then
        echo "- $file ✅" >> "$OUT_FILE"
        grep -E "^(export )?(async )?(function|const|class)" "$file" 2>/dev/null | \
          head -4 | sed 's/^/  → /' >> "$OUT_FILE"
      else
        echo "- $file ⬜ (to be created)" >> "$OUT_FILE"
      fi
    done
  fi

  # Get task name for keyword search
  TASK_NAME=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .name" "$META_FILE" 2>/dev/null)
  KEYWORDS=$(echo "$TASK_NAME" | tr ' ' '\n' | grep -E "^[A-Za-z]{5,}" | \
    sort -u | head -6 | tr '\n' '|' | sed 's/|$//')

  if [ -n "$KEYWORDS" ] && command -v rg &>/dev/null; then
    RELATED=$(rg -l "$KEYWORDS" src/ lib/ app/ 2>/dev/null | \
      grep -v "node_modules\|.next\|.git" | head -6)
    if [ -n "$RELATED" ]; then
      CONTENT_WRITTEN=1
      echo "" >> "$OUT_FILE"
      echo "## Related Files (keyword search)" >> "$OUT_FILE"
      echo "$RELATED" | while read -r f; do
        echo "- $f" >> "$OUT_FILE"
        grep -n "$KEYWORDS" "$f" 2>/dev/null | head -2 | sed 's/^/  → /' >> "$OUT_FILE"
      done
    fi
  fi
else
  # Fallback: old regex method if PLAN_META.json doesn't exist
  # NOTE: For quick tasks (quick-* IDs from /apex:quick), PLAN_META.json won't exist.
  # Header-only output with exit 1 is expected and non-fatal in that context.
  PLAN_FILE=".apex/phases/$PHASE/PLAN.md"
  if [ -f "$PLAN_FILE" ]; then
    FALLBACK_FILES=$(grep -A30 "id=\"$TASK_ID\"" "$PLAN_FILE" 2>/dev/null | \
      grep -E "src/|lib/|app/|api/" | sed 's/<[^>]*>//g' | tr -d ' ' | grep -v "^$")
    if [ -n "$FALLBACK_FILES" ]; then
      CONTENT_WRITTEN=1
      echo "$FALLBACK_FILES" | while read -r file; do
        if [ -f "$file" ]; then
          echo "- $file ✅" >> "$OUT_FILE"
        else
          echo "- $file ⬜ (to be created)" >> "$OUT_FILE"
        fi
      done
    fi
  fi
fi

echo "" >> "$OUT_FILE"
echo "## Note: Verify file existence before using. Map may be slightly stale." >> "$OUT_FILE"

if [ "$CONTENT_WRITTEN" -eq 1 ]; then
  echo "✅ Task map generated: $OUT_FILE"
  exit 0
else
  echo "⚠️  TASK MAP: no files resolved for task '$TASK_ID'" >&2
  echo "   Reason: PLAN_META.json missing, task not found, or no explicit files" >&2
  echo "   Output contains header + trailer only: $OUT_FILE" >&2
  exit 1
fi
