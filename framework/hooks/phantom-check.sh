#!/bin/bash
set -u
# Blocks advancement if SUMMARY.md uses uncertainty language
# Usage: bash phantom-check.sh [path-to-summary.md]

SUMMARY_FILE="${1:-$(find .apex/phases -name "*SUMMARY.md" -newer .apex/STATE.json | tail -1)}"

if [ -z "$SUMMARY_FILE" ] || [ ! -f "$SUMMARY_FILE" ]; then
  echo "⚠️ PHANTOM CHECK: No summary file found" >&2
  exit 1
fi

RED_FLAGS="should pass|seems to|likely works|I believe|appears correct|looks good\
|I think|I'm confident|probably works|might work|should work|seems correct\
|appears to work|it looks like|I assume|I expect"

if grep -qi "$RED_FLAGS" "$SUMMARY_FILE" 2>/dev/null; then
  MATCHED=$(grep -oi "$RED_FLAGS" "$SUMMARY_FILE" | head -3 | tr '\n' ', ')
  echo "❌ PHANTOM VERIFICATION DETECTED in $SUMMARY_FILE"
  echo "Found uncertainty language: $MATCHED"
  echo ""
  echo "SUMMARY.md must contain ACTUAL command outputs, not beliefs about results."
  echo "Replace uncertainty phrases with:"
  echo "  'Tests pass. Output: [paste actual npm test output]'"
  echo "  'Verified. Command: [cmd]. Output: [actual output]'"
  # R5-019: Living Evidence Counter — append a phantom-fail entry to
  # apex-learnings.md. Best-effort: failure here must not mask the
  # exit-2 phantom verdict.
  if [ -f "$(dirname "$0")/_learnings-emit.sh" ]; then
    # shellcheck source=/dev/null
    source "$(dirname "$0")/_learnings-emit.sh"
    PHASE_GUESS=$(echo "$SUMMARY_FILE" | sed -nE 's|.*phases/([^/]+)/.*|\1|p')
    [ -z "$PHASE_GUESS" ] && PHASE_GUESS="global"
    emit_learning "phantom-fail" "$PHASE_GUESS" "Phantom language in $(basename "$SUMMARY_FILE"): $MATCHED" 2>/dev/null || true
  fi
  exit 2
fi

echo "✅ PHANTOM CHECK: Summary uses concrete evidence language"
exit 0