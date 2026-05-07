#!/usr/bin/env bash
# R5-004: state-rebuild.sh reconstructs .apex/STATE.json from event-log.jsonl
# Test asserts:
#   1. Hook exits 0 when STATE.json already exists (no-op).
#   2. Hook produces STATE.json from a fixture event log when STATE.json
#      is missing.
#   3. STATE.json contains at least `current_phase` derived from the JSONL.
#      (R7-005: decision_mode is no longer overlaid on STATE.json — it is
#       read from PLAN_META.json on a per-task basis. The semantic event
#       continues to be emitted to event-log.jsonl by _state-update.sh.)
#   4. Idempotency: running rebuild twice yields byte-identical STATE.json.
#   5. Unknown event types are tolerated (no error).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/state-rebuild.sh"

# R7-009: shared IO helpers (jq_lines for CRLF-safe read loops).
# shellcheck source=_test-utils.sh
[ -f "$SCRIPT_DIR/_test-utils.sh" ] && source "$SCRIPT_DIR/_test-utils.sh"

if [ ! -f "$HOOK" ]; then
  echo "FAIL: state-rebuild.sh not found at $HOOK" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — state-rebuild requires jq"
  exit 0
fi

PASS=0
FAIL=0

assert_pass() {
  local label="$1" cond="$2"
  if eval "$cond" >/dev/null 2>&1; then
    echo "  PASS: $label"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $label"
    FAIL=$((FAIL+1))
  fi
}

run_sandbox() {
  local sandbox; sandbox="$(mktemp -d)"
  ( cd "$sandbox" && git init -q && git config user.email t@a && git config user.name t && \
    echo init > init.txt && git add . && git commit -qm init )
  echo "$sandbox"
}

write_fixture_event_log() {
  local f="$1"
  cat > "$f" <<'EOF'
{"ts":"2026-05-01T10:00:00Z","type":"session_event","event":"start","msg":"session started"}
{"ts":"2026-05-01T10:05:00Z","type":"phase_set","event":"phase_set","current_phase":"01"}
{"ts":"2026-05-01T10:10:00Z","type":"decision_mode_set","event":"decision_mode_set","decision_mode":"balanced"}
{"ts":"2026-05-01T10:15:00Z","type":"complexity_set","event":"complexity_set","complexity_level":3,"complexity_name":"Large"}
{"ts":"2026-05-01T10:20:00Z","type":"phase_set","event":"phase_set","current_phase":"02"}
{"ts":"2026-05-01T10:25:00Z","type":"unknown_event_type","event":"future_event","arbitrary":"payload"}
{"ts":"2026-05-01T10:30:00Z","type":"session_event","event":"checkpoint","msg":"phase 02 advanced"}
EOF
}

echo "=== R5-004: state-rebuild.sh ==="

# --- Case A: STATE.json present → rebuild is a no-op ---
SBA="$(run_sandbox)"
mkdir -p "$SBA/.apex"
echo '{"current_phase":"existing","decision_mode":"existing"}' > "$SBA/.apex/STATE.json"
ORIG_HASH=$(cat "$SBA/.apex/STATE.json" | shasum -a 256 2>/dev/null | cut -d' ' -f1 || md5sum "$SBA/.apex/STATE.json" | cut -d' ' -f1)
( cd "$SBA" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_A=$?
NEW_HASH=$(cat "$SBA/.apex/STATE.json" | shasum -a 256 2>/dev/null | cut -d' ' -f1 || md5sum "$SBA/.apex/STATE.json" | cut -d' ' -f1)
assert_pass "no-op when STATE.json exists exits 0"      "[ $EXIT_A -eq 0 ]"
assert_pass "no-op preserves existing STATE.json bytes" "[ '$ORIG_HASH' = '$NEW_HASH' ]"
rm -rf "$SBA"

# --- Case B: STATE.json missing, event-log.jsonl present → rebuild ---
SBB="$(run_sandbox)"
mkdir -p "$SBB/.apex"
write_fixture_event_log "$SBB/.apex/event-log.jsonl"
( cd "$SBB" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_B=$?
assert_pass "rebuild exits 0 when reconstruction runs"  "[ $EXIT_B -eq 0 ]"
assert_pass "STATE.json was created"                    "[ -f '$SBB/.apex/STATE.json' ]"
assert_pass "STATE.json is valid JSON"                  "jq . '$SBB/.apex/STATE.json' >/dev/null"
assert_pass "current_phase derived from JSONL"          "[ \"\$(jq -r '.current_phase' '$SBB/.apex/STATE.json')\" = '02' ]"
# R7-005: decision_mode is no longer overlaid on STATE.json.
assert_pass "decision_mode not in rebuilt STATE.json"   "! jq -e 'has(\"decision_mode\")' '$SBB/.apex/STATE.json' >/dev/null 2>&1"
assert_pass "rebuilt_from_event_log marker present"     "[ \"\$(jq -r '.rebuilt_from_event_log' '$SBB/.apex/STATE.json')\" = 'true' ]"

# Idempotency
HASH1=$(shasum -a 256 "$SBB/.apex/STATE.json" 2>/dev/null | cut -d' ' -f1 || md5sum "$SBB/.apex/STATE.json" | cut -d' ' -f1)
rm -f "$SBB/.apex/STATE.json"
( cd "$SBB" && bash "$HOOK" >/dev/null 2>&1 )
HASH2=$(shasum -a 256 "$SBB/.apex/STATE.json" 2>/dev/null | cut -d' ' -f1 || md5sum "$SBB/.apex/STATE.json" | cut -d' ' -f1)
assert_pass "idempotency: rebuild twice yields same bytes" "[ '$HASH1' = '$HASH2' ]"
rm -rf "$SBB"

# --- Case C: STATE.json missing, no event log → rebuild emits stub safely ---
SBC="$(run_sandbox)"
mkdir -p "$SBC/.apex"
( cd "$SBC" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_C=$?
assert_pass "no event log: hook still exits 0 (fail-soft)" "[ $EXIT_C -eq 0 ]"
rm -rf "$SBC"

# --- Case D: outside any git repo → fast pass-through (no crash) ---
SBD="$(mktemp -d)"
( cd "$SBD" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_D=$?
assert_pass "outside git repo: exits 0 cleanly" "[ $EXIT_D -eq 0 ]"
rm -rf "$SBD"

# --- Case E: R6-004 end-to-end dual-emit → real _state_update calls drive rebuild ---
# This case is a tautology-killer: it does NOT write fixture event lines.
# It invokes the real _state_update helper, lets it emit the dual events
# (state_mutation + semantic), then rebuilds STATE.json from that real log
# and asserts the canonical fields reflect the latest semantic events.
SBE="$(run_sandbox)"
mkdir -p "$SBE/.apex"
# Seed a STATE.json so _state_update has something to jq-update; then delete it
# before rebuild.
echo '{"current_phase":"00","decision_mode":"balanced","complexity_level":2,"complexity_name":"Medium"}' > "$SBE/.apex/STATE.json"
(
  cd "$SBE" && \
  source "$REPO_ROOT/framework/hooks/_state-update.sh" && \
  _state_update '.current_phase = "03"' && \
  _state_update '.decision_mode = "fast"' && \
  _state_update '.complexity_level = 4'
) >/dev/null 2>&1
EXIT_E_EMIT=$?
assert_pass "R6-004: _state_update calls all exit 0"           "[ $EXIT_E_EMIT -eq 0 ]"
assert_pass "R6-004: phase_set event emitted"                  "[ \"\$(grep -c '\"type\":\"phase_set\"' '$SBE/.apex/event-log.jsonl')\" -ge 1 ]"
assert_pass "R6-004: decision_mode_set event emitted"          "[ \"\$(grep -c '\"type\":\"decision_mode_set\"' '$SBE/.apex/event-log.jsonl')\" -ge 1 ]"
assert_pass "R6-004: complexity_set event emitted"             "[ \"\$(grep -c '\"type\":\"complexity_set\"' '$SBE/.apex/event-log.jsonl')\" -ge 1 ]"
assert_pass "R6-004: state_mutation events still present"      "[ \"\$(grep -c '\"type\":\"state_mutation\"' '$SBE/.apex/event-log.jsonl')\" -ge 3 ]"
# Now drive the rebuild against the real (non-fixture) log.
rm -f "$SBE/.apex/STATE.json"
( cd "$SBE" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_E=$?
assert_pass "R6-004: rebuild from real event log exits 0"      "[ $EXIT_E -eq 0 ]"
assert_pass "R6-004: rebuilt current_phase reflects last emit" "[ \"\$(jq -r '.current_phase' '$SBE/.apex/STATE.json')\" = '03' ]"
# R7-005: decision_mode is no longer overlaid on STATE.json (orphan field
# removed; consumers read decision_mode from PLAN_META.json). The
# decision_mode_set event is still emitted to event-log.jsonl above.
assert_pass "R7-005: rebuilt STATE has no decision_mode field" "! jq -e 'has(\"decision_mode\")' '$SBE/.apex/STATE.json' >/dev/null 2>&1"
assert_pass "R6-004: rebuilt complexity_level reflects emit"   "[ \"\$(jq -r '.complexity_level' '$SBE/.apex/STATE.json')\" = '4' ]"
rm -rf "$SBE"

# --- Case F: R6-011 schema-complete rebuild from frozen template ---
# Asserts that the rebuilt STATE.json carries every canonical schema-required
# top-level key (50+) — no longer a 7-field stub. Also asserts that the
# template itself (after stripping the `_doc` annotation) and the rebuilt
# STATE (after stripping the forensic markers added by state-rebuild.sh)
# both pass strict-schema validation via framework/scripts/validate-state.sh.
TEMPLATE="$REPO_ROOT/framework/templates/STATE-init.template.json"
SCHEMA="$REPO_ROOT/framework/schemas/STATE.schema.json"
VALIDATOR="$REPO_ROOT/framework/scripts/validate-state.sh"
assert_pass "R6-011: template file exists"                     "[ -f '$TEMPLATE' ]"
assert_pass "R6-011: template is valid JSON"                   "jq . '$TEMPLATE' >/dev/null"
assert_pass "R6-011: template has _doc drift warning"          "jq -e 'has(\"_doc\")' '$TEMPLATE' >/dev/null"
assert_pass "R6-011: template _doc references start.md"        "[ \"\$(jq -r '._doc' '$TEMPLATE' | grep -c 'start.md')\" -ge 1 ]"

# Strict-schema validation on the template (after stripping the annotation).
TPL_TMP="$(mktemp).json"
jq 'del(._doc)' "$TEMPLATE" > "$TPL_TMP"
bash "$VALIDATOR" "$SCHEMA" "$TPL_TMP" >/dev/null 2>&1
assert_pass "R6-011: template strict-validates against STATE.schema.json" "[ $? -eq 0 ]"
rm -f "$TPL_TMP"

# Rebuild flow with no event log: result must still be schema-complete.
SBF="$(run_sandbox)"
mkdir -p "$SBF/.apex"
( cd "$SBF" && bash "$HOOK" >/dev/null 2>&1 )
EXIT_F=$?
assert_pass "R6-011: rebuild from empty log exits 0"           "[ $EXIT_F -eq 0 ]"
assert_pass "R6-011: rebuilt STATE.json was created"           "[ -f '$SBF/.apex/STATE.json' ]"
# Count the canonical top-level keys (after stripping the forensic markers
# added by state-rebuild.sh: rebuilt_from_event_log, rebuild_source).
# R7-005: decision_mode is no longer added to the rebuilt STATE.json so the
# pre-validation strip no longer needs to mask it; schema sync is honest.
# 37 are required; the template populates 37 + 1 optional (mutation_scores)
# = 38 canonical keys.
KEY_COUNT=$(jq 'del(.rebuilt_from_event_log, .rebuild_source) | keys | length' "$SBF/.apex/STATE.json" 2>/dev/null)
assert_pass "R6-011: rebuilt STATE has >= 37 canonical fields" "[ ${KEY_COUNT:-0} -ge 37 ]"
# Strict-schema validation on the rebuilt STATE (after stripping forensic markers).
REB_TMP="$(mktemp).json"
jq 'del(.rebuilt_from_event_log, .rebuild_source)' "$SBF/.apex/STATE.json" > "$REB_TMP"
bash "$VALIDATOR" "$SCHEMA" "$REB_TMP" >/dev/null 2>&1
assert_pass "R6-011: rebuilt STATE strict-validates against schema" "[ $? -eq 0 ]"
rm -f "$REB_TMP"
# Init-block defaults preserved for non-derivable fields.
assert_pass "R6-011: pre_build_complete=false default"         "[ \"\$(jq -r '.pre_build_complete' '$SBF/.apex/STATE.json')\" = 'false' ]"
assert_pass "R6-011: apex_version=v7 default"                  "[ \"\$(jq -r '.apex_version' '$SBF/.apex/STATE.json')\" = 'v7' ]"
assert_pass "R6-011: proposals_mode=true default"              "[ \"\$(jq -r '.proposals_mode' '$SBF/.apex/STATE.json')\" = 'true' ]"
assert_pass "R6-011: autonomy.by_verify_level present"         "jq -e '.autonomy.by_verify_level | has(\"A\") and has(\"B\") and has(\"C\") and has(\"D\")' '$SBF/.apex/STATE.json' >/dev/null"
assert_pass "R6-011: circuit_breaker.max_allowed=3"            "[ \"\$(jq -r '.circuit_breaker.max_allowed' '$SBF/.apex/STATE.json')\" = '3' ]"
assert_pass "R6-011: rebuilt STATE has no _doc field"          "! jq -e 'has(\"_doc\")' '$SBF/.apex/STATE.json' >/dev/null 2>&1"
rm -rf "$SBF"

# --- Case G: R6-011 + R6-004 integration — overlay current_phase from real emit ---
SBG="$(run_sandbox)"
mkdir -p "$SBG/.apex"
echo '{"current_phase":"00","decision_mode":"balanced","complexity_level":2,"complexity_name":"Medium"}' > "$SBG/.apex/STATE.json"
(
  cd "$SBG" && \
  source "$REPO_ROOT/framework/hooks/_state-update.sh" && \
  _state_update '.current_phase = "03"'
) >/dev/null 2>&1
rm -f "$SBG/.apex/STATE.json"
( cd "$SBG" && bash "$HOOK" >/dev/null 2>&1 )
assert_pass "R6-011+R6-004: rebuilt current_phase=='03' (overlay)" "[ \"\$(jq -r '.current_phase' '$SBG/.apex/STATE.json')\" = '03' ]"
# Init-block defaults still present for fields not in the event log.
assert_pass "R6-011+R6-004: rebuilt status=initializing default"   "[ \"\$(jq -r '.status' '$SBG/.apex/STATE.json')\" = 'initializing' ]"
assert_pass "R6-011+R6-004: rebuilt phases_total=0 default"        "[ \"\$(jq -r '.phases_total' '$SBG/.apex/STATE.json')\" = '0' ]"
rm -rf "$SBG"

# --- Case H: R6-011 sync-to-claude.sh delivers the template ---
assert_pass "R6-011: sync-to-claude delivers STATE-init.template.json" \
  "grep -q 'STATE-init.template.json' '$REPO_ROOT/framework/scripts/sync-to-claude.sh'"

echo ""
echo "Results: $PASS passed, $FAIL failed"
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-state-rebuild"
fi
exit "$FAIL"
