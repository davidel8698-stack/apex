#!/bin/bash
# tool-event-logger.sh — R17-641 (F-641, IMP-019/028/035).
#
# Hook type: Auto-PostToolUse (matcher *) — single generic logger that
# emits one JSONL record per tool call to `.apex/event-log.jsonl` so
# critic.md anti-phantom STEPs 1.6 / 1.7 / 4.5 / 4.6 have ground truth
# to cross-reference against. Closes the IMP-019/028/035 producer half;
# the consumer prose was authored in R16 (R-619 / R-628 / R-635).
#
# Contract:
#   * exit 0 always — fire-and-forget; never blocks tool execution
#   * fail-loud-and-skip — one stderr line on jq absence, then continue
#   * NO STATE.json mutation — this hook is logging-only; the canonical
#     event-log lives at `.apex/event-log.jsonl`
#   * side effect: appends ONE JSONL line per invocation to
#     `.apex/event-log.jsonl` containing fields:
#       ts, type="tool_call", source="tool-event-logger",
#       tool_name, tool_input, tool_response, is_error
#
# Three-places contract for this new auto-wired hook:
#   1. this file (with the `# Hook type: Auto-PostToolUse (matcher *)` header)
#   2. framework/settings.json PostToolUse entry under matcher: "*"
#   3. framework/HOOK-CLASSIFICATION.md row under Auto-PostToolUse
#
# Critic consumers (do not touch — already authored):
#   * critic.md STEP 1.6 DATA-VALUE CROSS-REFERENCE (R-619)
#   * critic.md STEP 1.7 FABRICATED-TOOL-OUTPUT (R-619)
#   * critic.md STEP 4.5 DRY-RUN-CONTRADICTED (R-628)
#   * critic.md STEP 4.6 CITATION VERIFICATION (R-635)
# All four read `.apex/event-log.jsonl` substrings; this producer emits
# the substrings.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fail-loud-and-skip when jq absent — without jq we cannot produce
# a parseable JSONL line. Never block.
if ! command -v jq >/dev/null 2>&1; then
  echo "[tool-event-logger] jq not on PATH; skipping event-log emission" >&2
  exit 0
fi

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_state-update.sh"

export APEX_HOOK_SOURCE="tool-event-logger"

# Carve-out: outside a git repo (e.g. generic Claude sessions where the
# .apex/ tree may not exist), silently no-op. This matches the
# circuit-breaker.sh contract.
if ! command -v git >/dev/null 2>&1 || ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi
cd "$ROOT" || exit 0

# Read the PostToolUse stdin envelope. If stdin is empty or absent (CLI
# tests without a Claude Code wrapper), silently no-op.
if [ -t 0 ]; then
  exit 0
fi
STDIN_BUF=$(cat 2>/dev/null || true)
if [ -z "$STDIN_BUF" ]; then
  exit 0
fi

# Extract the four fields we need. `jq` may produce empty strings on
# missing slots — that is acceptable; the critic substring scan does
# not require every field to be present, only that the slot exists.
TN=$(printf '%s' "$STDIN_BUF" | jq -r '.tool_name // empty' 2>/dev/null || true)
TI_JSON=$(printf '%s' "$STDIN_BUF" | jq -c '.tool_input // {}' 2>/dev/null || echo '{}')
TR_JSON=$(printf '%s' "$STDIN_BUF" | jq -c '.tool_response // {}' 2>/dev/null || echo '{}')
IS_ERR=$(printf '%s' "$STDIN_BUF" | jq -r '(.tool_response.is_error // false) | tostring' 2>/dev/null || echo 'false')

if [ -z "$TN" ]; then
  # No tool_name -> not a recognizable tool envelope. Silently no-op.
  exit 0
fi

# Ensure the state dir exists; the helper appends to event-log.jsonl
# under .apex/ by default.
mkdir -p .apex 2>/dev/null || true

# Campaign B B2.1 (GAP-1 closure): stamp the most-recent in-flight
# sub-agent's agent_id onto this tool_call event so post-hoc
# subagent-transcripts/ filtering works. The registry file is written
# by pre-subagent-start.sh on Task() PreToolUse and updated to
# `status=stopped` by subagent-stop.sh on SubagentStop.
#
# Single-sub-agent-at-a-time best-effort (per EXPERIMENT-PROTOCOL.md
# §6.1.3 fallback). Concurrent Task() invocations share stamping;
# documented as Phase-7 R-AT-P7-01.
#
# Host attribution: when no sub-agent is in flight, stamp `host-<sid>`
# so every tool_call has a non-null `agent_id` — necessary for the
# audit-trail-coverage metric (§7.2) to compute over EVERY event.
AGENT_ID=""
if [ -f .apex/in-flight-subagents.jsonl ]; then
  AGENT_ID=$(awk '/"status":"in_flight"/' .apex/in-flight-subagents.jsonl 2>/dev/null \
    | tail -1 \
    | jq -r '.agent_id // empty' 2>/dev/null | tr -d '\r')
fi
if [ -z "$AGENT_ID" ]; then
  SID=$(printf '%s' "$STDIN_BUF" | jq -r '.session_id // ""' 2>/dev/null | tr -d '\r')
  AGENT_ID="host-${SID:-unknown}"
fi

# Emit the record via the ad-hoc helper. _emit_apex_event accepts
# arbitrary <key> <val> pairs after <event_type> <state_dir>; it writes
# one JSONL line per call to ${state_dir}/event-log.jsonl. STATE.json is
# NOT mutated — this hook is logging-only.
_emit_apex_event "tool_call" .apex \
  tool_name "$TN" \
  tool_input "$TI_JSON" \
  tool_response "$TR_JSON" \
  is_error "$IS_ERR" \
  agent_id "$AGENT_ID"

# Campaign B B2.4 (GAP-6 closure): emit a universal tool_input_hash
# event for EVERY tool call (not only Bash). circuit-breaker.sh's
# CHECK 4 ring buffer hashes the same canonical string but only fires
# on the Bash matcher; B2.4 surfaces the same signal across every tool
# so downstream consumers (round-checker TP-2, critic) can detect
# repeated identical Reads / Writes / Agent calls via the audit trail
# rather than relying on the safety-stop heuristic.
#
# Canonical-string contract (matches circuit-breaker.sh CHECK 4):
#   "<tool_name>|<jq -cS tool_input>"  (sorted keys for determinism)
#
# Truncation: the first 200 chars of the canonical string are hashed.
# Long tool_inputs (e.g. multi-MB Read payloads or Agent prompts) would
# otherwise produce per-call unique hashes that defeat collision
# detection. The truncation is documented in EXPERIMENT-PROTOCOL.md
# §13 (universal hashing risk-mitigation).
TI_CANON=$(printf '%s|%s' "$TN" "$TI_JSON" | head -c 200)
HASH=""
if command -v sha1sum >/dev/null 2>&1; then
  HASH=$(printf '%s' "$TI_CANON" | sha1sum | cut -c1-16)
elif command -v shasum >/dev/null 2>&1; then
  HASH=$(printf '%s' "$TI_CANON" | shasum -a 1 | cut -c1-16)
fi
if [ -n "$HASH" ]; then
  _emit_apex_event "tool_input_hash" .apex \
    tool_name "$TN" \
    hash_sha1 "$HASH" \
    truncated_at_chars "200" \
    agent_id "$AGENT_ID"
fi

exit 0
