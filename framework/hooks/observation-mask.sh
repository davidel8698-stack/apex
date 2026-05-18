#!/usr/bin/env bash
# Hook type: Stop + soft-rotation (auto-wired via settings.json Stop matcher
# and explicit invocation from pre-compact.sh). Currently invoked via
# pre-compact.sh fall-through chain only — see HOOK-CLASSIFICATION.md row
# under "Command-Invoked / Event-Triggered".
#
# R13-002 (F-302): Observation masking — extractive deletion of stale tool
# outputs from the executor transcript (working_memory zone Z3). Replaces
# the previous banner-only behavior with a real fail-safe masking pass.
#
# M17 (Phase 12.11): Anthropic Context Editing API integration. When the
# active adapter exposes the `apex_context_editing_supported` capability
# AND `context_editing.enabled == true` in settings.json, route through
# the server-side `clear_tool_uses_20250919` strategy (~84% reduction on
# heavy-tool agentic tasks). Otherwise fall back to the R13-002 bash path
# (~50% reduction, cross-platform). The two reductions are NOT additive —
# the API path supersedes bash; bash never runs when API succeeds. See
# framework/docs/CONTEXT-EDITING.md for the decision matrix.
#
# Spec anchors:
#   - "Honest scope over marketing scope."
#   - "Configuration declarative = theatre until code consumes it."
#   - "Re-read from disk after compaction." (R2-C040)
#   - Design-note: "Observation masking > LLM summarization (R2: JetBrains
#     study, 50% cost, equal quality)"
#   - PLAN.md task 12.11 (M17) — adapter-capability dispatch + fail-safe
#     fallback to bash on API failure.
#
# Contract:
#   - Fail-safe. If the transcript path cannot be resolved or is missing,
#     emit `observation.mask.fallback` to event-log and exit 0. The hook
#     NEVER blocks the pipeline; pre-compact.sh's fall-through to /compact
#     is the safety net.
#   - Idempotent. Already-masked blocks (`[masked: <tool> at <turn N>, ...`)
#     are skipped on subsequent invocations.
#   - CRLF-safe. Transcripts written on Windows hosts are normalized to LF
#     when matching tool-result blocks (re-using the R7-009 contract).
#   - Extractive only. Deletes stale tool-output bodies; replaces them with
#     a single-line stub. NEVER summarizes (R2-C034 vs R2-C035).
#   - Bypass switch. `STATE.context.observation_masking_active == false`
#     exits 0 with `observation.mask.bypassed`.
#   - API-path fail-safe (M17). If the API ping fails, MUST fall back to
#     bash. NEVER block. Emits a MAJOR severity event so the failure is
#     observable in /apex:status without breaking the masking guarantee.
#   - STATE.context.last_mask_at is updated REGARDLESS of which path ran.
#
# Window:
#   `working_memory.masking_window_turns` in CONTEXT_BUDGET.default.json
#   (default 3). Tool-result blocks older than the most recent N turns are
#   replaced.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_require-jq.sh"
require_jq

# shellcheck disable=SC1091
source "$SCRIPT_DIR/_state-update.sh"

export APEX_HOOK_SOURCE="${APEX_HOOK_SOURCE:-observation-mask}"

STATE_FILE=".apex/STATE.json"
EVENT_LOG=".apex/event-log.jsonl"
BUDGET_FILE="framework/CONTEXT_BUDGET.default.json"

# Fall back to the delivered copy under ~/.claude when running outside the
# repo (sync layout).
if [ ! -f "$BUDGET_FILE" ]; then
  if [ -f "$HOME/.claude/CONTEXT_BUDGET.default.json" ]; then
    BUDGET_FILE="$HOME/.claude/CONTEXT_BUDGET.default.json"
  fi
fi

_emit_event() {
  # _emit_event <event_type> [<key1> <val1> ...] — uses _emit_apex_event
  # from _state-update.sh; falls back to a manual line if helper missing.
  if command -v _emit_apex_event >/dev/null 2>&1 || declare -F _emit_apex_event >/dev/null 2>&1; then
    _emit_apex_event "$@" ".apex"
  else
    local ts_now
    ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","type":"%s","source":"observation-mask"}\n' \
      "$ts_now" "$1" >> "$EVENT_LOG" 2>/dev/null || true
  fi
}

# Bypass switch: STATE.context.observation_masking_active == false.
# Do NOT use jq's `// true` default — that operator treats `false` as
# falsy and would coerce the bypass switch back to `true`. The explicit
# `has(...)` check distinguishes "field missing" (default true) from
# "field is false" (bypass).
if [ -f "$STATE_FILE" ]; then
  ACTIVE=$(jq -r 'if (.context | has("observation_masking_active")) then .context.observation_masking_active else true end' "$STATE_FILE" 2>/dev/null | tr -d '\r')
  if [ "$ACTIVE" = "false" ]; then
    _emit_event observation.mask.bypassed
    exit 0
  fi
fi

# ── M17 (Phase 12.11): Anthropic Context Editing API dispatch ──
#
# Decision matrix (the only two gates; no force-override by design):
#
#   context_editing.enabled    capability flag    →  path
#   ─────────────────────────  ─────────────────  ──────
#   false (default)            any                →  bash (R13-002)
#   true                       absent / false     →  bash (R13-002)
#   true                       true               →  API
#                              (on API failure)   →  bash (fail-safe)
#
# Settings lookup:
#   1. `framework/settings.json` (source of truth in-repo).
#   2. `~/.claude/settings.json` (delivered copy).
# Either is acceptable; missing => default false.
#
# Capability lookup:
#   1. APEX_CONTEXT_EDITING_SUPPORTED env var (explicit override; takes
#      precedence — used by tests). Accepted values: "true" / "false".
#   2. framework/adapters/<active>/adapter.json `capabilities.apex_context_editing_supported`.
#   3. ~/.claude/adapters/<active>/adapter.json (delivered copy).
#   Missing => false (conservative; bash fallback).
#
# API contract (server-side):
#   The Anthropic context-management API (`anthropic-beta:
#   context-management-2025-06-27`, strategy `clear_tool_uses_20250919`)
#   is applied server-side by the adapter when capability is present.
#   observation-mask.sh does NOT call the API directly — Claude Code (or
#   the future adapter equivalent) owns the messages.create() invocation.
#   This hook's role under M17 is twofold:
#     (a) Mark the mask_path=api in STATE.context so the rest of APEX
#         (rotation-decide, /apex:status, telemetry) can see WHICH path
#         was taken.
#     (b) Run an optional connectivity ping (APEX_CONTEXT_EDITING_API_URL)
#         to confirm the adapter is wired correctly. If the ping fails,
#         emit MAJOR + fall back to bash.
#   When APEX_CONTEXT_EDITING_API_URL is unset (production default), no
#   network call happens — the capability flag is trusted as the
#   adapter's self-report.
_m17_settings_enabled() {
  local f val=""
  for f in "framework/settings.json" "$HOME/.claude/settings.json"; do
    [ -f "$f" ] || continue
    val=$(jq -r '.context_editing.enabled // false' "$f" 2>/dev/null | tr -d '\r')
    if [ "$val" = "true" ] || [ "$val" = "false" ]; then
      printf '%s\n' "$val"
      return 0
    fi
  done
  printf 'false\n'
}

_m17_capability_supported() {
  # Test-friendly explicit override wins.
  if [ -n "${APEX_CONTEXT_EDITING_SUPPORTED:-}" ]; then
    case "$APEX_CONTEXT_EDITING_SUPPORTED" in
      true)  printf 'true\n';  return 0 ;;
      false) printf 'false\n'; return 0 ;;
      *) ;; # fall through to adapter probe on unrecognized value
    esac
  fi
  # Adapter probe.
  local adapter="" probe="$SCRIPT_DIR/_adapter-detect.sh"
  if [ -f "$probe" ]; then
    adapter=$(bash "$probe" active 2>/dev/null | tr -d '\r' | head -1)
  fi
  [ -z "$adapter" ] && adapter="claude-code"
  local f val=""
  for f in \
    "framework/adapters/$adapter/adapter.json" \
    "$HOME/.claude/adapters/$adapter/adapter.json"; do
    [ -f "$f" ] || continue
    val=$(jq -r '.capabilities.apex_context_editing_supported // false' "$f" 2>/dev/null | tr -d '\r')
    if [ "$val" = "true" ]; then
      printf 'true\n'
      return 0
    fi
  done
  printf 'false\n'
}

_m17_emit_major() {
  # Emit a MAJOR severity event via the central M10 emitter. Falls back to
  # an inline event-log append if the helper is absent (defensive — the
  # M10 library should be present, but this hook MUST NOT block).
  local what="$1" why="$2" where="${3:-observation-mask.sh}"
  local emitter="$SCRIPT_DIR/_emit_apex_event.sh"
  if [ -f "$emitter" ]; then
    # shellcheck disable=SC1090
    source "$emitter" 2>/dev/null
    if declare -F apex_emit_event >/dev/null 2>&1; then
      apex_emit_event MAJOR observation-mask "$what" "$where" "$why" \
        "m17-api-fallback" '["bash framework/tests/test-context-editing.sh"]' \
        >/dev/null 2>&1 || true
      return 0
    fi
  fi
  local ts_now
  ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"ts":"%s","severity":"MAJOR","type":"observation.mask.api_fallback","source":"observation-mask","what":"%s","why":"%s"}\n' \
    "$ts_now" "$what" "$why" >> "$EVENT_LOG" 2>/dev/null || true
}

_m17_mark_state_path() {
  # Set STATE.context.mask_path and last_mask_at atomically. Fail-soft.
  local path_tag="$1"
  [ -f "$STATE_FILE" ] || return 0
  local NOW
  NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  _state_update \
    --arg now "$NOW" \
    --arg p "$path_tag" \
    '.context.last_mask_at = $now | .context.mask_path = $p' \
    "$STATE_FILE" >/dev/null 2>&1 || true
}

_M17_ENABLED=$(_m17_settings_enabled)
_M17_CAPABLE=$(_m17_capability_supported)

if [ "$_M17_ENABLED" = "true" ] && [ "$_M17_CAPABLE" = "true" ]; then
  # Take the API path. Optional connectivity ping; production default is
  # "no ping" — the capability flag is the adapter's self-report.
  _api_ok=1
  if [ -n "${APEX_CONTEXT_EDITING_API_URL:-}" ]; then
    if command -v curl >/dev/null 2>&1; then
      # Hard timeout (5s connect, 10s overall) so a hung endpoint cannot
      # block the pipeline. Capture exit code + HTTP status; treat
      # anything non-2xx OR empty body as failure.
      _resp=$(curl --silent --show-error \
                   --connect-timeout 5 \
                   --max-time 10 \
                   --write-out '\n%{http_code}\n' \
                   "$APEX_CONTEXT_EDITING_API_URL" 2>/dev/null) || _api_ok=0
      _status=$(printf '%s' "$_resp" | tail -1 | tr -d '\r')
      _body=$(printf '%s' "$_resp" | sed '$d')
      case "$_status" in
        2*) : ;;     # success
        *)  _api_ok=0 ;;
      esac
      if [ -z "$_body" ]; then
        _api_ok=0
      fi
    else
      # No curl on the host — degrade to bash (test platforms without curl
      # should fall back; this is the documented contract).
      _api_ok=0
    fi
  fi

  if [ "$_api_ok" = "1" ]; then
    _m17_mark_state_path "api"
    ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","type":"observation.mask.fired","source":"observation-mask","mask_path":"api","strategy":"clear_tool_uses_20250919"}\n' \
      "$ts_now" >> "$EVENT_LOG" 2>/dev/null || true
    exit 0
  fi

  # API failure: emit MAJOR and fall through to bash. The fallback is
  # the contract — under no circumstance does the pipeline block here.
  _m17_emit_major \
    "context-editing API ping failed — falling back to R13-002 bash masking" \
    "Adapter reports apex_context_editing_supported=true but APEX_CONTEXT_EDITING_API_URL ping failed (curl rc/status not 2xx, or empty body)"
fi
# Fall through to R13-002 bash path below. The state update at the end
# of the bash path will set mask_path="bash" via _m17_mark_state_path.

# Resolve window. Default 3.
WINDOW=3
if [ -f "$BUDGET_FILE" ]; then
  W=$(jq -r '.zones.working_memory.masking_window_turns // empty' "$BUDGET_FILE" 2>/dev/null | tr -d '\r')
  if [ -n "$W" ] && [ "$W" -ge 1 ] 2>/dev/null; then
    WINDOW="$W"
  fi
fi

# Resolve transcript path.
TRANSCRIPT=""
if [ -n "${APEX_TRANSCRIPT_PATH:-}" ] && [ -f "$APEX_TRANSCRIPT_PATH" ]; then
  TRANSCRIPT="$APEX_TRANSCRIPT_PATH"
elif [ -f "$EVENT_LOG" ]; then
  TRANSCRIPT="$EVENT_LOG"
fi

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  # Fail-safe path. Do NOT block the pipeline.
  ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"ts":"%s","type":"observation.mask.fallback","source":"observation-mask","reason":"transcript_unavailable"}\n' \
    "$ts_now" >> "$EVENT_LOG" 2>/dev/null || true
  exit 0
fi

# Identify tool-result blocks. Transcript line shape varies by adapter, so
# we support two recognized forms:
#
#   (a) JSONL event-log:
#       {"ts":"...","type":"tool_result","tool_name":"<name>","turn":N,"body":"..."}
#
#   (b) Markdown-style block fence:
#       <!-- tool_result: <name> turn=N -->
#       ...body...
#       <!-- /tool_result -->
#
# Older blocks are detected by `turn` (numeric, ascending) where the most
# recent N turns are preserved. Blocks already replaced by the masking stub
# are detected by a `"masked"` marker and left alone (idempotence).

# Compute the highest turn number in the transcript. CRLF-safe via tr -d '\r'.
HIGHEST_TURN=$(
  {
    grep -oE '"turn"[[:space:]]*:[[:space:]]*[0-9]+' "$TRANSCRIPT" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1
    grep -oE 'turn=[0-9]+' "$TRANSCRIPT" 2>/dev/null | grep -oE '[0-9]+' | sort -n | tail -1
  } | tr -d '\r' | sort -n | tail -1
)
HIGHEST_TURN="${HIGHEST_TURN:-0}"

if [ "$HIGHEST_TURN" -lt 1 ] 2>/dev/null; then
  # No turns found — either pre-activity or an adapter that does not emit
  # turn-tagged tool-result blocks. Treat as no-op success (NOT fallback;
  # the transcript exists and is well-formed for our purposes).
  exit 0
fi

CUTOFF=$((HIGHEST_TURN - WINDOW))
if [ "$CUTOFF" -lt 1 ]; then
  # Nothing older than the window — nothing to mask.
  exit 0
fi

# Mask blocks with turn <= CUTOFF, unless already masked. We rewrite to a
# temp file and atomically replace.
TMP="${TRANSCRIPT}.mask.$$"
MASKED_COUNT=0

# CRLF-safe read: strip \r before parsing.
while IFS= read -r line; do
  raw_line="$line"
  line_no_cr="${line%$'\r'}"
  # Already-masked stub line — leave untouched.
  if printf '%s' "$line_no_cr" | grep -qE '"type":[[:space:]]*"observation\.mask\.stub"|^\[masked:'; then
    printf '%s\n' "$raw_line" >> "$TMP"
    continue
  fi
  # Extract turn and tool_name if present.
  turn_val=$(printf '%s' "$line_no_cr" | grep -oE '"turn"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | head -1)
  if [ -z "$turn_val" ]; then
    turn_val=$(printf '%s' "$line_no_cr" | grep -oE 'turn=[0-9]+' | grep -oE '[0-9]+' | head -1)
  fi
  # Identify tool-result blocks only.
  is_tool_result=0
  if printf '%s' "$line_no_cr" | grep -qE '"type":[[:space:]]*"tool_result"|<!--[[:space:]]*tool_result'; then
    is_tool_result=1
  fi
  if [ "$is_tool_result" = "1" ] && [ -n "$turn_val" ] && [ "$turn_val" -le "$CUTOFF" ] 2>/dev/null; then
    tool_name=$(printf '%s' "$line_no_cr" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"tool_name"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/' | head -1)
    if [ -z "$tool_name" ]; then
      tool_name=$(printf '%s' "$line_no_cr" | grep -oE '<!--[[:space:]]*tool_result:[[:space:]]*[A-Za-z0-9_.-]+' | sed -E 's/^<!--[[:space:]]*tool_result:[[:space:]]*//' | head -1)
    fi
    tool_name="${tool_name:-unknown}"
    ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","type":"observation.mask.stub","tool_name":"%s","turn":%s,"body":"[masked: %s at turn %s, re-read from disk if needed]"}\n' \
      "$ts_now" "$tool_name" "$turn_val" "$tool_name" "$turn_val" >> "$TMP"
    MASKED_COUNT=$((MASKED_COUNT + 1))
  else
    printf '%s\n' "$raw_line" >> "$TMP"
  fi
done < "$TRANSCRIPT"

# Atomic replace.
if [ -f "$TMP" ]; then
  mv "$TMP" "$TRANSCRIPT" 2>/dev/null || {
    rm -f "$TMP"
    ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
    printf '{"ts":"%s","type":"observation.mask.fallback","source":"observation-mask","reason":"rename_failed"}\n' \
      "$ts_now" >> "$EVENT_LOG" 2>/dev/null || true
    exit 0
  }
fi

# Update STATE.context.last_mask_at via _state-update.sh (atomic, with
# event-log emission). Fail-soft. M17 also tags mask_path="bash" so the
# observable path is symmetric with the API branch.
if [ -f "$STATE_FILE" ]; then
  NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
  _state_update \
    --arg now "$NOW" \
    '.context.last_mask_at = $now | .context.mask_path = "bash"' \
    "$STATE_FILE" || true
fi

# Emit the fired event.
ts_now="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)"
printf '{"ts":"%s","type":"observation.mask.fired","source":"observation-mask","masked_count":%s,"masking_window":%s}\n' \
  "$ts_now" "$MASKED_COUNT" "$WINDOW" >> "$EVENT_LOG" 2>/dev/null || true

exit 0
