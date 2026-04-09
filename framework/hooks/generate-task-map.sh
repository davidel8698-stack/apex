#!/bin/bash
TASK_ID=${1:-"current"}
PHASE=$(cat .apex/STATE.json 2>/dev/null | jq -r '.current_phase // empty')
META_FILE=".apex/phases/$PHASE/PLAN_META.json"

cat > .apex/TASK_MAP.md << MAPHEADER
# Task-Specific Repository Map: $TASK_ID
Generated: $(date)

## Explicitly Required Files
MAPHEADER

# [שיפור 21] Read files from PLAN_META.json instead of regex parsing
if [ -f "$META_FILE" ] && command -v jq &>/dev/null; then
  EXPLICIT_FILES=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .files[]" "$META_FILE" 2>/dev/null)

  for file in $EXPLICIT_FILES; do
    if [ -f "$file" ]; then
      echo "- $file ✅" >> .apex/TASK_MAP.md
      grep -E "^(export )?(async )?(function|const|class)" "$file" 2>/dev/null | \
        head -4 | sed 's/^/  → /' >> .apex/TASK_MAP.md
    else
      echo "- $file ⬜ (to be created)" >> .apex/TASK_MAP.md
    fi
  done

  # Get task name for keyword search
  TASK_NAME=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\") | .name" "$META_FILE" 2>/dev/null)
  KEYWORDS=$(echo "$TASK_NAME" | tr ' ' '\n' | grep -E "^[A-Za-z]{5,}" | \
    sort -u | head -6 | tr '\n' '|' | sed 's/|$//')

  if [ -n "$KEYWORDS" ]; then
    echo "" >> .apex/TASK_MAP.md
    echo "## Related Files (keyword search)" >> .apex/TASK_MAP.md
    rg -l "$KEYWORDS" src/ lib/ app/ 2>/dev/null | \
      grep -v "node_modules\|.next\|.git" | head -6 | \
      while read -r f; do
        echo "- $f" >> .apex/TASK_MAP.md
        grep -n "$KEYWORDS" "$f" 2>/dev/null | head -2 | sed 's/^/  → /' >> .apex/TASK_MAP.md
      done
  fi
else
  # Fallback: old regex method if PLAN_META.json doesn't exist
  PLAN_FILE=".apex/phases/$PHASE/PLAN.md"
  if [ -f "$PLAN_FILE" ]; then
    grep -A30 "id=\"$TASK_ID\"" "$PLAN_FILE" 2>/dev/null | \
      grep -E "src/|lib/|app/|api/" | sed 's/<[^>]*>//g' | tr -d ' ' | grep -v "^$" | \
      while read -r file; do
        if [ -f "$file" ]; then
          echo "- $file ✅" >> .apex/TASK_MAP.md
        else
          echo "- $file ⬜ (to be created)" >> .apex/TASK_MAP.md
        fi
      done
  fi
fi

echo "" >> .apex/TASK_MAP.md
echo "## Note: Verify file existence before using. Map may be slightly stale." >> .apex/TASK_MAP.md
echo "✅ Task map generated: .apex/TASK_MAP.md"

exit 0