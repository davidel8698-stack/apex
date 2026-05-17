#!/bin/bash
set -u
# Hook type: PostToolUse (Bash|Write|Edit)
#
# R16-604 / IMP-006 — scratchpad / extended-thinking artifact monitor.
# Companion to phantom-check.sh: phantom-check scans SUMMARY.md, this
# hook scans any extended-thinking / scratchpad artifact paths the
# platform may expose (e.g., `.apex/scratchpads/`, `.apex/thinking/`,
# `.apex/cot/`, or an env-pointed path `APEX_SCRATCHPAD_PATH`).
#
# Spec anchor (IMP-006): "framework/hooks/phantom-check.sh (או hook
# חדש scratchpad-monitor.sh) חייב לזהות self-named cheating patterns
# בקוד שה-executor כתב ובציטוטי extended-thinking: desperate, getting
# desperate, desperate hack, last resort, \b(grind|fishing|cherry.pick|
# lucky)\b, cover.up, evade detection, to fool, to trick, # hack, XXX
# hack."
#
# Platform dependency note: extended-thinking blocks are not captured
# to a file on every Claude Code installation. When no scratchpad path
# resolves, this hook exits 0 silently — the absence of artifacts is
# not itself a finding. When artifacts ARE present, the cheating
# vocabulary regex applies.
#
# Detection scope: cheating tokens only. Generic uncertainty language
# is phantom-check's domain.
#
# Exit codes:
#   0 — no artifacts found, or artifacts found with no matches.
#   2 — cheating vocabulary detected (blocking).

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

CHEATING_PATTERNS='desperate|getting desperate|desperate hack|last resort|\bgrind\b|\bfishing\b|cherry.?pick|\blucky\b|cover.?up|evade detection|to fool|to trick|# hack|XXX hack'

# Resolve candidate scratchpad paths
CANDIDATES=()
if [ -n "${APEX_SCRATCHPAD_PATH:-}" ] && [ -e "$APEX_SCRATCHPAD_PATH" ]; then
  CANDIDATES+=("$APEX_SCRATCHPAD_PATH")
fi
for dir in .apex/scratchpads .apex/thinking .apex/cot; do
  if [ -d "$dir" ]; then
    CANDIDATES+=("$dir")
  fi
done

# No artifact paths exist — exit 0. Platform may not expose CoT.
if [ ${#CANDIDATES[@]} -eq 0 ]; then
  exit 0
fi

# Collect candidate files (only those modified in the last 24h to keep
# the scan scoped to the active session).
MATCHES_FILE=$(mktemp 2>/dev/null || echo "/tmp/scratchpad-monitor.$$")
trap 'rm -f "$MATCHES_FILE"' EXIT

for c in "${CANDIDATES[@]}"; do
  if [ -d "$c" ]; then
    find "$c" -type f -mtime -1 -print0 2>/dev/null | xargs -0 -r grep -liE "$CHEATING_PATTERNS" 2>/dev/null >> "$MATCHES_FILE" || true
  elif [ -f "$c" ]; then
    if grep -liE "$CHEATING_PATTERNS" "$c" 2>/dev/null >> "$MATCHES_FILE"; then
      :
    fi
  fi
done

if [ -s "$MATCHES_FILE" ]; then
  MATCHED_FILES=$(head -3 "$MATCHES_FILE" | tr '\n' ', ')
  SAMPLE_TOKENS=$(head -3 "$MATCHES_FILE" | xargs -I{} grep -hoiE "$CHEATING_PATTERNS" {} 2>/dev/null | sort -u | head -5 | tr '\n' ', ')
  echo "❌ SCRATCHPAD-MONITOR: Mythos cheating vocabulary detected in extended-thinking artifacts." >&2
  echo "   Files: $MATCHED_FILES" >&2
  echo "   Tokens: $SAMPLE_TOKENS" >&2
  echo "" >&2
  echo "Self-incriminating language in the scratchpad indicates the executor was aware" >&2
  echo "of cutting corners. Blocking phase advancement until reviewed." >&2
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "scratchpad-monitor" \
      "Scratchpad self-incrimination: cheating vocabulary detected in extended-thinking artifacts." \
      "Files: $MATCHED_FILES — tokens: $SAMPLE_TOKENS" \
      "/apex:forensics -- inspect the flagged scratchpad files for the cover-up trail" \
      "/apex:rollback -- revert the executor's work on this task" \
      "/apex:recover -- re-run with a clean executor session and no shortcut path" \
      2>/dev/null || true
  fi
  exit 2
fi

exit 0
