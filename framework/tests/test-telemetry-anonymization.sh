#!/usr/bin/env bash
# Phase 12.09 — M16.1 Telemetry Anonymization test.
#
# Verifies framework/hooks/_telemetry-emit.sh enforces anonymization:
#   C-1: hook exists + syntax-valid.
#   C-2: Project basename does NOT appear as literal text in emitted line.
#   C-3: project_hash IS present in emitted line AND is exactly 8 hex chars.
#   C-4: project_hash deterministically equals sha256(basename $PWD)[0:8].
#   C-5: No file paths in counters (grep '/' on the counters object → 0).
#
# Harness contract (R10-008): arithmetic globals, no EXIT trap.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TELEM_SH="$REPO_ROOT/framework/hooks/_telemetry-emit.sh"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.09 — M16.1 Telemetry Anonymization ==="

# Pick a sha256 tool for the deterministic-reproduction test in C-4.
_compute_sha8() {
  local input="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$input" | sha256sum | awk '{print substr($1, 1, 8)}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$input" | shasum -a 256 | awk '{print substr($1, 1, 8)}'
  elif command -v openssl >/dev/null 2>&1; then
    printf '%s' "$input" | openssl dgst -sha256 | awk '{print substr($NF, 1, 8)}'
  else
    printf '00000000'
  fi
}

# --- C-1: hook exists + syntax-valid ---
TOTAL=$((TOTAL + 1))
if [ -f "$TELEM_SH" ] && bash -n "$TELEM_SH" 2>/dev/null; then
  echo "  ✅ C-1: _telemetry-emit.sh exists, syntax-valid"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: _telemetry-emit.sh missing or syntax error"
  exit 1
fi

# Helper: sandbox with a non-trivial, easily-greppable basename.
_make_anon_sandbox() {
  local parent
  parent=$(mktemp -d)
  # Use a non-trivial basename — easily greppable, unlikely to false-positive.
  local sb="$parent/UltraSecretCustomerName_DoNotLeak_12345"
  mkdir -p "$sb/.apex"
  mkdir -p "$sb/fake_home/.claude"
  echo "$sb"
}

# --- C-2: project basename does NOT appear in emitted line. ---
TOTAL=$((TOTAL + 1))
SB=$(_make_anon_sandbox)
BASENAME=$(basename "$SB")
(cd "$SB" && HOME="$SB/fake_home" unset APEX_TELEMETRY; bash "$TELEM_SH" "task_complete" "phase_a" '{"score":0.9}' >/dev/null 2>&1)
MATCH_COUNT=0
if [ -f "$SB/.apex/telemetry.jsonl" ]; then
  # grep -F: literal match, case-sensitive (basename is randomized + literal).
  # Use grep | wc -l (not grep -c) so non-match exit-1 does not append a stray "0".
  MATCH_COUNT=$(grep -F "$BASENAME" "$SB/.apex/telemetry.jsonl" 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$MATCH_COUNT" = "0" ]; then
  echo "  ✅ C-2: basename '$BASENAME' has 0 matches in telemetry.jsonl"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: basename '$BASENAME' LEAKED — $MATCH_COUNT match(es)"
  [ -f "$SB/.apex/telemetry.jsonl" ] && cat "$SB/.apex/telemetry.jsonl" | sed 's/^/      /'
  FAIL=$((FAIL + 1))
fi
# Sandbox kept for C-3, C-4.

# --- C-3: project_hash IS present and is exactly 8 hex chars. ---
TOTAL=$((TOTAL + 1))
HASH_OK="no"
if [ -f "$SB/.apex/telemetry.jsonl" ] && command -v jq >/dev/null 2>&1; then
  HASH=$(jq -r '.project_hash // ""' "$SB/.apex/telemetry.jsonl" 2>/dev/null | head -1)
  if printf '%s' "$HASH" | grep -qE '^[0-9a-f]{8}$' 2>/dev/null; then
    HASH_OK="yes"
  fi
fi
if [ "$HASH_OK" = "yes" ]; then
  echo "  ✅ C-3: project_hash present and is exactly 8 hex chars ($HASH)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: project_hash missing or wrong shape (got '$HASH')"
  FAIL=$((FAIL + 1))
fi

# --- C-4: project_hash deterministically reproduces sha256(basename $PWD)[0:8]. ---
TOTAL=$((TOTAL + 1))
EXPECTED_HASH=$(_compute_sha8 "$BASENAME")
if [ "$HASH" = "$EXPECTED_HASH" ]; then
  echo "  ✅ C-4: project_hash matches sha256(basename)[0:8] (both = $HASH)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: project_hash mismatch — emitted=$HASH, expected=$EXPECTED_HASH"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# --- C-5: No file paths in counters — grep '/' inside counters object returns 0. ---
TOTAL=$((TOTAL + 1))
SB=$(_make_anon_sandbox)
# Emit a line with a deliberately-clean numeric-only counters payload (the
# contract is "numeric only"; the test guards against a future caller bug
# where a path slips into counters).
(cd "$SB" && HOME="$SB/fake_home" unset APEX_TELEMETRY; bash "$TELEM_SH" "task_complete" "phase_a" '{"score":0.9,"attempts":1}' >/dev/null 2>&1)
SLASH_COUNT=0
if [ -f "$SB/.apex/telemetry.jsonl" ] && command -v jq >/dev/null 2>&1; then
  # Extract just the counters object as text and count '/' occurrences.
  COUNTERS_TEXT=$(jq -c '.counters' "$SB/.apex/telemetry.jsonl" 2>/dev/null)
  # Use grep | wc -l (not grep -c) so non-match exit-1 does not pollute the count.
  SLASH_COUNT=$(printf '%s' "$COUNTERS_TEXT" | grep -F '/' 2>/dev/null | wc -l | tr -d ' ')
fi
if [ "$SLASH_COUNT" = "0" ]; then
  echo "  ✅ C-5: no '/' chars inside counters object (path-leak guard)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: '/' found inside counters object — possible path leak ($SLASH_COUNT match(es))"
  [ -f "$SB/.apex/telemetry.jsonl" ] && cat "$SB/.apex/telemetry.jsonl" | sed 's/^/      /'
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
