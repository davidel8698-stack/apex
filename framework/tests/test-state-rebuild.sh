#!/usr/bin/env bash
# R5-004: state-rebuild.sh reconstructs .apex/STATE.json from event-log.jsonl
# Test asserts:
#   1. Hook exits 0 when STATE.json already exists (no-op).
#   2. Hook produces STATE.json from a fixture event log when STATE.json
#      is missing.
#   3. STATE.json contains at least `current_phase` and `decision_mode`
#      derived from the JSONL.
#   4. Idempotency: running rebuild twice yields byte-identical STATE.json.
#   5. Unknown event types are tolerated (no error).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/state-rebuild.sh"

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
assert_pass "decision_mode derived from JSONL"          "[ \"\$(jq -r '.decision_mode' '$SBB/.apex/STATE.json')\" = 'balanced' ]"
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
assert_pass "R6-004: rebuilt decision_mode reflects last emit" "[ \"\$(jq -r '.decision_mode' '$SBE/.apex/STATE.json')\" = 'fast' ]"
assert_pass "R6-004: rebuilt complexity_level reflects emit"   "[ \"\$(jq -r '.complexity_level' '$SBE/.apex/STATE.json')\" = '4' ]"
rm -rf "$SBE"

echo ""
echo "Results: $PASS passed, $FAIL failed"
exit "$FAIL"
