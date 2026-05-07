#!/usr/bin/env bash
# R5-002: opt-in SQLite mirror over STATE.json + event-log.jsonl.
#
# Test asserts:
#   1. With APEX_SQLITE_MIRROR unset/empty, _state-update.sh writes JSON
#      and JSONL byte-identically (no .apex/state.db is created).
#   2. With APEX_SQLITE_MIRROR=1 and sqlite3 present, .apex/state.db
#      appears with a non-empty state_snapshot table after a state write.
#   3. With APEX_SQLITE_MIRROR=1 and sqlite3 absent, the mirror prints
#      a fail-loud message and the host write does NOT crash. The state
#      file is still updated atomically.
#   4. Three-places contract: _state-sqlite.sh exists, sync-to-claude.sh
#      delivers it, HOOK-CLASSIFICATION.md lists it.
#
# Spec anchor: "SQLite+FTS5 as future migration path …"

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK_LIB="$REPO_ROOT/framework/hooks/_state-update.sh"
SQLITE_LIB="$REPO_ROOT/framework/hooks/_state-sqlite.sh"

if [ ! -f "$HOOK_LIB" ]; then
  echo "FAIL: $HOOK_LIB not found" >&2
  exit 1
fi
if [ ! -f "$SQLITE_LIB" ]; then
  echo "FAIL: $SQLITE_LIB not found" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not available — _state-update requires jq"
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
  mkdir -p "$sandbox/.apex"
  echo '{"counter":0,"updated_at":"2026-01-01T00:00:00Z"}' > "$sandbox/.apex/STATE.json"
  printf '%s' "$sandbox"
}

echo "=== R5-002: SQLite mirror tests ==="

# --- Three-places contract -----------------------------------------------
echo
echo "[contract] three-places contract"
assert_pass "_state-sqlite.sh exists" "test -f '$SQLITE_LIB'"
assert_pass "sync-to-claude.sh delivers _state-sqlite.sh (via copy_tree or explicit)" \
  "grep -E '_state-sqlite.sh|copy_tree.*FRAMEWORK_ROOT/hooks' '$REPO_ROOT/framework/scripts/sync-to-claude.sh' | grep -q ."
assert_pass "HOOK-CLASSIFICATION.md lists _state-sqlite.sh" \
  "grep -q '_state-sqlite.sh' '$REPO_ROOT/framework/HOOK-CLASSIFICATION.md'"
assert_pass "STATE-PLANE.md exists" \
  "test -f '$REPO_ROOT/framework/docs/STATE-PLANE.md'"
assert_pass "STATE.schema.json declares optional sqlite_mirror" \
  "jq -e '.properties.sqlite_mirror.type==\"object\"' '$REPO_ROOT/framework/schemas/STATE.schema.json'"

# --- Mirror unset → byte-identical to baseline ---------------------------
echo
echo "[default] APEX_SQLITE_MIRROR unset — baseline preserved"
SANDBOX_A="$(run_sandbox)"
(
  cd "$SANDBOX_A"
  unset APEX_SQLITE_MIRROR
  source "$HOOK_LIB"
  _state_update '.counter = 1'
)
assert_pass "STATE.json updated with counter=1" \
  "jq -e '.counter == 1' '$SANDBOX_A/.apex/STATE.json'"
assert_pass "event-log.jsonl appended" \
  "test -s '$SANDBOX_A/.apex/event-log.jsonl'"
assert_pass "no state.db created when mirror disabled" \
  "test ! -e '$SANDBOX_A/.apex/state.db'"
rm -rf "$SANDBOX_A"

# --- Mirror=1 with sqlite3 present → mirror created ---------------------
echo
echo "[enabled] APEX_SQLITE_MIRROR=1 — mirror behavior"
if command -v sqlite3 >/dev/null 2>&1; then
  SANDBOX_B="$(run_sandbox)"
  (
    cd "$SANDBOX_B"
    export APEX_SQLITE_MIRROR=1
    source "$HOOK_LIB"
    _state_update '.counter = 5'
  )
  assert_pass "STATE.json updated under mirror=1" \
    "jq -e '.counter == 5' '$SANDBOX_B/.apex/STATE.json'"
  assert_pass ".apex/state.db created" \
    "test -f '$SANDBOX_B/.apex/state.db'"
  assert_pass "state_snapshot has at least one row" \
    "[ \"\$(sqlite3 '$SANDBOX_B/.apex/state.db' 'SELECT COUNT(*) FROM state_snapshot;' 2>/dev/null)\" -ge 1 ]"
  assert_pass "events_fts virtual table exists" \
    "sqlite3 '$SANDBOX_B/.apex/state.db' \".schema events_fts\" 2>/dev/null | grep -q fts5"
  rm -rf "$SANDBOX_B"
else
  echo "  SKIP: sqlite3 CLI not available — cannot exercise mirror happy path"
fi

# --- Mirror=1 with sqlite3 absent → fail-loud-and-skip -------------------
echo
echo "[fallback] APEX_SQLITE_MIRROR=1 with sqlite3 absent — fail-loud-and-skip"
SANDBOX_C="$(run_sandbox)"
ERR_LOG="$SANDBOX_C/mirror.err"
(
  cd "$SANDBOX_C"
  # Force sqlite3 to appear absent by clearing PATH down to a minimal set
  # that excludes sqlite3 binaries. We keep /usr/bin and /bin to retain
  # date, jq, etc. but build a temp PATH-shim that hides sqlite3.
  SHIM_DIR="$(mktemp -d)"
  cat > "$SHIM_DIR/sqlite3" <<'INNER'
#!/usr/bin/env bash
exit 127
INNER
  # Don't actually invoke; we just want command -v to fail. Easier: put a
  # PATH that excludes sqlite3's normal location.
  # Approach: prepend a directory that has no sqlite3 and remove the original
  # by exporting a PATH that begins with SHIM_DIR (empty for sqlite3) and
  # excludes the directories containing sqlite3.
  rm -f "$SHIM_DIR/sqlite3"
  # Build a PATH excluding directories that contain sqlite3.
  ORIG_PATH="$PATH"
  if command -v sqlite3 >/dev/null 2>&1; then
    SQLITE_BIN="$(command -v sqlite3)"
    SQLITE_DIR="$(dirname "$SQLITE_BIN")"
    # Filter the dir out of PATH.
    NEW_PATH=""
    IFS=':'
    for p in $ORIG_PATH; do
      if [ "$p" != "$SQLITE_DIR" ]; then
        if [ -z "$NEW_PATH" ]; then NEW_PATH="$p"; else NEW_PATH="$NEW_PATH:$p"; fi
      fi
    done
    unset IFS
    export PATH="$NEW_PATH"
  fi
  export APEX_SQLITE_MIRROR=1
  source "$HOOK_LIB"
  _state_update '.counter = 9' 2>"$ERR_LOG"
  rm -rf "$SHIM_DIR"
)
assert_pass "STATE.json still updated when sqlite3 absent" \
  "jq -e '.counter == 9' '$SANDBOX_C/.apex/STATE.json'"
assert_pass "fail-loud message printed (sqlite3 absent path)" \
  "grep -q 'sqlite3' '$ERR_LOG' || ! command -v sqlite3 >/dev/null 2>&1"
rm -rf "$SANDBOX_C"

# --- R6-013: Multi-event watermark ingestion ----------------------------
# Three event-log appends with no mirror call between them, then one mirror
# call → all three land in the events table (not just the last). Verifies
# the watermark sidecar exists and equals the line count. Verifies the
# bootstrap case (no offset file → ingest the full log).
echo
echo "[R6-013] watermark-based multi-event ingestion"
if command -v sqlite3 >/dev/null 2>&1; then
  SANDBOX_D="$(run_sandbox)"
  (
    cd "$SANDBOX_D"
    export APEX_SQLITE_MIRROR=1
    # Hand-craft three event lines (no _state_update so the mirror is not
    # auto-fired — we want to test the manual mirror call against a
    # multi-line log).
    cat > .apex/event-log.jsonl <<'JSONL'
{"ts":"2026-05-01T10:00:00Z","type":"phase_set","source":"test","current_phase":"01"}
{"ts":"2026-05-01T10:05:00Z","type":"decision_mode_set","source":"test","decision_mode":"fast"}
{"ts":"2026-05-01T10:10:00Z","type":"complexity_set","source":"test","complexity_level":3}
JSONL
    # First-time mirror (no offset file) → bootstrap case ingests full log.
    bash "$SQLITE_LIB" mirror .apex/STATE.json .apex/event-log.jsonl >/dev/null 2>&1
  )
  EVENT_COUNT=$(sqlite3 "$SANDBOX_D/.apex/state.db" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo 0)
  assert_pass "R6-013: bootstrap mirror ingests all 3 event-log lines" \
    "[ ${EVENT_COUNT:-0} -ge 3 ]"
  assert_pass "R6-013: watermark sidecar exists after mirror" \
    "[ -f '$SANDBOX_D/.apex/.sqlite-mirror.offset' ]"
  WATERMARK=$(cat "$SANDBOX_D/.apex/.sqlite-mirror.offset" 2>/dev/null | tr -d '[:space:]')
  assert_pass "R6-013: watermark equals event-log line count (=3)" \
    "[ '${WATERMARK:-0}' = '3' ]"
  # Append three more lines, mirror again → only the new lines are ingested.
  (
    cd "$SANDBOX_D"
    export APEX_SQLITE_MIRROR=1
    cat >> .apex/event-log.jsonl <<'JSONL'
{"ts":"2026-05-01T10:15:00Z","type":"session_event","source":"test","msg":"checkpoint"}
{"ts":"2026-05-01T10:20:00Z","type":"phase_set","source":"test","current_phase":"02"}
{"ts":"2026-05-01T10:25:00Z","type":"complexity_set","source":"test","complexity_level":4}
JSONL
    bash "$SQLITE_LIB" mirror .apex/STATE.json .apex/event-log.jsonl >/dev/null 2>&1
  )
  EVENT_COUNT_2=$(sqlite3 "$SANDBOX_D/.apex/state.db" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo 0)
  assert_pass "R6-013: second mirror appends only new lines (total=6)" \
    "[ ${EVENT_COUNT_2:-0} -eq 6 ]"
  WATERMARK_2=$(cat "$SANDBOX_D/.apex/.sqlite-mirror.offset" 2>/dev/null | tr -d '[:space:]')
  assert_pass "R6-013: watermark advances to new line count (=6)" \
    "[ '${WATERMARK_2:-0}' = '6' ]"
  # FTS5 mirror keeps pace with events table.
  FTS_COUNT=$(sqlite3 "$SANDBOX_D/.apex/state.db" "SELECT COUNT(*) FROM events_fts;" 2>/dev/null || echo 0)
  assert_pass "R6-013: events_fts mirrors events row-for-row" \
    "[ ${FTS_COUNT:-0} -eq 6 ]"
  # Idempotency: running mirror again with no new lines → no row growth.
  (
    cd "$SANDBOX_D"
    export APEX_SQLITE_MIRROR=1
    bash "$SQLITE_LIB" mirror .apex/STATE.json .apex/event-log.jsonl >/dev/null 2>&1
  )
  EVENT_COUNT_3=$(sqlite3 "$SANDBOX_D/.apex/state.db" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo 0)
  assert_pass "R6-013: idempotent mirror call (no growth, total=6)" \
    "[ ${EVENT_COUNT_3:-0} -eq 6 ]"
  rm -rf "$SANDBOX_D"
else
  echo "  SKIP: sqlite3 CLI not available — cannot exercise R6-013 watermark cases"
fi

# --- R6-013: STATE-PLANE.md documents the watermark approach -------------
echo
echo "[R6-013] STATE-PLANE.md watermark documentation"
assert_pass "R6-013: STATE-PLANE.md documents watermark" \
  "grep -q 'watermark' '$REPO_ROOT/framework/docs/STATE-PLANE.md'"
assert_pass "R6-013: STATE-PLANE.md names .sqlite-mirror.offset sidecar" \
  "grep -q '.sqlite-mirror.offset' '$REPO_ROOT/framework/docs/STATE-PLANE.md'"

echo
echo "=== Results: PASS=$PASS FAIL=$FAIL ==="
# R9-002: bridge private counters into harness globals once.
if declare -F harness_assert_local >/dev/null 2>&1; then
  harness_assert_local "$PASS" "$FAIL" "test-sqlite-mirror"
fi
if [ "$FAIL" -ne 0 ]; then
  exit 1
fi
exit 0
