#!/bin/bash
set -u
# Schema-drift hook — validates .apex/ JSON state files after every write.
# Checks that required top-level fields exist using jq.
# Exit 0: valid or non-target file. Exit 2: required fields missing.
#
# Registered as PostToolUse for Write|Edit.
#
# R5-014: On block (exit 2), source `_fix-plan-emit.sh` and write
# `.apex/FIX_PLAN.md`. The R5-002 sqlite_mirror shape validation block
# below is preserved untouched. Only the FIX_PLAN.md emission is new.

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

# Phase 8 R-P8-C10: canonical input extraction via shared helper.
# Closes F-010 (stdin-envelope bypass — auditor axis-13.e discovery).
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_hook-input.sh" ]; then
  source "$(dirname "$0")/_hook-input.sh"
fi

FILE=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")

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
  echo "⚠️ STATE FILE CHANGED UNEXPECTEDLY (schema-drift): jq not available, skipping validation" >&2
  exit 0
fi

# Validate JSON parse
if ! jq empty "$FILE" 2>/dev/null; then
  echo "🚫 STATE FILE CHANGED UNEXPECTEDLY (schema-drift): $FILE is not valid JSON" >&2
  # R5-014: structured fix plan
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "schema-drift" \
      "Schema-drift detected: $FILE is not valid JSON." \
      "Last-written file: $FILE" \
      "/apex:forensics -- find the write that produced invalid JSON" \
      "/apex:rollback -- restore the file from the last green tag" \
      "/apex:recover -- reset and re-run the writer with corrected input" \
      2>/dev/null || true
  fi
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
  echo "🚫 STATE FILE CHANGED UNEXPECTEDLY (schema-drift): $FILE missing required fields:$MISSING" >&2
  # R5-014: structured fix plan
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "schema-drift" \
      "Schema-drift detected: $FILE is missing required fields:$MISSING" \
      "Last-written file: $FILE" \
      "/apex:forensics -- find which write dropped the missing fields" \
      "/apex:rollback -- restore the file from the last green tag" \
      "/apex:recover -- reset and re-run the writer to repopulate the schema" \
      2>/dev/null || true
  fi
  exit 2
fi

# R5-002: optional sqlite_mirror field shape validation. Tolerates absence.
case "$FILE" in
  */.apex/STATE.json)
    if jq -e 'has("sqlite_mirror")' "$FILE" >/dev/null 2>&1; then
      if ! jq -e '
        .sqlite_mirror | type == "object"
        and ((has("enabled") | not) or (.enabled | type == "boolean"))
        and ((has("last_synced_at") | not) or (.last_synced_at == null) or (.last_synced_at | type == "string"))
        and ((has("threshold_events") | not) or (.threshold_events | type == "number"))
      ' "$FILE" >/dev/null 2>&1; then
        echo "🚫 STATE FILE CHANGED UNEXPECTEDLY (schema-drift): $FILE sqlite_mirror has invalid shape (expected {enabled?: bool, last_synced_at?: string|null, threshold_events?: int})" >&2
        # R5-014: structured fix plan (preserves R5-002 sqlite_mirror validation)
        if command -v emit_fix_plan >/dev/null 2>&1; then
          emit_fix_plan \
            "schema-drift" \
            "Schema-drift: sqlite_mirror field has an invalid shape." \
            "Last-written file: $FILE — expected {enabled?: bool, last_synced_at?: string|null, threshold_events?: int}" \
            "/apex:forensics -- find the writer that produced the malformed sqlite_mirror" \
            "/apex:rollback -- restore the file from the last green tag" \
            "/apex:recover -- reset and re-run with sqlite_mirror disabled (APEX_SQLITE_MIRROR=)" \
            2>/dev/null || true
        fi
        exit 2
      fi
    fi
    ;;
esac

exit 0
