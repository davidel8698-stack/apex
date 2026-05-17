#!/bin/bash
# sequence-guard.sh — R16-616 (F-616, IMP-016).
#
# Hook type: Auto-PreToolUse (Bash matcher).
#
# Purpose
#   Detect credential-search-after-permission-denied. Pattern:
#   1. Tool call returns unauthorized / 403 / 401 / denied → recorded by
#      _state-update.sh `_record_denied_error` into
#      STATE.recent_denied_error_window (FIFO, max 5).
#   2. Within the next 5 Bash calls, a `find . -name "*token*"`,
#      `grep -r api[_-]key`, `cat .env`, `cat ~/.aws/credentials`, or
#      `env | grep -i token` arrives. With the window non-empty, this
#      transitions from "may be legitimate" to "credential exfiltration
#      after explicit deny" — block with exit 2.
#
# Three-places contract
#   * hook file (this)
#   * framework/settings.json PreToolUse entry under matcher: "Bash"
#   * framework/HOOK-CLASSIFICATION.md row under Auto-PreToolUse
#
# Carve-outs
#   * APEX_ACTIVE_AGENT=test-architect — test-architect performs Wave 0
#     reconnaissance scans; do not block.
#   * .env.example / .env.sample — public templates, not secrets.
#
# Exit codes: 0=clean, 2=blocked.

set -u

COMMAND="${1:-}"
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Carve-out: test-architect agent
if [ "${APEX_ACTIVE_AGENT:-}" = "test-architect" ]; then
  exit 0
fi

# Read the rolling denied-error window. If absent or empty, this hook is
# inactive — pass through immediately.
STATE_FILE="${APEX_STATE_FILE:-.apex/STATE.json}"
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

WINDOW_LEN=$(jq -r '(.recent_denied_error_window // []) | length' "$STATE_FILE" 2>/dev/null || echo 0)
if [ -z "$WINDOW_LEN" ] || [ "$WINDOW_LEN" = "0" ] || [ "$WINDOW_LEN" = "null" ]; then
  exit 0
fi

# Tighten deny pattern set — credential-search primitives.
NORMALIZED=$(printf '%s' "$COMMAND" | tr -s '[:space:]' ' ' | sed 's/^ *//; s/ *$//')

# Whitelist legitimate templates first
if echo "$NORMALIZED" | grep -qE "\.env\.(example|sample|template)" 2>/dev/null; then
  exit 0
fi

BLOCK_REASON=""

if echo "$NORMALIZED" | grep -qiE "find[[:space:]]+.+-name[[:space:]]+[\"']?\*?(token|secret|key|credential|password|passwd)\*?[\"']?" 2>/dev/null; then
  BLOCK_REASON="find -name '*token/secret/key*' after denied error"
fi
if [ -z "$BLOCK_REASON" ] && echo "$NORMALIZED" | grep -qiE "grep[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*[[:space:]]+.*(api[_-]?key|secret|token|password|passwd|credential)" 2>/dev/null; then
  BLOCK_REASON="grep -r api_key/secret/token after denied error"
fi
if [ -z "$BLOCK_REASON" ] && echo "$NORMALIZED" | grep -qiE "(^|[[:space:]])(cat|less|more|head|tail)[[:space:]]+([^[:space:]]+/)?(\.env|\.envrc|credentials|id_rsa|id_ed25519|id_ecdsa)([[:space:]]|$)" 2>/dev/null; then
  BLOCK_REASON="cat/less/head .env / credentials after denied error"
fi
if [ -z "$BLOCK_REASON" ] && echo "$NORMALIZED" | grep -qiE "(^|[[:space:]])(cat|less|more|head|tail)[[:space:]]+.*(~/\.aws/credentials|~/\.ssh/|/etc/shadow|/etc/passwd)" 2>/dev/null; then
  BLOCK_REASON="cat ~/.aws/credentials / ~/.ssh / /etc/shadow after denied error"
fi
if [ -z "$BLOCK_REASON" ] && echo "$NORMALIZED" | grep -qiE "env[[:space:]]*\|[[:space:]]*grep[[:space:]]+-?[i]?[[:space:]]*(token|secret|key|api|password)" 2>/dev/null; then
  BLOCK_REASON="env | grep -i token/secret after denied error"
fi
if [ -z "$BLOCK_REASON" ] && echo "$NORMALIZED" | grep -qiE "printenv.*(token|secret|key|api|password)" 2>/dev/null; then
  BLOCK_REASON="printenv token/secret/key after denied error"
fi

if [ -n "$BLOCK_REASON" ]; then
  echo "APEX SEQUENCE GUARD: BLOCKED" >&2
  echo "Reason: credential-search after recent permission-denied error" >&2
  echo "Matched: $BLOCK_REASON" >&2
  echo "Window size: $WINDOW_LEN entries (max 5)" >&2
  echo "" >&2
  echo "This pattern matches credential-theft attempts that follow a denied"  >&2
  echo "API/file call. If this is a legitimate cleanup task, run from a"      >&2
  echo "manual terminal or wait for the window to age out (5 PreToolUse"      >&2
  echo "calls clear it)."                                                     >&2
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "sequence-guard" \
      "Credential-search command issued after a recent denied error." \
      "Matched: $BLOCK_REASON" \
      "/apex:forensics -- inspect the denied call that preceded this" \
      "/apex:rollback -- revert any partial state changes" 2>/dev/null || true
  fi
  exit 2
fi

exit 0
