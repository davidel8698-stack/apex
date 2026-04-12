#!/bin/bash
set -u
# Schema-drift hook — validates .apex/ JSON state files after every write.
# Checks that required top-level fields exist using jq.
# Exit 0: valid or non-target file. Exit 2: required fields missing.
#
# Registered as PostToolUse for Write|Edit.

FILE="${1:-}"

# Only validate known .apex/ JSON state files
case "$FILE" in
  */.apex/STATE.json)
    REQUIRED_KEYS='["project","complexity_level","complexity_name","pipeline","apex_version","current_stage","pre_build_complete","current_phase","current_unit","current_wave","status","reflexion","context","circuit_breaker","snapshots","tokens","health_check","evoscore","comprehension_gates","tdad","phase_tags","stack_skills","autonomy"]'
    ;;
  *RESULT.json)
    # Only *-RESULT.json inside .apex/phases/
    case "$FILE" in
      */.apex/phases/*-RESULT.json|*/.apex/phases/*/*-RESULT.json)
        REQUIRED_KEYS='["task_id","status","files_modified","files_read","tests_run","verify_commands_run","done_criteria_checked","edge_cases_handled","decisions_made","confidence","attempt_number","issues_found","unresolved_risks"]'
        ;;
      *)
        exit 0
        ;;
    esac
    ;;
  */.apex/phases/*/PLAN_META.json)
    REQUIRED_KEYS='["phase_id","phase_name","tasks"]'
    ;;
  *)
    # Not a target file — pass through
    exit 0
    ;;
esac

# Require jq
if ! command -v jq &>/dev/null; then
  echo "⚠️ SCHEMA-DRIFT: jq not available, skipping validation" >&2
  exit 0
fi

# Validate JSON parse
if ! jq empty "$FILE" 2>/dev/null; then
  echo "🚫 SCHEMA-DRIFT: $FILE is not valid JSON" >&2
  exit 2
fi

# Check required keys exist
MISSING=""
for KEY in $(echo "$REQUIRED_KEYS" | jq -r '.[]'); do
  if ! jq -e "has(\"$KEY\")" "$FILE" >/dev/null 2>&1; then
    MISSING="$MISSING $KEY"
  fi
done

if [ -n "$MISSING" ]; then
  echo "🚫 SCHEMA-DRIFT: $FILE missing required fields:$MISSING" >&2
  exit 2
fi

exit 0
