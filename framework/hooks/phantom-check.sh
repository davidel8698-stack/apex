#!/bin/bash
# Blocks advancement if SUMMARY.md uses uncertainty language
# Usage: bash phantom-check.sh [path-to-summary.md]

SUMMARY_FILE="${1:-$(find .apex/phases -name "*SUMMARY.md" -newer .apex/STATE.json | tail -1)}"

if [ -z "$SUMMARY_FILE" ] || [ ! -f "$SUMMARY_FILE" ]; then
  echo "✅ PHANTOM CHECK: No summary file to check"
  exit 0
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
  exit 2
fi

echo "✅ PHANTOM CHECK: Summary uses concrete evidence language"
exit 0