#!/bin/bash
# Runs all tests from previous phases to detect regressions before advancing
# Usage: bash cross-phase-audit.sh [current_phase_number]
# [שיפור 21] Now reads verify_commands from PLAN_META.json instead of regex
source "$(dirname "$0")/_require-jq.sh"
require_jq

CURRENT_PHASE=${1:-1}
echo "🔍 APEX Cross-Phase Regression Audit (checking Phases 1 to $((CURRENT_PHASE-1)))..."

if [ "$CURRENT_PHASE" -le 1 ]; then
  echo "✅ No previous phases to audit (Phase 1)"
  exit 0
fi

FAILURES=0
TOTAL_TESTS=0
TESTED_PHASES=0

for phase_dir in .apex/phases/*/; do
  PHASE_NUM=$(basename "$phase_dir" | cut -d- -f1 | sed 's/^0*//')

  if [ "$PHASE_NUM" -lt "$CURRENT_PHASE" ] 2>/dev/null; then
    META_FILE="${phase_dir}PLAN_META.json"

    if [ -f "$META_FILE" ]; then
      # [שיפור 21] Read verify_commands from structured JSON
      VERIFY_CMDS=$(jq -r '.tasks[].verify_commands[]' "$META_FILE" 2>/dev/null | \
        grep -E "^(npm|npx|node|curl)" | sort -u | head -10)
    else
      # Fallback for projects without PLAN_META.json (legacy layout)
      VERIFY_CMDS=$(grep -h "<verify>" "${phase_dir}"*.md 2>/dev/null | \
        grep -v "^<verify>" | sed 's|.*<verify>||;s|</verify>.*||' | \
        grep -E "^(npm|npx|node|curl)" | sort -u | head -10)
    fi

    if [ -n "$VERIFY_CMDS" ]; then
      echo "  Checking Phase $PHASE_NUM..."
      PHASE_FAIL=0

      while IFS= read -r cmd; do
        [ -z "$cmd" ] && continue
        # Security: validate command prefix against allowlist
        CMD_PREFIX=$(echo "$cmd" | awk '{print $1}')
        case "$CMD_PREFIX" in
          npm|npx|node|python|python3|pytest|vitest|jest|curl|grep|bash) ;;
          *) echo "  ⚠️ SKIPPED (not in allowlist): $cmd"; continue ;;
        esac
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        OUTPUT=$(bash -c "$cmd" 2>&1)
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
          echo "  ❌ REGRESSION in Phase $PHASE_NUM: $cmd"
          echo "     Output: $(echo "$OUTPUT" | head -3)"
          FAILURES=$((FAILURES + 1))
          PHASE_FAIL=1
        fi
      done <<< "$VERIFY_CMDS"

      [ $PHASE_FAIL -eq 0 ] && echo "  ✅ Phase $PHASE_NUM: no regressions"
      TESTED_PHASES=$((TESTED_PHASES + 1))
    fi
  fi
done

# Update EvoScore in STATE.json
if [ -f .apex/STATE.json ]; then
  REGRESSION_RATE=0
  [ "$TOTAL_TESTS" -gt 0 ] && REGRESSION_RATE=$(echo "scale=2; $FAILURES * 100 / $TOTAL_TESTS" | bc 2>/dev/null || echo "0")

  jq --argjson rate "$REGRESSION_RATE" \
     --argjson total "$TOTAL_TESTS" \
     --arg date "$(date -I)" \
     '.evoscore.regression_rate = $rate |
      .evoscore.total_cross_phase_tests = $total |
      .evoscore.last_full_audit = $date' \
     .apex/STATE.json > /tmp/state_tmp.json && mv /tmp/state_tmp.json .apex/STATE.json
fi

echo ""
echo "Cross-Phase Audit Complete:"
echo "  Phases checked: $TESTED_PHASES"
echo "  Tests run: $TOTAL_TESTS"
echo "  Failures: $FAILURES"
echo "  EvoScore regression rate: ${REGRESSION_RATE:-0}%"

if [ "$FAILURES" -gt 0 ]; then
  echo ""
  echo "⛔ BLOCKED: $FAILURES regression(s) detected in previous phases."
  echo "Fix before advancing. Current changes broke earlier functionality."
  exit 2
fi

echo "✅ Zero regressions — codebase health maintained"
exit 0