#!/usr/bin/env bash
# APEX State File Validator — validates JSON state files against their schemas.
# Uses jq for JSON Schema subset validation: required fields, type checks, enums.
# Does NOT support: $ref resolution, allOf/anyOf/oneOf, complex regex, format.
#
# Usage:
#   bash validate-state.sh <schema.json> <state-file.json>
#   bash validate-state.sh --soft <schema.json> <state-file.json>
#
# Exit codes:
#   0 — valid (or --soft mode with warnings only)
#   1 — usage error / file not found
#   2 — validation failure (strict mode)

set -uo pipefail

# --- Parse arguments ---
SOFT_MODE=false
if [ "${1:-}" = "--soft" ]; then
  SOFT_MODE=true
  shift
fi

SCHEMA="${1:-}"
STATE_FILE="${2:-}"

if [ -z "$SCHEMA" ] || [ -z "$STATE_FILE" ]; then
  echo "Usage: validate-state.sh [--soft] <schema.json> <state-file.json>" >&2
  exit 1
fi

if [ ! -f "$SCHEMA" ]; then
  echo "🚫 VALIDATE: Schema not found: $SCHEMA" >&2
  exit 1
fi

if [ ! -f "$STATE_FILE" ]; then
  echo "🚫 VALIDATE: State file not found: $STATE_FILE" >&2
  exit 1
fi

# --- Verify jq is available ---
if ! command -v jq &>/dev/null; then
  echo "🚫 VALIDATE: jq not found in PATH" >&2
  exit 1
fi

# --- Verify both files are valid JSON ---
if ! jq empty "$SCHEMA" 2>/dev/null; then
  echo "🚫 VALIDATE: Schema is not valid JSON: $SCHEMA" >&2
  exit 1
fi

if ! jq empty "$STATE_FILE" 2>/dev/null; then
  echo "🚫 VALIDATE: State file is not valid JSON: $STATE_FILE" >&2
  exit 2
fi

ERRORS=0
WARNINGS=0

report() {
  local level="$1"
  local msg="$2"
  if [ "$level" = "ERROR" ]; then
    echo "  ❌ $msg" >&2
    ERRORS=$((ERRORS + 1))
  else
    echo "  ⚠️  $msg" >&2
    WARNINGS=$((WARNINGS + 1))
  fi
}

# --- Check root type ---
EXPECTED_TYPE=$(jq -r '.type // "object"' "$SCHEMA" | tr -d '\r')
ACTUAL_TYPE=$(jq -r 'type' "$STATE_FILE" | tr -d '\r')
if [ "$EXPECTED_TYPE" != "$ACTUAL_TYPE" ]; then
  report ERROR "Root type mismatch: expected '$EXPECTED_TYPE', got '$ACTUAL_TYPE'"
fi

# --- Check required fields at root level ---
# Use mapfile to avoid stdin conflicts with jq inside loops
mapfile -t REQUIRED_FIELDS < <(jq -r '.required[]? // empty' "$SCHEMA" 2>/dev/null | tr -d '\r')
for field in "${REQUIRED_FIELDS[@]}"; do
  [ -z "$field" ] && continue
  if ! jq -e --arg f "$field" 'has($f)' "$STATE_FILE" >/dev/null 2>&1; then
    report ERROR "Missing required field: '$field'"
  fi
done

# --- Check additionalProperties at root level ---
ADDITIONAL=$(jq -r '.additionalProperties // "not_set"' "$SCHEMA" | tr -d '\r')
if [ "$ADDITIONAL" = "false" ]; then
  SCHEMA_KEYS=$(jq -r '.properties | keys[]' "$SCHEMA" 2>/dev/null | tr -d '\r' | sort)
  STATE_KEYS=$(jq -r 'keys[]' "$STATE_FILE" 2>/dev/null | tr -d '\r' | sort)
  EXTRA_KEYS=$(comm -23 <(echo "$STATE_KEYS") <(echo "$SCHEMA_KEYS"))
  if [ -n "$EXTRA_KEYS" ]; then
    while IFS= read -r key; do
      [ -z "$key" ] && continue
      report ERROR "Unexpected field (additionalProperties: false): '$key'"
    done <<< "$EXTRA_KEYS"
  fi
fi

# --- Type-check each property defined in schema ---
# Build type checks as a single jq call to avoid stdin issues
mapfile -t PROP_ENTRIES < <(jq -r '.properties | to_entries[] | "\(.key)\t\(.value.type // "any")"' "$SCHEMA" 2>/dev/null | tr -d '\r')
for entry in "${PROP_ENTRIES[@]}"; do
  [ -z "$entry" ] && continue
  key=$(echo "$entry" | cut -f1)
  expected_type=$(echo "$entry" | cut -f2)

  # Skip if field doesn't exist
  if ! jq -e --arg f "$key" 'has($f)' "$STATE_FILE" >/dev/null 2>&1; then
    continue
  fi

  actual_type=$(jq -r --arg f "$key" '.[$f] | type' "$STATE_FILE" 2>/dev/null | tr -d '\r')

  # Handle nullable types: ["string", "null"]
  if echo "$expected_type" | jq -e 'type == "array"' >/dev/null 2>&1; then
    mapfile -t allowed < <(echo "$expected_type" | jq -r '.[]' | tr -d '\r')
    match=false
    for t in "${allowed[@]}"; do
      if [ "$t" = "$actual_type" ]; then
        match=true
        break
      fi
      # jq reports integers as "number" — treat integer schema type as matching number
      if [ "$t" = "integer" ] && [ "$actual_type" = "number" ]; then
        is_int=$(jq --arg f "$key" '.[$f] | . == (. | floor)' "$STATE_FILE" 2>/dev/null | tr -d '\r')
        if [ "$is_int" = "true" ]; then
          match=true
          break
        fi
      fi
    done
    if [ "$match" = "false" ]; then
      report ERROR "Type mismatch for '$key': expected one of $expected_type, got '$actual_type'"
    fi
  elif [ "$expected_type" != "any" ] && [ "$expected_type" != "$actual_type" ]; then
    # Handle integer vs number: jq reports integers as "number"
    if [ "$expected_type" = "integer" ] && [ "$actual_type" = "number" ]; then
      is_int=$(jq --arg f "$key" '.[$f] | . == (. | floor)' "$STATE_FILE" 2>/dev/null | tr -d '\r')
      if [ "$is_int" != "true" ]; then
        report ERROR "Type mismatch for '$key': expected integer, got float"
      fi
      # integer that is whole number — OK, skip
    else
      report ERROR "Type mismatch for '$key': expected '$expected_type', got '$actual_type'"
    fi
  fi

  # Check enum constraints
  has_enum=$(jq -r --arg f "$key" '.properties[$f] | has("enum")' "$SCHEMA" 2>/dev/null | tr -d '\r')
  if [ "$has_enum" = "true" ]; then
    actual_value=$(jq -r --arg f "$key" '.[$f]' "$STATE_FILE" 2>/dev/null | tr -d '\r')
    if ! jq -e --arg f "$key" --arg v "$actual_value" '.properties[$f].enum | index($v) != null' "$SCHEMA" >/dev/null 2>&1; then
      report ERROR "Enum violation for '$key': '$actual_value' not in allowed values"
    fi
  fi
done

# --- Check nested required fields (one level deep) ---
mapfile -t NESTED_ENTRIES < <(jq -r '.properties | to_entries[] | select(.value.type == "object" and .value.required != null) | "\(.key)\t\(.value.required | join(","))"' "$SCHEMA" 2>/dev/null | tr -d '\r')
for entry in "${NESTED_ENTRIES[@]}"; do
  [ -z "$entry" ] && continue
  parent=$(echo "$entry" | cut -f1)
  required_csv=$(echo "$entry" | cut -f2)

  if ! jq -e --arg f "$parent" 'has($f) and (.[$f] | type == "object")' "$STATE_FILE" >/dev/null 2>&1; then
    continue
  fi
  IFS=',' read -ra fields <<< "$required_csv"
  for field in "${fields[@]}"; do
    if ! jq -e --arg p "$parent" --arg f "$field" '.[$p] | has($f)' "$STATE_FILE" >/dev/null 2>&1; then
      report ERROR "Missing required field: '$parent.$field'"
    fi
  done
done

# --- Check apex_version / version match ---
SCHEMA_VERSION=$(jq -r '.properties.apex_version.enum[0] // .properties.version.const // empty' "$SCHEMA" 2>/dev/null | tr -d '\r')
if [ -n "$SCHEMA_VERSION" ]; then
  STATE_VERSION=$(jq -r '.apex_version // .version // empty' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  if [ -n "$STATE_VERSION" ] && [ "$SCHEMA_VERSION" != "$STATE_VERSION" ]; then
    report ERROR "Version mismatch: schema expects '$SCHEMA_VERSION', state has '$STATE_VERSION'"
  fi
fi

# --- Summary ---
echo "" >&2
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ VALIDATE: $(basename "$STATE_FILE") passed against $(basename "$SCHEMA")" >&2
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "✅ VALIDATE: $(basename "$STATE_FILE") passed with $WARNINGS warning(s)" >&2
  exit 0
else
  if [ "$SOFT_MODE" = "true" ]; then
    echo "⚠️  VALIDATE (soft): $(basename "$STATE_FILE") has $ERRORS error(s), $WARNINGS warning(s) — continuing" >&2
    exit 0
  else
    echo "🚫 VALIDATE: $(basename "$STATE_FILE") FAILED with $ERRORS error(s), $WARNINGS warning(s)" >&2
    exit 2
  fi
fi
