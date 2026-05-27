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
# Design note: B2.4 emits `tool_input_hash` from tool-event-logger.sh
# (PostToolUse matcher `*`) rather than from circuit-breaker.sh
# (matcher `Bash` only). Same canonical-string contract (CHECK 4 in
# circuit-breaker.sh) — but universal coverage and zero risk to the
# breaker's safety semantics. Documented in commit message; consumer
# code (round-checker TP-2, critic) reads the events from event-log
# regardless of which hook emitted them.

if grep -qE 'tool_input_hash' "$HOOKS_DIR/tool-event-logger.sh" 2>/dev/null; then
  ok "E1: tool-event-logger.sh emits tool_input_hash on every tool call"
  # Live demo — emit a Read+identical-Read pair via _emit_apex_event
  # and assert hash determinism.
  BOX="$(mk_sandbox)"
  pushd "$BOX" >/dev/null 2>&1
  # Simulate two identical Read PostToolUse envelopes through
  # tool-event-logger.sh by calling its stdin entry directly.
  ENV='{"tool_name":"Read","tool_input":{"file_path":"/tmp/x.txt"},"tool_response":{},"session_id":"sid-test"}'
  echo "$ENV" | bash "$HOOKS_DIR/tool-event-logger.sh" >/dev/null 2>&1 || true
  echo "$ENV" | bash "$HOOKS_DIR/tool-event-logger.sh" >/dev/null 2>&1 || true
  N=$(grep -c '"type":"tool_input_hash"' .apex/event-log.jsonl 2>/dev/null || echo 0)
  if [ "$N" -ge 2 ]; then
    # Determinism: both lines should carry the same hash_sha1.
    H_UNIQUE=$(grep '"type":"tool_input_hash"' .apex/event-log.jsonl | jq -r '.hash_sha1' 2>/dev/null | sort -u | wc -l | tr -d ' ')
    if [ "$H_UNIQUE" = "1" ]; then
      ok "E2: identical Read calls produce identical hash (determinism)"
    else
      nope "E2: hash differs across identical Reads — canonicalisation broken"
    fi
  else
    nope "E2: tool_input_hash events not emitted by live demo"
  fi
  popd >/dev/null 2>&1
  rm -rf "$BOX"
else
  skip "E1: universal hashing pending B2.4"
  skip "E2: live-demo determinism pending B2.4"
fi

# ----- F. B2.5 pre-task claims (AC-11) ------------------------------------

if grep -q 'pre-task-claims' "$HOOKS_DIR/pre-task-snapshot.sh" 2>/dev/null \
   && grep -q 'pre_task_claim' "$HOOKS_DIR/pre-task-snapshot.sh" 2>/dev/null; then
  ok "F1: pre-task-snapshot.sh writes pre-task-claims/ + emits pre_task_claim event"
  # Live demo: stage a fake PLAN_META.json with a single task, invoke
  # pre-task-snapshot.sh with the matching id, assert the claim file
  # lands AND the event-log carries a pre_task_claim entry.
  BOX="$(mk_sandbox)"
  pushd "$BOX" >/dev/null 2>&1
  PHASE="test-phase"
  TASK="test-task-1"
  mkdir -p ".apex/phases/${PHASE}"
  cat > .apex/STATE.json <<JSON
{ "current_phase": "${PHASE}" }
JSON
  cat > ".apex/phases/${PHASE}/PLAN_META.json" <<JSON
{
  "phase_id": "${PHASE}",
  "phase_name": "audit-trail layer test",
  "tasks": [
    {
      "id": "${TASK}",
      "name": "demo",
      "files": ["src/foo.sh", "src/bar.sh"],
      "done_criteria": ["foo wired", "bar tested"]
    }
  ]
}
JSON
  # Run the hook with the task id (named-invocation path, no stdin
  # envelope — bypasses the R8-008 self-filter and the git-stash side
  # effect since the sandbox has nothing to stash).
  bash "$HOOKS_DIR/pre-task-snapshot.sh" "$TASK" </dev/null >/dev/null 2>&1 || true
  if [ -f ".apex/pre-task-claims/${TASK}.json" ]; then
    EXP_FILES_CT=$(jq -r '(.expected_files | length)' ".apex/pre-task-claims/${TASK}.json" 2>/dev/null)
    if [ "$EXP_FILES_CT" = "2" ]; then
      ok "F2: claim file captures expected_files[] from PLAN_META"
    else
      nope "F2: expected_files count wrong (want 2, got ${EXP_FILES_CT:-empty})"
    fi
  else
    nope "F2: claim file not created"
  fi
  if grep -q '"type":"pre_task_claim"' .apex/event-log.jsonl 2>/dev/null; then
    ok "F3: pre_task_claim event landed in event-log"
  else
    nope "F3: pre_task_claim event NOT in event-log"
  fi
  popd >/dev/null 2>&1
  rm -rf "$BOX"
else
  skip "F1: pre-task claims pending B2.5"
  skip "F2: live demo pending B2.5"
  skip "F3: event-log emit pending B2.5"
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

# ----- H. Campaign C TP-C2 three-factor audit-probe carve-out (AC-C2) -------
# Spec anchor: audit-trail-review/FIX-DESIGN-C-R4.md §4 (frozen 2026-05-25).
# Verifies marker + agent_id + nonce three-factor protocol.

if [ -f "$HOOKS_DIR/_audit-probe-marker.sh" ]; then
  ok "H0: _audit-probe-marker.sh shared helper present"

  BOX="$(mk_sandbox)"
  pushd "$BOX" >/dev/null 2>&1
  # shellcheck disable=SC1090
  source "$HOOKS_DIR/_audit-probe-marker.sh"

  # H-C1: marker + valid agent_id + matching nonce → allow (exit 0)
  printf '%s\n' '{"agent_id":"subagent-framework-auditor-25-c1abcdef","agent_name":"framework-auditor","status":"in_flight","audit_probe_nonce":"deadbeef00000001","round_tag":"H-C1","started_at":"2026-05-25T15:00:00Z"}' > .apex/in-flight-subagents.jsonl
  if apex_check_audit_probe "__APEX_AUDIT_PROBE__:deadbeef00000001:subagent-framework-auditor-25-c1abcdef rm -rf /tmp/x" 2>/dev/null; then
    ok "H-C1: three-factor PASS — marker+agent+nonce all valid → allow"
  else
    nope "H-C1: three-factor PASS path failed"
  fi

  # H-C2: no marker → return 1 (block-fallthrough — caller continues to existing block path)
  if apex_check_audit_probe "rm -rf /tmp/x" 2>/dev/null; then
    nope "H-C2: marker-absent INCORRECTLY allowed"
  else
    ok "H-C2: marker-absent → return 1 (block-fallthrough preserved)"
  fi

  # H-C3: marker + wrong agent_name in registry (executor, not framework-auditor) → block
  printf '%s\n' '{"agent_id":"subagent-executor-25-c3cafebab","agent_name":"executor","status":"in_flight","audit_probe_nonce":"deadbeef00000002","round_tag":"H-C3","started_at":"2026-05-25T15:00:00Z"}' > .apex/in-flight-subagents.jsonl
  if apex_check_audit_probe "__APEX_AUDIT_PROBE__:deadbeef00000002:subagent-executor-25-c3cafebab rm -rf /tmp/x" 2>/dev/null; then
    nope "H-C3: non-auditor agent INCORRECTLY allowed via marker (F2 broken)"
  else
    ok "H-C3: non-auditor agent → blocked (F2 enforced)"
  fi

  # H-C4: marker prefix on Write tool's new_string field — helper extracts from full field-list
  # (Test by direct command-style invocation since the shell helper takes COMMAND as $1.)
  printf '%s\n' '{"agent_id":"subagent-framework-auditor-25-c4abcdef","agent_name":"framework-auditor","status":"in_flight","audit_probe_nonce":"deadbeef00000004","round_tag":"H-C4","started_at":"2026-05-25T15:00:00Z"}' > .apex/in-flight-subagents.jsonl
  if apex_check_audit_probe "__APEX_AUDIT_PROBE__:deadbeef00000004:subagent-framework-auditor-25-c4abcdef echo hi" 2>/dev/null; then
    ok "H-C4: marker on benign payload → allow (parser correctness on multi-token cmd)"
  else
    nope "H-C4: parser failed on benign multi-token marker"
  fi

  # H-C5: registry has framework-auditor STOPPED + a different framework-auditor IN_FLIGHT → use the in-flight one
  printf '%s\n' '{"agent_id":"subagent-framework-auditor-25-c5oldstop","agent_name":"framework-auditor","status":"stopped","audit_probe_nonce":"deadbeef00000005","round_tag":"H-C5","started_at":"2026-05-25T15:00:00Z","stopped_at":"2026-05-25T15:00:30Z"}' > .apex/in-flight-subagents.jsonl
  printf '%s\n' '{"agent_id":"subagent-framework-auditor-25-c5newlive","agent_name":"framework-auditor","status":"in_flight","audit_probe_nonce":"deadbeef00000006","round_tag":"H-C5","started_at":"2026-05-25T15:01:00Z"}' >> .apex/in-flight-subagents.jsonl
  if apex_check_audit_probe "__APEX_AUDIT_PROBE__:deadbeef00000006:subagent-framework-auditor-25-c5newlive rm -rf /tmp/x" 2>/dev/null; then
    ok "H-C5: multi-entry registry — picks in_flight entry over stopped"
  else
    nope "H-C5: multi-entry registry handling broke"
  fi

  # H-C6: only entry is framework-auditor STOPPED (no in_flight) → block
  printf '%s\n' '{"agent_id":"subagent-framework-auditor-25-c6stopped","agent_name":"framework-auditor","status":"stopped","audit_probe_nonce":"deadbeef00000007","round_tag":"H-C6","started_at":"2026-05-25T15:00:00Z","stopped_at":"2026-05-25T15:00:30Z"}' > .apex/in-flight-subagents.jsonl
  if apex_check_audit_probe "__APEX_AUDIT_PROBE__:deadbeef00000007:subagent-framework-auditor-25-c6stopped rm -rf /tmp/x" 2>/dev/null; then
    nope "H-C6: stopped-only framework-auditor INCORRECTLY allowed"
  else
    ok "H-C6: stopped-only framework-auditor → blocked (status=in_flight enforced)"
  fi

  # H-C7: marker malformed (no second colon) → block (CR-C-R3-03 parser hardening)
  printf '%s\n' '{"agent_id":"subagent-framework-auditor-25-c7parser","agent_name":"framework-auditor","status":"in_flight","audit_probe_nonce":"deadbeef00000008","round_tag":"H-C7","started_at":"2026-05-25T15:00:00Z"}' > .apex/in-flight-subagents.jsonl
  if apex_check_audit_probe "__APEX_AUDIT_PROBE__:deadbeef00000008 rm -rf /tmp/x" 2>/dev/null; then
    nope "H-C7: malformed marker (no second colon) INCORRECTLY allowed — parser regression"
  else
    ok "H-C7: malformed marker → blocked (parser correctness CR-C-R3-03)"
  fi

  # H-C8: audit_probe_allowed event emission verified
  printf '%s\n' '{"agent_id":"subagent-framework-auditor-25-c8eventtt","agent_name":"framework-auditor","status":"in_flight","audit_probe_nonce":"deadbeef00000009","round_tag":"H-C8","started_at":"2026-05-25T15:00:00Z"}' > .apex/in-flight-subagents.jsonl
  rm -f .apex/event-log.jsonl
  apex_check_audit_probe "__APEX_AUDIT_PROBE__:deadbeef00000009:subagent-framework-auditor-25-c8eventtt echo audit-probe-event-test" 2>/dev/null
  if grep -q '"type":"audit_probe_allowed"' .apex/event-log.jsonl 2>/dev/null \
     && grep -q '"agent_id":"subagent-framework-auditor-25-c8eventtt"' .apex/event-log.jsonl 2>/dev/null; then
    ok "H-C8: audit_probe_allowed event emitted with matching agent_id"
  else
    nope "H-C8: audit_probe_allowed event missing or mismatched"
  fi

  popd >/dev/null 2>&1
  rm -rf "$BOX"
else
  skip "H0: _audit-probe-marker.sh not present — Campaign C TP-C2 not installed"
  skip "H-C1..H-C8: TP-C2 tests skipped (helper missing)"
fi

# ----- H-D Phase-7 R-AT-C-02: mutation-class probe minimum gates ----------
# Tests round-checker TP-2 §6.b clauses (i)-(vi) — fixture-anchored
# per-class coverage enforcement that closes AC-5b heldout B+C+D >= 5/5.
# Design: audit-trail-review/PHASE-7-RITEM-R-AT-C-02-DESIGN-R2.md §2.D

MUTATION_FIXTURE="$REPO_ROOT/framework/test-fixtures/mutation-class-probes.json"
HD_FIXTURE_DIR="$REPO_ROOT/framework/test-fixtures"

# jq_clean — wrapper that strips CR from jq output (jq 1.8.x on Windows
# emits CRLF; downstream `grep -Fx` compares fail otherwise).
jq_clean() { jq "$@" | tr -d '\r'; }

# round_checker_sim — local simulator of round-checker mutation-class
# enforcement logic. Reads a transcript fixture + the mutation-class
# fixture; emits the verdict name to stdout. Mirrors clauses (i)-(vi).
round_checker_sim() {
  local transcript="$1"
  local fixture="$MUTATION_FIXTURE"

  # Clause (i): fixture readability gate
  if [ ! -f "$fixture" ] || ! jq -e . "$fixture" >/dev/null 2>&1; then
    echo "mutation_class_fixture_missing"
    return
  fi

  # Existing rule: axis_10 empty → axis_10_blind_spot (fires before new clauses)
  local axis_10_count
  axis_10_count=$(jq_clean -r '.axis_10.concrete_bypass_attempts | length' "$transcript" 2>/dev/null || echo 0)
  if [ "${axis_10_count:-0}" -eq 0 ]; then
    echo "axis_10_blind_spot"
    return
  fi

  # Clause (vi) normalization helper: lowercase guard names from transcript
  local guards_in_axis_10
  guards_in_axis_10=$(jq_clean -r '.axis_10.concrete_bypass_attempts[].guard // empty' "$transcript" 2>/dev/null \
                     | tr '[:upper:]' '[:lower:]' | sort -u)

  # Clause (ii): per-guard coverage floor — UNION of all 4 mutation classes
  local g
  for g in $(jq_clean -r '
      .regex_word_boundary[].guard_canonical_name,
      .case_folding[].guard_canonical_name,
      .silent_failure[].guard_canonical_name,
      .counter_swallow[].target_canonical_name
    ' "$fixture" 2>/dev/null | sort -u); do
    if ! echo "$guards_in_axis_10" | grep -Fxq "$(echo "$g" | tr '[:upper:]' '[:lower:]')"; then
      echo "axis_10_guard_coverage_gap"
      return
    fi
  done

  # Clause (iii): regex_word_boundary minimum (>=1 boundary variant per guard)
  for g in $(jq_clean -r '.regex_word_boundary[].guard_canonical_name' "$fixture"); do
    local payloads payload_classes boundary_variants boundary_variant_ids matched
    payloads=$(jq_clean -r --arg g "$g" '
      .axis_10.concrete_bypass_attempts[]
      | select((.guard // "" | ascii_downcase) == ($g | ascii_downcase))
      | .payload // empty
    ' "$transcript" 2>/dev/null)
    payload_classes=$(jq_clean -r --arg g "$g" '
      .axis_10.concrete_bypass_attempts[]
      | select((.guard // "" | ascii_downcase) == ($g | ascii_downcase))
      | .payload_class // empty
    ' "$transcript" 2>/dev/null)
    boundary_variants=$(jq_clean -r --arg g "$g" '
      .regex_word_boundary[] | select(.guard_canonical_name == $g) | .boundary_variants[]?
    ' "$fixture" 2>/dev/null)
    boundary_variant_ids=$(jq_clean -r --arg g "$g" '
      .regex_word_boundary[] | select(.guard_canonical_name == $g) | .boundary_variant_ids[]?
    ' "$fixture" 2>/dev/null)
    matched=0
    if [ -n "$boundary_variants" ]; then
      while IFS= read -r bv; do
        [ -z "$bv" ] && continue
        if echo "$payloads" | grep -Fxq "$bv"; then matched=1; break; fi
      done <<< "$boundary_variants"
    fi
    if [ "$matched" -eq 0 ] && [ -n "$boundary_variant_ids" ]; then
      while IFS= read -r bvid; do
        [ -z "$bvid" ] && continue
        if echo "$payload_classes" | grep -Fxq "$bvid"; then matched=1; break; fi
      done <<< "$boundary_variant_ids"
    fi
    if [ "$matched" -eq 0 ]; then
      echo "axis_10_mutation_class_blind_spot"
      return
    fi
  done

  # Clause (iv): case_folding minimum (>=3 distinct case-variant IDs per guard)
  for g in $(jq_clean -r '.case_folding[].guard_canonical_name' "$fixture"); do
    local variant_ids count
    variant_ids=$(jq_clean -r --arg g "$g" '
      .case_folding[] | select(.guard_canonical_name == $g) | .case_variant_ids[]?
    ' "$fixture")
    count=0
    while IFS= read -r vid; do
      [ -z "$vid" ] && continue
      if jq_clean -r --arg g "$g" --arg v "$vid" '
        .axis_10.concrete_bypass_attempts[]
        | select((.guard // "" | ascii_downcase) == ($g | ascii_downcase))
        | select((.payload_class // "") == $v) | "ok"
      ' "$transcript" 2>/dev/null | grep -q ok; then
        count=$((count+1))
      fi
    done <<< "$variant_ids"
    if [ "$count" -lt 3 ]; then
      echo "axis_10_case_folding_blind_spot"
      return
    fi
  done

  # Clause (v): silent_failure stderr-assertion minimum
  for g in $(jq_clean -r '.silent_failure[].guard_canonical_name' "$fixture"); do
    local has_stderr_assertion
    has_stderr_assertion=$(jq_clean -r --arg g "$g" '
      .axis_10.concrete_bypass_attempts[]
      | select((.guard // "" | ascii_downcase) == ($g | ascii_downcase))
      | select((.stderr_nonempty == true) or ((.stderr_contains // "") != ""))
      | "ok"
    ' "$transcript" 2>/dev/null | head -1)
    if [ "$has_stderr_assertion" != "ok" ]; then
      echo "axis_10_silent_failure_blind_spot"
      return
    fi
  done

  # Clause (vii) — Per-guard runtime-contract probe count (R-AT-C-04).
  # Minimum settings-wired-guard set for layer-test purposes: destructive-guard.sh
  # (canonical F-001 representative). Real-world auditors parse settings.json fully.
  local settings_wired_guards="destructive-guard.sh"
  for g in $settings_wired_guards; do
    local has_probe
    has_probe=$(jq_clean -r --arg g "$g" '
      .axis_13.runtime_contract_probes[]?
      | select((.guard // "" | ascii_downcase) == ($g | ascii_downcase))
      | "ok"
    ' "$transcript" 2>/dev/null | head -1)
    if [ "$has_probe" != "ok" ]; then
      echo "axis_13_runtime_contract_blind_spot"
      return
    fi
  done

  # Clause (viii) — Discrepancy-classification gate (R-AT-C-04).
  # For each discrepant entry (argv_exit != stdin_exit), at least one finding's
  # cite[] must include the guard filename. Rolled-up multi-guard cite[] accepted.
  local discrepant_guards
  discrepant_guards=$(jq_clean -r '
    .axis_13.runtime_contract_probes[]?
    | select(.argv_exit != .stdin_exit)
    | .guard
  ' "$transcript" 2>/dev/null | sort -u)
  if [ -n "$discrepant_guards" ]; then
    while IFS= read -r dg; do
      [ -z "$dg" ] && continue
      local cite_match
      cite_match=$(jq_clean -r --arg g "$dg" '
        .findings[]?
        | .cite[]?
        | select(. == $g)
        | "ok"
      ' "$transcript" 2>/dev/null | head -1)
      if [ "$cite_match" != "ok" ]; then
        echo "axis_13_runtime_contract_drift_unreported"
        return
      fi
    done <<< "$discrepant_guards"
  fi

  # Clause (ix) — Source-literal carve-out scan (R-DH-P7-01).
  # Layer-test minimum regex-deny subset: destructive-guard.sh + path-guard.sh
  # (production axis-13.c requires full extracted_set; this is the narrowed
  # minimum for layer-test scope per critic R2 NB-1).
  local regex_deny_guards="destructive-guard.sh path-guard.sh"
  for g in $regex_deny_guards; do
    local has_scan_entry
    has_scan_entry=$(jq_clean -r --arg g "$g" '
      .axis_13.source_literal_carveouts[]?
      | select((.guard // "" | ascii_downcase) == ($g | ascii_downcase))
      | "ok"
    ' "$transcript" 2>/dev/null | head -1)
    if [ "$has_scan_entry" != "ok" ]; then
      echo "axis_13_source_literal_scan_blind_spot"
      return
    fi
  done
  # Per-entry emission gate: undocumented carveouts with exit-0 bypass
  # MUST have a cite[] finding for the guard.
  local unreported_guards
  unreported_guards=$(jq_clean -r '
    .axis_13.source_literal_carveouts[]?
    | select((.exempt_via // "") == "undocumented")
    | select(any(.probe_exits[]?; . == 0))
    | .guard
  ' "$transcript" 2>/dev/null | sort -u)
  if [ -n "$unreported_guards" ]; then
    while IFS= read -r ug; do
      [ -z "$ug" ] && continue
      local cite_match
      cite_match=$(jq_clean -r --arg g "$ug" '
        .findings[]? | .cite[]? | select(. == $g) | "ok"
      ' "$transcript" 2>/dev/null | head -1)
      if [ "$cite_match" != "ok" ]; then
        echo "axis_13_source_literal_bypass_unreported"
        return
      fi
    done <<< "$unreported_guards"
  fi

  echo "PASS"
}

run_hd_test() {
  local h_id="$1" expected="$2" transcript="$3" extra_setup="$4"
  local saved_fixture="" verdict
  if [ "$extra_setup" = "remove_fixture" ]; then
    saved_fixture=$(mktemp)
    cp "$MUTATION_FIXTURE" "$saved_fixture"
    rm -f "$MUTATION_FIXTURE"
  fi
  verdict=$(round_checker_sim "$transcript")
  if [ -n "$saved_fixture" ]; then
    mv "$saved_fixture" "$MUTATION_FIXTURE"
  fi
  if [ "$verdict" = "$expected" ]; then
    ok "$h_id: $expected — verdict matches"
  else
    nope "$h_id: expected $expected, got $verdict"
  fi
}

if [ -f "$MUTATION_FIXTURE" ]; then
  ok "H-D0: mutation-class-probes.json fixture present"
  run_hd_test "H-D1" "axis_10_mutation_class_blind_spot" "$HD_FIXTURE_DIR/round-checker-h-d-1.jsonl" ""
  run_hd_test "H-D2" "PASS"                              "$HD_FIXTURE_DIR/round-checker-h-d-2.jsonl" ""
  run_hd_test "H-D3" "axis_10_case_folding_blind_spot"   "$HD_FIXTURE_DIR/round-checker-h-d-3.jsonl" ""
  run_hd_test "H-D4" "axis_10_silent_failure_blind_spot" "$HD_FIXTURE_DIR/round-checker-h-d-4.jsonl" ""
  run_hd_test "H-D5" "axis_10_blind_spot"                "$HD_FIXTURE_DIR/round-checker-h-d-5.jsonl" ""
  run_hd_test "H-D6" "mutation_class_fixture_missing"    "$HD_FIXTURE_DIR/round-checker-h-d-6.jsonl" "remove_fixture"
  run_hd_test "H-D7" "axis_10_guard_coverage_gap"        "$HD_FIXTURE_DIR/round-checker-h-d-7.jsonl" ""
  # H-E1..H-E4 — Phase-7 R-AT-C-04 axis-13.e runtime-contract probe enforcement
  run_hd_test "H-E1" "axis_13_runtime_contract_blind_spot"        "$HD_FIXTURE_DIR/round-checker-h-e-1.jsonl" ""
  run_hd_test "H-E2" "axis_13_runtime_contract_drift_unreported"  "$HD_FIXTURE_DIR/round-checker-h-e-2.jsonl" ""
  run_hd_test "H-E3" "PASS"                                       "$HD_FIXTURE_DIR/round-checker-h-e-3.jsonl" ""
  run_hd_test "H-E4" "PASS"                                       "$HD_FIXTURE_DIR/round-checker-h-e-4.jsonl" ""
  # H-F1..H-F3 — Phase-7 R-DH-P7-01 axis-13.c source-literal carve-out enforcement
  run_hd_test "H-F1" "axis_13_source_literal_scan_blind_spot"     "$HD_FIXTURE_DIR/round-checker-h-f-1.jsonl" ""
  run_hd_test "H-F2" "axis_13_source_literal_bypass_unreported"   "$HD_FIXTURE_DIR/round-checker-h-f-2.jsonl" ""
  run_hd_test "H-F3" "PASS"                                       "$HD_FIXTURE_DIR/round-checker-h-f-3.jsonl" ""
else
  skip "H-D0..H-D7 / H-E1..H-E4: mutation-class-probes.json fixture missing (R-AT-C-02 not installed)"
fi

# ----- H-G Phase-8 R-P8-A: shared input-extraction helper _hook-input.sh --
# Closes F-001 family (stdin-envelope-bypass) by providing canonical
# argv→stdin→empty fallback chain. Reference design:
# audit-trail-review/PHASE-8-R-P8-A-DESIGN-R2.md
if [ -f "$HOOKS_DIR/_hook-input.sh" ]; then
  # H-G0: helper file present
  if [ -f "$HOOKS_DIR/_hook-input.sh" ]; then
    ok "H-G0: _hook-input.sh present at \$HOOKS_DIR"
  else
    nope "H-G0: _hook-input.sh missing"
  fi
  # H-G1: sourcing exposes 4 public functions
  HG1_FN_COUNT=$( (source "$HOOKS_DIR/_hook-input.sh" 2>/dev/null </dev/null
    for fn in apex_hook_input_command apex_hook_input_filepath apex_hook_input_tool_name apex_hook_input_raw; do
      if [ "$(type -t "$fn" 2>/dev/null)" = "function" ]; then echo "ok"; fi
    done) | wc -l | tr -d ' ' )
  if [ "$HG1_FN_COUNT" = "4" ]; then
    ok "H-G1: sourcing helper exposes 4 public functions"
  else
    nope "H-G1: expected 4 public functions, got $HG1_FN_COUNT"
  fi
  # H-G2: helper does NOT execute standalone (no side effects, exit 0)
  HG2_OUT=$(bash "$HOOKS_DIR/_hook-input.sh" </dev/null 2>/dev/null)
  HG2_EXIT=$?
  if [ "$HG2_EXIT" = "0" ] && [ -z "$HG2_OUT" ]; then
    ok "H-G2: standalone invocation is no-op (exit 0, empty stdout)"
  else
    nope "H-G2: standalone invocation has side effects (exit=$HG2_EXIT, out='$HG2_OUT')"
  fi
  # H-G3: argv path — apex_hook_input_command "rm -rf /" echoes "rm -rf /"
  HG3_OUT=$( (source "$HOOKS_DIR/_hook-input.sh"; apex_hook_input_command "rm -rf /") </dev/null 2>/dev/null )
  if [ "$HG3_OUT" = "rm -rf /" ]; then
    ok "H-G3: argv path returns argv value"
  else
    nope "H-G3: argv path failed (got '$HG3_OUT')"
  fi
  # H-G4: empty stdin + no argv → empty
  HG4_OUT=$( (source "$HOOKS_DIR/_hook-input.sh"; apex_hook_input_command) </dev/null 2>/dev/null )
  if [ -z "$HG4_OUT" ]; then
    ok "H-G4: empty/empty input returns empty"
  else
    nope "H-G4: expected empty, got '$HG4_OUT'"
  fi
  # H-G5: malformed JSON stdin → empty
  HG5_OUT=$( (source "$HOOKS_DIR/_hook-input.sh"; apex_hook_input_command) <<<'not-json{' 2>/dev/null )
  if [ -z "$HG5_OUT" ]; then
    ok "H-G5: malformed JSON returns empty"
  else
    nope "H-G5: malformed JSON should return empty, got '$HG5_OUT'"
  fi
  # H-G6: stdin path — {"tool_input":{"command":"abc"}} → "abc"
  HG6_OUT=$( (source "$HOOKS_DIR/_hook-input.sh"; apex_hook_input_command) <<<'{"tool_input":{"command":"abc"}}' 2>/dev/null )
  if [ "$HG6_OUT" = "abc" ]; then
    ok "H-G6: stdin path returns extracted .tool_input.command"
  else
    nope "H-G6: stdin path failed (got '$HG6_OUT')"
  fi
  # H-G7: argv priority when both present
  HG7_OUT=$( (source "$HOOKS_DIR/_hook-input.sh"; apex_hook_input_command "FROM_ARGV") <<<'{"tool_input":{"command":"FROM_STDIN"}}' 2>/dev/null )
  if [ "$HG7_OUT" = "FROM_ARGV" ]; then
    ok "H-G7: argv-priority wins when both argv + stdin present"
  else
    nope "H-G7: argv-priority broken (got '$HG7_OUT')"
  fi
  # H-G8: multi-field via _raw (the documented pattern for hooks needing
  # both .tool_name AND .tool_input, e.g., test-deletion-guard)
  HG8_OUT=$( (source "$HOOKS_DIR/_hook-input.sh"
    PAYLOAD=$(apex_hook_input_raw)
    TN=$(echo "$PAYLOAD" | jq -r '.tool_name // empty' 2>/dev/null)
    CMD=$(echo "$PAYLOAD" | jq -r '.tool_input.command // empty' 2>/dev/null)
    echo "$TN:$CMD") <<<'{"tool_name":"Bash","tool_input":{"command":"ls"}}' 2>/dev/null )
  if [ "$HG8_OUT" = "Bash:ls" ]; then
    ok "H-G8: multi-field via _raw extracts tool_name + tool_input correctly"
  else
    nope "H-G8: multi-field _raw pattern failed (got '$HG8_OUT')"
  fi
  # H-G9: filepath extraction from stdin envelope
  HG9_OUT=$( (source "$HOOKS_DIR/_hook-input.sh"; apex_hook_input_filepath) <<<'{"tool_input":{"file_path":"/tmp/x.txt"}}' 2>/dev/null )
  if [ "$HG9_OUT" = "/tmp/x.txt" ]; then
    ok "H-G9: apex_hook_input_filepath extracts .tool_input.file_path"
  else
    nope "H-G9: filepath extraction failed (got '$HG9_OUT')"
  fi

  # H-G10..H-G14: Wave 1 (R-P8-C1..C5) per-hook helper-sourcing verification.
  # Verifies each broken Bash-matcher hook now sources _hook-input.sh.
  # Functional verification of argv_exit == stdin_exit parity is performed
  # at the end-to-end test layer (see test-fix-plan-emit.sh).
  for HG_PAIR in "H-G10:destructive-guard.sh" "H-G11:exfil-guard.sh" "H-G12:sequence-guard.sh" "H-G13:subagent-guard.sh" "H-G14:grader-search-guard.sh"; do
    HG_ID="${HG_PAIR%%:*}"
    HG_HOOK="${HG_PAIR#*:}"
    if grep -q "source.*_hook-input.sh" "$HOOKS_DIR/$HG_HOOK" 2>/dev/null; then
      ok "$HG_ID: $HG_HOOK sources _hook-input.sh"
    else
      nope "$HG_ID: $HG_HOOK missing _hook-input.sh source"
    fi
  done

  # H-G15: destructive-guard.sh argv+stdin parity probe (Wave 1 functional gate).
  # Confirms F-001 closure: argv_exit == stdin_exit for matched deny pattern.
  HG15_ARGV_EXIT=$( bash "$HOOKS_DIR/destructive-guard.sh" "rm -rf /" </dev/null >/dev/null 2>&1; echo $? )
  HG15_STDIN_EXIT=$( echo '{"tool_input":{"command":"rm -rf /"}}' | bash "$HOOKS_DIR/destructive-guard.sh" >/dev/null 2>&1; echo $? )
  if [ "$HG15_ARGV_EXIT" = "2" ] && [ "$HG15_STDIN_EXIT" = "2" ]; then
    ok "H-G15: destructive-guard.sh argv+stdin parity (both exit 2 on 'rm -rf /')"
  else
    nope "H-G15: parity broken (argv=$HG15_ARGV_EXIT, stdin=$HG15_STDIN_EXIT)"
  fi

  # H-G16: subagent-guard.sh argv+stdin parity probe.
  HG16_ARGV_EXIT=$( bash "$HOOKS_DIR/subagent-guard.sh" "rm -rf / --yes" </dev/null >/dev/null 2>&1; echo $? )
  HG16_STDIN_EXIT=$( echo '{"tool_input":{"command":"rm -rf / --yes"}}' | bash "$HOOKS_DIR/subagent-guard.sh" >/dev/null 2>&1; echo $? )
  if [ "$HG16_ARGV_EXIT" = "2" ] && [ "$HG16_STDIN_EXIT" = "2" ]; then
    ok "H-G16: subagent-guard.sh argv+stdin parity (both exit 2 on 'rm -rf / --yes')"
  else
    nope "H-G16: parity broken (argv=$HG16_ARGV_EXIT, stdin=$HG16_STDIN_EXIT)"
  fi

  # H-G17: grader-search-guard.sh argv+stdin parity probe.
  HG17_ARGV_EXIT=$( bash "$HOOKS_DIR/grader-search-guard.sh" "find tests -name expected" </dev/null >/dev/null 2>&1; echo $? )
  HG17_STDIN_EXIT=$( echo '{"tool_input":{"command":"find tests -name expected"}}' | bash "$HOOKS_DIR/grader-search-guard.sh" >/dev/null 2>&1; echo $? )
  if [ "$HG17_ARGV_EXIT" = "2" ] && [ "$HG17_STDIN_EXIT" = "2" ]; then
    ok "H-G17: grader-search-guard.sh argv+stdin parity (both exit 2 on grader search)"
  else
    nope "H-G17: parity broken (argv=$HG17_ARGV_EXIT, stdin=$HG17_STDIN_EXIT)"
  fi
else
  skip "H-G0..H-G17: _hook-input.sh helper not installed (R-P8-A not landed)"
fi

# ----- summary ------------------------------------------------------------
TOTAL=$((LOCAL_PASS + LOCAL_FAIL))
echo "── $LOCAL_PASS/$TOTAL passed (skipped: $LOCAL_SKIP)"
if [ "$LOCAL_FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
