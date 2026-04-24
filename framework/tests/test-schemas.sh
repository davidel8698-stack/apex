# R4-004: self-source harness if run standalone
if [ -z "${COMMANDS_DIR:-}" ]; then
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$TEST_DIR/_harness.sh"
  harness_setup
  STANDALONE=1
fi

echo "  Schemas: structure validation"

# STATE.schema.json checks
assert_jq "$SCHEMAS_DIR/STATE.schema.json" '.properties.apex_version.enum[0] == "v7"' "D-2: apex_version is v7"
assert_jq "$SCHEMAS_DIR/STATE.schema.json" '.properties.autonomy.properties.by_verify_level.properties | keys | sort == ["A","B","C","D"]' "D-3: autonomy has by_verify_level A/B/C/D"
assert_jq "$SCHEMAS_DIR/STATE.schema.json" '.properties.autopilot != null' "D-4a: schema has autopilot"
assert_jq "$SCHEMAS_DIR/STATE.schema.json" '.properties.session != null' "D-4b: schema has session"
assert_jq "$SCHEMAS_DIR/STATE.schema.json" '.properties.circuit_breaker.properties.total_tool_calls_this_task != null' "D-4c: circuit_breaker has total_tool_calls_this_task"

# RESULT.schema.json checks
assert_jq "$SCHEMAS_DIR/RESULT.schema.json" '.properties.confidence != null' "D-5a: RESULT schema has confidence"
assert_jq "$SCHEMAS_DIR/RESULT.schema.json" '.properties.attempt_number != null' "D-5b: RESULT schema has attempt_number"

# PLAN_META.schema.json — verify it exists and is valid JSON
assert_jq "$SCHEMAS_DIR/PLAN_META.schema.json" '.type == "object"' "PLAN_META.schema.json is valid"

# CONTEXT_BUDGET.schema.json — verify it exists and is valid JSON
assert_jq "$SCHEMAS_DIR/CONTEXT_BUDGET.schema.json" '.type == "object"' "CONTEXT_BUDGET.schema.json is valid"

# R4-004: standalone-mode cleanup (only fires when this test file was invoked directly)
if [ "${STANDALONE:-0}" = "1" ]; then
  harness_teardown
  harness_report
fi
