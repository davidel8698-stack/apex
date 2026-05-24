#!/usr/bin/env bash
# pre-subagent-start.sh — Campaign B B2.1 (GAP-1 closure).
#
# Hook type: Auto-PreToolUse (matcher Agent — i.e. the Task tool).
#
# Purpose
#   Emit a `subagent_start` boundary event into `.apex/event-log.jsonl`
#   and stamp the synthesized `agent_id` into
#   `.apex/in-flight-subagents.jsonl` so downstream tool-event-logger
#   PostToolUse calls can attribute child tool calls to the correct
#   sub-agent — the structural fix for the F-204-013 audit-honesty
#   regression (Campaign A's narrow CR-04 is upgraded to Campaign B's
#   universal coverage via this registry).
#
# Spec anchor
#   audit-trail-review/EXPERIMENT-PROTOCOL.md §6.1 (frozen 2026-05-24).
#   Closes AC-1 (binding hard-FAIL per §12.2). Paired with the
#   extension to subagent-stop.sh (boundary emission + denormalised
#   transcript write).
#
# Synthesized agent_id format (frozen, §6.1.1)
#   subagent-<agent_name>-<round_tag>-<sha1_prefix_8>
#
#   sha1 input: "<ts>|<tool_input_prompt_first_200_chars>"
#   round_tag:  STATE.self_heal.current_round, else STATE.current_phase,
#               else NOROUND-<unix_ts>
#
# Concurrency note (§6.1.3)
#   Two Task() invocations in parallel produce two distinct subagent_start
#   events with distinct agent_id suffixes. Disambiguation of child
#   tool_call events to the correct parent sub-agent is single-sub-agent-
#   at-a-time best-effort: tool-event-logger.sh stamps the most-recent
#   `in_flight` registry entry's agent_id. Concurrent sub-agents share
#   stamping — documented limitation; reserved as Phase-7 R-AT-P7-01.
#
# Three-place contract
#   1. this file (with the `# Hook type: Auto-PreToolUse (matcher Agent)` header)
#   2. framework/settings.json PreToolUse entry under matcher: "Agent"
#   3. framework/HOOK-CLASSIFICATION.md Auto-PreToolUse table row
#
# Exit codes
#   0 always — fire-and-forget; never blocks Task() invocation. (A
#   blocking exit would silence sub-agent dispatch on hook errors, the
#   opposite of the audit-trail invariant.)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Hard dependencies — without jq the registry update is not reliable.
# Skip silently per the tool-event-logger.sh fail-loud-and-skip pattern;
# downstream subagent-stop.sh will see an empty registry and write a
# fallback transcript with `agent_id=null` so the trail isn't lost.
if ! command -v jq >/dev/null 2>&1; then
  echo "[pre-subagent-start] jq absent; skipping subagent_start boundary emit" >&2
  exit 0
fi

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_state-update.sh"

export APEX_HOOK_SOURCE="pre-subagent-start"

# Outside a git repo (Claude sessions without .apex/), silently no-op.
if ! command -v git >/dev/null 2>&1 || ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi
cd "$ROOT" || exit 0

# Read the PreToolUse stdin envelope. Empty stdin → CLI test path; silent
# no-op so unit tests of other hooks don't pull in subagent state.
if [ -t 0 ]; then
  exit 0
fi
STDIN_BUF=$(cat 2>/dev/null || true)
if [ -z "$STDIN_BUF" ]; then
  exit 0
fi

# Defensive: this hook fires for the Task tool only. The matcher in
# settings.json narrows by name, but if a future Claude Code version
# repurposes "Agent", filter on tool_name here too.
TN=$(printf '%s' "$STDIN_BUF" | jq -r '.tool_name // empty' 2>/dev/null || true)
case "$TN" in
  Task|Agent) ;;
  *) exit 0 ;;
esac

# Extract sub-agent metadata. The Task tool's tool_input carries
# subagent_type (the agent definition file basename) and prompt. Some
# Claude versions also include description and model overrides — we
# ignore those for the trail.
AGENT_NAME=$(printf '%s' "$STDIN_BUF" | jq -r '.tool_input.subagent_type // .tool_input.agent_name // "unknown"' 2>/dev/null | tr -d '\r')
PROMPT_RAW=$(printf '%s' "$STDIN_BUF" | jq -r '.tool_input.prompt // ""' 2>/dev/null)
SESSION_ID=$(printf '%s' "$STDIN_BUF" | jq -r '.session_id // ""' 2>/dev/null | tr -d '\r')

# Defensive: agent_name cannot be empty; use "unknown" so the agent_id
# is still grep-able rather than collapsing to a degenerate prefix.
[ -z "$AGENT_NAME" ] && AGENT_NAME="unknown"

# Round-tag resolution per §4.3:
#   1. STATE.self_heal.current_round
#   2. STATE.current_phase (covers non-self-heal Task() invocations)
#   3. NOROUND-<unix-ts> fallback (so the file-name is unambiguous)
ROUND_TAG=""
if [ -f .apex/STATE.json ]; then
  ROUND_TAG=$(jq -r '.self_heal.current_round // .current_round // .current_phase // empty' .apex/STATE.json 2>/dev/null | tr -d '\r')
fi
if [ -z "$ROUND_TAG" ]; then
  ROUND_TAG="NOROUND-$(date -u +%s 2>/dev/null || echo 0)"
fi
# Sanitize: round_tag becomes part of a filename; strip path-traversal
# vectors and shell metacharacters.
ROUND_TAG=$(printf '%s' "$ROUND_TAG" | tr -c 'A-Za-z0-9._-' '_' | head -c 64)

# Tool-input summary: first 200 chars of the prompt, role-marker-stripped
# (per §6.1.1). The role-marker scrub avoids re-injecting the canonical
# override-marker phrase into the audit trail — apex-prompt-guard.cjs
# would reject the line otherwise.
SUMMARY=$(printf '%s' "$PROMPT_RAW" | head -c 200 \
  | sed -E 's/\\<\\<(SYSTEM|USER|ASSISTANT|HUMAN|TOOL):?\\>\\>//gi' \
  | tr '\n' ' ' | tr -d '\r')

# Synthesize agent_id. The sha1 input combines ISO timestamp + the
# 200-char summary so re-runs produce reproducible IDs (debug aid) but
# concurrent same-prompt invocations still differ via the timestamp.
NOW_ISO=$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)
SHA_INPUT="${NOW_ISO}|${SUMMARY}"
SHA8=$(printf '%s' "$SHA_INPUT" | sha1sum 2>/dev/null | cut -c1-8)
[ -z "$SHA8" ] && SHA8=$(printf '%s' "${NOW_ISO}${RANDOM}" | md5sum 2>/dev/null | cut -c1-8)
[ -z "$SHA8" ] && SHA8="0000$(date +%s | tail -c 5)"

AGENT_NAME_SAN=$(printf '%s' "$AGENT_NAME" | tr -c 'A-Za-z0-9._-' '_' | head -c 64)
AGENT_ID="subagent-${AGENT_NAME_SAN}-${ROUND_TAG}-${SHA8}"
PARENT_ID="host-${SESSION_ID:-unknown}"

# Ensure dirs exist.
mkdir -p .apex/subagent-transcripts .apex 2>/dev/null || true

# 1) Append to the in-flight registry. The registry is a JSONL file; one
# line per Task() invocation. tool-event-logger.sh reads the last
# `status=in_flight` line to stamp tool_call events with this agent_id.
REG=".apex/in-flight-subagents.jsonl"
jq -nc \
  --arg id "$AGENT_ID" --arg name "$AGENT_NAME" --arg parent "$PARENT_ID" \
  --arg round "$ROUND_TAG" --arg ts "$NOW_ISO" --arg summary "$SUMMARY" \
  '{agent_id:$id, agent_name:$name, parent_agent_id:$parent, round_tag:$round, started_at:$ts, status:"in_flight", tool_input_summary:$summary}' \
  >> "$REG" 2>/dev/null || true

# 2) Emit the subagent_start boundary event.
_emit_apex_event "subagent_start" .apex \
  agent_name "$AGENT_NAME" \
  agent_id "$AGENT_ID" \
  parent_agent_id "$PARENT_ID" \
  round_tag "$ROUND_TAG" \
  tool_input_summary "$SUMMARY"

# Never block — sub-agent dispatch must proceed even if logging fails.
exit 0
