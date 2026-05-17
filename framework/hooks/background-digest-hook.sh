#!/usr/bin/env bash
# background-digest-hook.sh — M10 MINOR digest emitter (Phase 12.06).
#
# Hook type: Command-Invoked (fired by /apex:next every 45 min via the
# soft-rotation trigger, OR by /apex:status when the user explicitly
# requests a digest).
#
# Purpose
#   MINOR events in event-log.jsonl are silent by design. This hook
#   periodically reaps them and emits a compact human-readable
#   digest: top-5 most-frequent (hook, what) pairs since the last
#   digest, plus total counts per hook.
#
# Spec anchors
#   apex-spec.md — `היכולות הנדרשות` (alert-fatigue mitigation).
#   .apex/phases/12-apex-evolution-v8/PLAN.md task 12.06 §§5-6.
#   R5 §7 F5 (alert fatigue research).
#
# Usage
#   bash framework/hooks/background-digest-hook.sh [--since <ISO-8601>] [--limit N]
#
# Options
#   --since   Only digest events newer than this RFC 3339 timestamp.
#             Default: last value of STATE.severity.digest_state.last_digest_at,
#             or 45 minutes ago when STATE missing the field.
#   --limit   Max number of top-frequency rows to emit. Default 5.
#
# Output
#   stdout: human-readable digest block.
#   Updates STATE.severity.digest_state.last_digest_at to now (RFC 3339).
#
# Exit codes
#   0 = digest emitted (zero or more MINOR events)
#   1 = invocation error
#   2 = jq required but missing

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVENT_LOG="${APEX_EVENT_LOG:-./.apex/event-log.jsonl}"
STATE_FILE="${APEX_STATE_FILE:-./.apex/STATE.json}"

SINCE_OVERRIDE=""
LIMIT=5

while [ $# -gt 0 ]; do
  case "$1" in
    --since)   shift; SINCE_OVERRIDE="${1:?}"; shift ;;
    --limit)   shift; LIMIT="${1:?}"; shift ;;
    -h|--help) sed -n '1,30p' "$0" | grep '^# ' | sed 's/^# //'; exit 0 ;;
    *) echo "🚫 unknown arg: $1" >&2; exit 1 ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "🚫 background-digest-hook: jq is required" >&2
  exit 2
fi

# Resolve `since`.
NOW_ISO="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
NOW_EPOCH="$(date -u +%s)"
SINCE_ISO=""
if [ -n "$SINCE_OVERRIDE" ]; then
  SINCE_ISO="$SINCE_OVERRIDE"
elif [ -f "$STATE_FILE" ]; then
  SINCE_ISO="$(jq -r '.severity.digest_state.last_digest_at // ""' "$STATE_FILE" 2>/dev/null)"
fi
if [ -z "$SINCE_ISO" ] || [ "$SINCE_ISO" = "null" ]; then
  # Default: 45 min ago.
  SINCE_EPOCH=$(( NOW_EPOCH - 2700 ))
  SINCE_ISO="$(date -u -d "@$SINCE_EPOCH" +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u +'%Y-%m-%dT%H:%M:%SZ')"
fi

if [ ! -f "$EVENT_LOG" ]; then
  echo "📋 No event-log.jsonl found at $EVENT_LOG — nothing to digest."
  exit 0
fi

# Filter MINOR events since SINCE_ISO. Group by (hook, what). Emit top
# N most-frequent + total count.
SINCE_EPOCH="$(date -u -d "$SINCE_ISO" +%s 2>/dev/null || echo 0)"

# Use jq to filter + group. Pipe-friendly.
DIGEST_JSON=$(jq -c --argjson since "$SINCE_EPOCH" '
  select(.severity == "MINOR")
  | select((.ts | fromdateiso8601) > $since)
  | {hook: .hook, what: .what}
' "$EVENT_LOG" 2>/dev/null | jq -sc --argjson limit "$LIMIT" '
  group_by([.hook, .what])
  | map({hook: .[0].hook, what: .[0].what, count: length})
  | sort_by(-.count)
  | {top: .[0:$limit], total: (map(.count) | add // 0), unique: length}
' 2>/dev/null)

if [ -z "$DIGEST_JSON" ] || [ "$DIGEST_JSON" = "null" ]; then
  DIGEST_JSON='{"top":[],"total":0,"unique":0}'
fi

TOTAL=$(printf '%s' "$DIGEST_JSON" | jq -r '.total // 0')
UNIQUE=$(printf '%s' "$DIGEST_JSON" | jq -r '.unique // 0')

# Emit digest.
printf '📋 MINOR digest — since %s (%s events, %s unique patterns)\n' \
  "$SINCE_ISO" "$TOTAL" "$UNIQUE"
if [ "$TOTAL" = "0" ]; then
  printf '   (no MINOR events in window)\n'
else
  printf '   Top %s by frequency:\n' "$LIMIT"
  printf '%s' "$DIGEST_JSON" | jq -r '.top[] | "     \(.count)x  [\(.hook)]  \(.what)"'
fi

# Update STATE.severity.digest_state.last_digest_at.
if [ -f "$STATE_FILE" ]; then
  TMP="$(mktemp)"
  jq --arg now "$NOW_ISO" --argjson total "$TOTAL" '
    .severity = (.severity // {critical_budget_window: [], digest_state: {last_digest_at: null, pending_minor_count: 0}}) |
    .severity.digest_state.last_digest_at = $now |
    .severity.digest_state.pending_minor_count = 0
  ' "$STATE_FILE" > "$TMP" 2>/dev/null
  if [ -s "$TMP" ]; then
    mv "$TMP" "$STATE_FILE"
  else
    rm -f "$TMP"
  fi
fi

exit 0
