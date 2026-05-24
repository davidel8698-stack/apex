#!/usr/bin/env bash
# test-audit-trail-layer.sh — Campaign B audit-trail layer test (Phases B2.0–B2.6).
#
# Campaign anchor: audit-trail-review/EXPERIMENT-PROTOCOL.md (frozen
# 2026-05-24T11:11:00Z baseline cece2a1). This test exercises the universal
# tool-call audit-trail layer the campaign installs. It is the binding
# regression gate for AC-1 (GAP-1), AC-2 (schema), AC-9 (sub-agent count
# guard), AC-11 (pre-task claims), and the B2.1–B2.6 sub-deliverables.
#
# Discipline:
#   * Each acceptance case is a separate function (a/b/c…) so the
#     summary line tells the maintainer which sub-fix regressed.
#   * Pending cases SKIP — they do NOT fail. A case flips from SKIP to
#     active when the matching B2.N hook/library lands. This keeps
#     run-all.sh `failed:0` between commits while honestly tracking the
#     TODO list.
#   * Lab-isolation: every case operates inside a per-case `mktemp -d`
#     sandbox initialised as a throw-away git repo with a stub `.apex/`.
#     Source the real hooks from $REPO_ROOT — never copy or mutate them.
#   * Cross-platform: bash + jq + git + tar/gzip only. No Python, no
#     node. Win32 `date +%s%N` is unreliable so we use `%s` (R-020-003).
#
# Sub-fix mapping (initial SKIP set; each case becomes active as its
# implementation commit lands):
#   B2.1 GAP-1 transcript aggregation     → AC-1
#   B2.2 schema enforcement              → AC-2
#   B2.3 rotation/retention              → (operational)
#   B2.4 universal hashing               → (defensive)
#   B2.5 pre-task claims                 → AC-11
#   B2.6 sub-agent count guard           → AC-9
#
# Cross-fix integration cases live at the bottom (e.g. F-204-013
# reconstruction is exercised in TP-2 B4 tests, not here).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOKS_DIR="$REPO_ROOT/framework/hooks"
SCHEMAS_DIR="$REPO_ROOT/framework/schemas"

LOCAL_PASS=0
LOCAL_FAIL=0
LOCAL_SKIP=0
ok()   { echo "  ✅ $1"; LOCAL_PASS=$((LOCAL_PASS+1)); }
nope() { echo "  ❌ $1"; LOCAL_FAIL=$((LOCAL_FAIL+1)); }
skip() { echo "  ⏭  $1"; LOCAL_SKIP=$((LOCAL_SKIP+1)); }

echo "=== Campaign B: audit-trail-layer integration tests ==="

# Hard dependencies. Missing → skip the whole file (run-all.sh records as
# a passing skip, not a hard FAIL — matches the IMP-036 first-deployment
# gate's contract for environment-conditional tests).
if ! command -v jq >/dev/null 2>&1; then
  skip "0a: jq not on PATH — layer test requires jq for JSON assertions"
  echo "$LOCAL_PASS/$((LOCAL_PASS+LOCAL_FAIL)) passed (skipped: $LOCAL_SKIP)"
  exit 0
fi
ok "0a: jq present"
if ! command -v git >/dev/null 2>&1; then
  skip "0b: git not on PATH — layer test sandboxes use git toplevel"
  echo "$LOCAL_PASS/$((LOCAL_PASS+LOCAL_FAIL)) passed (skipped: $LOCAL_SKIP)"
  exit 0
fi
ok "0b: git present"

# ----- helpers ------------------------------------------------------------

# mk_sandbox — create a throw-away git repo with .apex/ scaffold, cd into
# it, and source _state-update.sh so the test can call _emit_apex_event
# directly. Echoes the sandbox path so the caller can `rm -rf` it.
mk_sandbox() {
  local box
  box="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/apex-audit-trail-$$-$RANDOM")"
  mkdir -p "$box/.apex/subagent-transcripts" "$box/.apex/pre-task-claims" 2>/dev/null
  ( cd "$box" && git init -q 2>/dev/null && git -c user.email=t@t.t -c user.name=t commit --allow-empty -q -m init 2>/dev/null ) || true
  printf '%s\n' "$box"
}

# ----- A. B2.0 scaffold presence ------------------------------------------
# These three rows verify the scaffold itself — every other case can
# trust that the test file is discovered, the hooks dir is reachable,
# and the schemas dir exists for the JSON Schema artefact.

if [ -d "$HOOKS_DIR" ]; then
  ok "A1: framework/hooks/ resolvable"
else
  nope "A1: framework/hooks/ missing"
fi
if [ -d "$SCHEMAS_DIR" ]; then
  ok "A2: framework/schemas/ resolvable"
else
  nope "A2: framework/schemas/ missing"
fi
if [ -f "$HOOKS_DIR/_state-update.sh" ] && grep -q '^_emit_apex_event()' "$HOOKS_DIR/_state-update.sh"; then
  ok "A3: _emit_apex_event() defined in _state-update.sh"
else
  nope "A3: _emit_apex_event() not found — Campaign B can't extend it"
fi

# ----- B. B2.1 GAP-1 sub-agent transcript aggregation (AC-1) --------------
# Active assertions land in the B2.1 implementation commit. Each row
# becomes a hard `ok`/`nope` once `framework/hooks/pre-subagent-start.sh`
# and the matching `subagent-stop.sh` extension are committed.

if [ -f "$HOOKS_DIR/pre-subagent-start.sh" ]; then
  ok "B1: pre-subagent-start.sh present"
  if grep -qE 'subagent_start' "$HOOKS_DIR/pre-subagent-start.sh"; then
    ok "B2: pre-subagent-start.sh emits subagent_start event"
  else
    nope "B2: pre-subagent-start.sh missing subagent_start emission"
  fi
  if grep -qE 'agent_id' "$HOOKS_DIR/pre-subagent-start.sh"; then
    ok "B3: pre-subagent-start.sh synthesizes agent_id"
  else
    nope "B3: pre-subagent-start.sh missing agent_id synthesis"
  fi
else
  skip "B1: pre-subagent-start.sh pending B2.1 implementation"
  skip "B2: subagent_start emission pending B2.1"
  skip "B3: agent_id synthesis pending B2.1"
fi

if grep -q 'subagent_stop' "$HOOKS_DIR/subagent-stop.sh" 2>/dev/null \
   && grep -q 'subagent-transcripts' "$HOOKS_DIR/subagent-stop.sh" 2>/dev/null; then
  ok "B4: subagent-stop.sh extended to write subagent-transcripts/"
else
  skip "B4: subagent-stop.sh transcript-write pending B2.1"
fi

if grep -q 'agent_id' "$HOOKS_DIR/tool-event-logger.sh" 2>/dev/null; then
  ok "B5: tool-event-logger.sh stamps agent_id on tool_call events"
else
  skip "B5: tool-event-logger.sh agent_id stamping pending B2.1"
fi

if grep -q 'pre-subagent-start.sh' "$REPO_ROOT/framework/settings.json" 2>/dev/null; then
  ok "B6: settings.json wires pre-subagent-start.sh (PreToolUse matcher Agent)"
else
  skip "B6: settings.json wiring pending B2.1"
fi

# B2.1 acceptance test (live demonstration). Sandbox-only — simulates a
# subagent_start → tool_call → subagent_stop sequence by hand and
# asserts a transcript file lands under .apex/subagent-transcripts/.
if [ -f "$HOOKS_DIR/pre-subagent-start.sh" ] && grep -q 'subagent-transcripts' "$HOOKS_DIR/subagent-stop.sh" 2>/dev/null; then
  BOX="$(mk_sandbox)"
  pushd "$BOX" >/dev/null 2>&1
  # Simulate boundary events via the same _emit_apex_event the hooks use.
  # shellcheck disable=SC1090
  source "$HOOKS_DIR/_state-update.sh"
  export APEX_HOOK_SOURCE="test-audit-trail-layer"
  AID="subagent-framework-auditor-R999-deadbeef"
  _emit_apex_event "subagent_start" .apex agent_name "framework-auditor" agent_id "$AID" round_tag "R999"
  _emit_apex_event "tool_call" .apex tool_name "Bash" tool_input "{}" tool_response "{}" is_error "false" agent_id "$AID"
  _emit_apex_event "subagent_stop" .apex agent_name "framework-auditor" agent_id "$AID" round_tag "R999"
  # The B2.1 SubagentStop extension should denormalise into a transcript file.
  # We invoke subagent-stop.sh directly with a synthesized envelope.
  printf '{"agent_name":"framework-auditor","tool_calls_count":1,"agent_id":"%s","round_tag":"R999"}\n' "$AID" \
    | bash "$HOOKS_DIR/subagent-stop.sh" >/dev/null 2>&1 || true
  TRANSCRIPT_GLOB=".apex/subagent-transcripts/framework-auditor-R999-*.jsonl"
  # shellcheck disable=SC2086
  if ls $TRANSCRIPT_GLOB >/dev/null 2>&1; then
    ok "B7: live demo — transcript file landed under .apex/subagent-transcripts/"
    # Subset check: every line in the transcript carries agent_id == $AID
    # (within the start..stop boundary). A single mismatch fails the row.
    BAD=$(cat $TRANSCRIPT_GLOB 2>/dev/null | jq -r --arg a "$AID" 'select(.agent_id != $a and .agent_id != null) | .agent_id' | head -1)
    if [ -z "$BAD" ]; then
      ok "B8: transcript subset — every line agent_id == start/stop boundary id"
    else
      nope "B8: transcript subset violated — stray agent_id $BAD"
    fi
  else
    nope "B7: transcript file not created — B2.1 acceptance test FAIL"
    skip "B8: subset check skipped — no transcript to inspect"
  fi
  popd >/dev/null 2>&1
  rm -rf "$BOX"
else
  skip "B7: live demo pending B2.1 implementation"
  skip "B8: subset check pending B2.1 implementation"
fi

# ----- C. B2.2 schema enforcement (AC-2) ----------------------------------

if [ -f "$SCHEMAS_DIR/EVENT-LOG-ENTRY.schema.json" ]; then
  ok "C1: EVENT-LOG-ENTRY.schema.json present"
  # Required-field check: schema_version, ts, type, source must be required.
  REQUIRED=$(jq -r '.. | objects | select(has("required")) | .required[]' "$SCHEMAS_DIR/EVENT-LOG-ENTRY.schema.json" 2>/dev/null | sort -u | tr '\n' ' ')
  for f in schema_version ts type source; do
    if echo "$REQUIRED" | grep -qw "$f"; then
      ok "C2.$f: schema requires field '$f'"
    else
      nope "C2.$f: schema missing required field '$f'"
    fi
  done
  # oneOf discriminator present
  if jq -e '.oneOf' "$SCHEMAS_DIR/EVENT-LOG-ENTRY.schema.json" >/dev/null 2>&1; then
    ok "C3: schema uses oneOf for event-type variants"
  else
    nope "C3: schema missing oneOf discriminator"
  fi
else
  skip "C1: EVENT-LOG-ENTRY.schema.json pending B2.2"
  skip "C2: required-field check pending B2.2"
  skip "C3: oneOf discriminator pending B2.2"
fi

# Live malformed-entry routing. Sandbox simulates a malformed entry hitting
# the validation path; assertion is that the bad line goes to
# event-log-rejected.jsonl and never to the main log.
if [ -f "$SCHEMAS_DIR/EVENT-LOG-ENTRY.schema.json" ] && grep -q 'event-log-rejected' "$HOOKS_DIR/_state-update.sh" 2>/dev/null; then
  BOX="$(mk_sandbox)"
  pushd "$BOX" >/dev/null 2>&1
  # shellcheck disable=SC1090
  source "$HOOKS_DIR/_state-update.sh"
  export APEX_HOOK_SOURCE="test-audit-trail-layer"
  # Emit a deliberately invalid event (missing required `type`).
  _emit_apex_event "" .apex broken "true" 2>/dev/null || true
  if [ -f .apex/event-log-rejected.jsonl ] && [ -s .apex/event-log-rejected.jsonl ]; then
    ok "C4: malformed entry routed to event-log-rejected.jsonl"
  else
    nope "C4: malformed entry NOT routed to rejection log"
  fi
  popd >/dev/null 2>&1
  rm -rf "$BOX"
else
  skip "C4: rejection-log routing pending B2.2"
fi

# ----- D. B2.3 rotation/retention -----------------------------------------

if [ -f "$HOOKS_DIR/event-log-rotate.sh" ]; then
  ok "D1: event-log-rotate.sh present"
  if grep -qE '10[[:space:]]*\*[[:space:]]*1024[[:space:]]*\*[[:space:]]*1024|10485760|10MB|10 MB|10\s*MiB' "$HOOKS_DIR/event-log-rotate.sh"; then
    ok "D2: event-log-rotate.sh references the 10 MB threshold"
  else
    nope "D2: event-log-rotate.sh missing 10 MB threshold"
  fi
  if grep -qE 'gzip|\.gz' "$HOOKS_DIR/event-log-rotate.sh"; then
    ok "D3: event-log-rotate.sh compresses rotated archives"
  else
    nope "D3: event-log-rotate.sh missing gzip step"
  fi
else
  skip "D1: event-log-rotate.sh pending B2.3"
  skip "D2: 10 MB threshold pending B2.3"
  skip "D3: gzip step pending B2.3"
fi

if grep -q 'event-log-rotate.sh' "$REPO_ROOT/framework/settings.json" 2>/dev/null; then
  ok "D4: settings.json wires event-log-rotate.sh on SessionStart"
else
  skip "D4: settings.json wiring pending B2.3"
fi

# ----- E. B2.4 universal hashing ------------------------------------------

if grep -qE 'tool_input_hash|hash_(write|edit|read|agent)' "$HOOKS_DIR/circuit-breaker.sh" 2>/dev/null; then
  ok "E1: circuit-breaker.sh extended to hash Write/Edit/Read/Agent"
else
  skip "E1: universal hashing pending B2.4"
fi

# ----- F. B2.5 pre-task claims (AC-11) ------------------------------------

if grep -q 'pre-task-claims' "$HOOKS_DIR/pre-task-snapshot.sh" 2>/dev/null \
   && grep -q 'pre_task_claim' "$HOOKS_DIR/pre-task-snapshot.sh" 2>/dev/null; then
  ok "F1: pre-task-snapshot.sh writes pre-task-claims/ + emits pre_task_claim event"
else
  skip "F1: pre-task claims pending B2.5"
fi

# ----- G. B2.6 sub-agent count guard (AC-9) -------------------------------

if grep -q 'subagent_count_mismatch' "$HOOKS_DIR/subagent-stop.sh" 2>/dev/null; then
  ok "G1: subagent-stop.sh cross-references claimed vs observed tool_calls_count"
  # Live lying-subagent synthetic test.
  BOX="$(mk_sandbox)"
  pushd "$BOX" >/dev/null 2>&1
  # shellcheck disable=SC1090
  source "$HOOKS_DIR/_state-update.sh"
  AID="subagent-liar-RX-cafebabe"
  # Boundary events present, but ZERO tool_call entries between them.
  _emit_apex_event "subagent_start" .apex agent_name "liar" agent_id "$AID" round_tag "RX"
  _emit_apex_event "subagent_stop"  .apex agent_name "liar" agent_id "$AID" round_tag "RX"
  # Lying envelope: claims 5 tool calls but transcript is empty.
  printf '{"agent_name":"liar","tool_calls_count":5,"agent_id":"%s","round_tag":"RX"}\n' "$AID" \
    | bash "$HOOKS_DIR/subagent-stop.sh" >/dev/null 2>&1 || true
  if grep -q '"type":"subagent_count_mismatch"' .apex/event-log.jsonl 2>/dev/null; then
    ok "G2: lying-subagent synthetic — P0 subagent_count_mismatch emitted"
  else
    nope "G2: lying-subagent synthetic — count-mismatch P0 NOT emitted"
  fi
  popd >/dev/null 2>&1
  rm -rf "$BOX"
else
  skip "G1: sub-agent count guard pending B2.6"
  skip "G2: lying-subagent synthetic pending B2.6"
fi

# ----- summary ------------------------------------------------------------
TOTAL=$((LOCAL_PASS + LOCAL_FAIL))
echo "── $LOCAL_PASS/$TOTAL passed (skipped: $LOCAL_SKIP)"
if [ "$LOCAL_FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
