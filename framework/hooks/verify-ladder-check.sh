#!/bin/bash
# Verification ladder enforcement — validates verify_level assignments after architect.
# R4: No single verification layer sufficient; honor-system enforcement is loose.
# Called after architect generates PLAN_META.json.
source "$(dirname "$0")/_require-jq.sh"
require_jq

PLAN_META=".apex/phases/$1/PLAN_META.json"

if [ ! -f "$PLAN_META" ]; then
  exit 0
fi

WARNINGS=0

# Check: has_behavior=true + verify_level=A → should be at least B
BEHAVIOR_A=$(jq -r '[.tasks[] | select(.has_behavior == true and .verify_level == "A")] | length' "$PLAN_META" 2>/dev/null)
if [ "$BEHAVIOR_A" -gt 0 ]; then
  echo "⚠️ LADDER: $BEHAVIOR_A task(s) with has_behavior=true assigned verify_level A (should be ≥B)"
  # Auto-correct
  jq '(.tasks[] | select(.has_behavior == true and .verify_level == "A")).verify_level = "B"' \
    "$PLAN_META" > /tmp/plan_meta_fix.json && mv /tmp/plan_meta_fix.json "$PLAN_META"
  echo "   Auto-corrected to verify_level B"
  WARNINGS=$((WARNINGS + BEHAVIOR_A))
fi

# Check: specialist=security|integration + verify_level < C → should be at least C
SEC_LOW=$(jq -r '[.tasks[] | select((.specialist == "security" or .specialist == "integration") and (.verify_level == "A" or .verify_level == "B"))] | length' "$PLAN_META" 2>/dev/null)
if [ "$SEC_LOW" -gt 0 ]; then
  echo "⚠️ LADDER: $SEC_LOW security/integration task(s) below verify_level C"
  jq '(.tasks[] | select((.specialist == "security" or .specialist == "integration") and (.verify_level == "A" or .verify_level == "B"))).verify_level = "C"' \
    "$PLAN_META" > /tmp/plan_meta_fix.json && mv /tmp/plan_meta_fix.json "$PLAN_META"
  echo "   Auto-corrected to verify_level C"
  WARNINGS=$((WARNINGS + SEC_LOW))
fi

if [ "$WARNINGS" -eq 0 ]; then
  echo "✅ Verification ladder: all assignments valid"
fi

exit 0