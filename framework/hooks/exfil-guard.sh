#!/bin/bash
set -u
# R16-610 (F-610, IMP-005): exfil-guard.sh — stateful conditional elevated
# guards triggered when STATE.tool_failure_count >= 5.
#
# Hook type: PreToolUse (Bash). Stateful — reads STATE.json.
# Pairs with: _state-update.sh `_record_tool_failure` (PostToolUse side).
#
# Rationale (IMP-005)
#   Sustained tool-failure state is a known precursor to exfil attempts —
#   the executor flailing on errors may resort to side-channels. When the
#   failure count crosses the threshold, tighten the deny pattern set for
#   subsequent Bash calls. Below the threshold, this hook is a no-op.
#
# Elevated deny set (active when failure-count >= 5)
#   - DNS exfil via encoded subdomain: `dig <base64-looking>.<domain>`
#   - Non-standard port binds: `nc -l <high-port>`, `python -m http.server <high-port>`
#   - Base64-looking filenames: `> <[A-Za-z0-9+/]{16,}={0,2}>` write targets
#   - Side-channel /tmp/<encoded> writes
#
# Carve-outs
#   - APEX_EXFIL_GUARD=off — emergency bypass.
#   - APEX_ACTIVE_AGENT=test-architect — Wave 0 scan must read sample data.
#
# Exit codes
#   0 — clean (below threshold OR no elevated pattern matched).
#   2 — blocked (above threshold AND elevated pattern matched).

COMMAND="${1:-}"

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Emergency bypass and agent carve-out (cheap checks first).
if [ "${APEX_EXFIL_GUARD:-}" = "off" ]; then
  exit 0
fi
if [ "${APEX_ACTIVE_AGENT:-}" = "test-architect" ]; then
  exit 0
fi

# --- R16-614 (F-614, IMP-013): unconditional public-share deny ---------
# Public-share / paste-class exfil channels are blocked at all times, NOT
# gated by tool_failure_count (unlike the R16-610 elevated set below).
# Rationale: posting to gist / pastebin / transfer.sh is never a legitimate
# in-task action regardless of failure state; the failure-count gate exists
# only to widen the *advisory*-class exfil set. Public-share is a hard deny
# end-state. Inline domain list per planner decision (R-614 step §10:
# inline, keeps the hook self-contained; no cross-file dependency on
# security-patterns.json).
#
# Carve-outs honor the same emergency bypass + test-architect agent escape
# already declared at the top of this hook.
NORMALIZED_PUBLIC=$(echo "$COMMAND" | tr -s ' ' | sed 's/^ *//;s/ *$//')

_public_block() {
  echo "🛑 APEX EXFIL GUARD: BLOCKED (public-share deny — unconditional)" >&2
  echo "Command: $1" >&2
  echo "Matched: $2" >&2
  echo "" >&2
  echo "Public-share / paste / file-drop channels are denied at all times." >&2
  echo "See framework/docs/SECURITY-RUNTIME.md (IMP-013)." >&2
  if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
    # shellcheck source=/dev/null
    source "$(dirname "$0")/_fix-plan-emit.sh"
    if command -v emit_fix_plan >/dev/null 2>&1; then
      emit_fix_plan \
        "exfil-guard" \
        "Public-share / exfil channel was blocked (unconditional): $2" \
        "Blocked command: $1" \
        "/apex:forensics -- inspect the chain that led to the exfil attempt" \
        "/apex:rollback -- revert recent edits to the last green tag" \
        "/apex:recover -- reset and re-plan without the exfil-class action" \
        2>/dev/null || true
    fi
  fi
}

# Domain deny list (11) — public paste / file-drop / link-share endpoints
# that have no in-task legitimate use.
_PUBLIC_SHARE_DOMAINS='gist\.github\.com|pastebin\.com|hastebin\.com|paste\.ee|ix\.io|transfer\.sh|0x0\.st|file\.io|dropbox\.com/s/|we\.tl|wetransfer\.com'
if echo "$NORMALIZED_PUBLIC" | grep -qiE "$_PUBLIC_SHARE_DOMAINS" 2>/dev/null; then
  _public_block "$COMMAND" "public-share domain in command (gist/pastebin/transfer.sh/file.io/dropbox-share/wetransfer)"
  exit 2
fi

# Command shapes (4) — gh gist create, gist <upload, curl POST <public domain>,
# wget --post-data <public domain>. The curl/wget patterns intentionally
# co-require a public-share domain match elsewhere in the command (caught by
# the regex above when the URL is on the same line — which it always is for
# single-shot exfil).
if echo "$NORMALIZED_PUBLIC" | grep -qiE "\bgh\s+gist\s+create\b" 2>/dev/null; then
  _public_block "$COMMAND" "gh gist create — GitHub gist publish"
  exit 2
fi
if echo "$NORMALIZED_PUBLIC" | grep -qiE "\bgist\s+(<|--?file)" 2>/dev/null; then
  _public_block "$COMMAND" "gist CLI upload — gist <file or gist --file"
  exit 2
fi
if echo "$NORMALIZED_PUBLIC" | grep -qiE "\bcurl\b.*\s(-X\s+POST|--data|--data-binary|-F\b|--form\b)" 2>/dev/null \
   && echo "$NORMALIZED_PUBLIC" | grep -qiE "$_PUBLIC_SHARE_DOMAINS" 2>/dev/null; then
  _public_block "$COMMAND" "curl POST <public-share-domain> — exfil via POST upload"
  exit 2
fi
if echo "$NORMALIZED_PUBLIC" | grep -qiE "\bwget\b.*\s--post-data" 2>/dev/null \
   && echo "$NORMALIZED_PUBLIC" | grep -qiE "$_PUBLIC_SHARE_DOMAINS" 2>/dev/null; then
  _public_block "$COMMAND" "wget --post-data <public-share-domain> — exfil via POST upload"
  exit 2
fi
# --- end R16-614 -------------------------------------------------------

# Locate STATE.json. Walk up from $PWD looking for .apex/STATE.json.
STATE_FILE=""
search_dir="$PWD"
for _ in 1 2 3 4 5 6 7 8; do
  if [ -f "$search_dir/.apex/STATE.json" ]; then
    STATE_FILE="$search_dir/.apex/STATE.json"
    break
  fi
  parent="$(dirname "$search_dir")"
  [ "$parent" = "$search_dir" ] && break
  search_dir="$parent"
done

# No STATE.json (fresh checkout, no apex init) → fail-open (cannot read
# threshold). The other security hooks remain active; this layer is purely
# the stateful augmentation.
if [ -z "$STATE_FILE" ]; then
  exit 0
fi
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# Read tool_failure_count; default 0 when absent (additive field).
FAILURE_COUNT="$(jq -r '.tool_failure_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
case "$FAILURE_COUNT" in
  ''|*[!0-9]*) FAILURE_COUNT=0 ;;
esac

# Below the IMP-005 threshold (>=5) — no elevated check.
if [ "$FAILURE_COUNT" -lt 5 ]; then
  exit 0
fi

# Source the fix-plan emitter for structured failure output.
# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

block() {
  echo "🛑 APEX EXFIL GUARD: BLOCKED (elevated mode, failure_count=$FAILURE_COUNT)" >&2
  echo "Command: $1" >&2
  echo "Matched: $2" >&2
  echo "" >&2
  echo "Elevated guards are active because STATE.tool_failure_count >= 5." >&2
  echo "The executor has hit a sustained failure run; exfil-class patterns" >&2
  echo "are tightened to catch side-channel escape attempts." >&2
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "exfil-guard" \
      "Elevated exfil-guard fired (failure_count=$FAILURE_COUNT): $2" \
      "Blocked command: $1" \
      "/apex:forensics -- inspect the failure run that elevated this guard" \
      "/apex:recover -- reset failure_count to 0 once the underlying error is fixed" \
      2>/dev/null || true
  fi
}

# Normalize for matching.
NORMALIZED=$(echo "$COMMAND" | tr -s ' ' | sed 's/^ *//;s/ *$//')

# Elevated deny patterns — only evaluated when count >= 5.

# 1. DNS exfil via encoded subdomain (dig with a base64-looking label).
if echo "$NORMALIZED" | grep -qiE "\bdig\s+[A-Za-z0-9+/]{12,}={0,2}\.[A-Za-z0-9.-]+" 2>/dev/null; then
  block "$COMMAND" "dig <encoded>.<domain> — DNS exfil pattern (elevated, failure_count=$FAILURE_COUNT)"
  exit 2
fi

# 2. Non-standard port bind (nc listener on a high port, or python http server on a high port).
if echo "$NORMALIZED" | grep -qiE "\bnc\s+(-l|--listen)\s+(-[a-zA-Z]+\s+)?[0-9]{4,5}\b" 2>/dev/null; then
  port="$(echo "$NORMALIZED" | grep -oE '[0-9]{4,5}' | head -1)"
  if [ "${port:-0}" -ge 1024 ] && [ "${port:-0}" -le 65535 ]; then
    block "$COMMAND" "nc -l <high-port> — non-standard port bind (elevated, failure_count=$FAILURE_COUNT)"
    exit 2
  fi
fi
if echo "$NORMALIZED" | grep -qiE "python\d*\s+-m\s+http\.server\s+[0-9]{4,5}\b" 2>/dev/null; then
  block "$COMMAND" "python -m http.server <port> — non-standard listener (elevated, failure_count=$FAILURE_COUNT)"
  exit 2
fi

# 3. Base64-looking filename targets in writes.
if echo "$NORMALIZED" | grep -qE "(>|>>|tee)\s+[A-Za-z0-9+/]{16,}={0,2}(\s|$)" 2>/dev/null; then
  block "$COMMAND" "write to base64-looking filename — side-channel exfil (elevated, failure_count=$FAILURE_COUNT)"
  exit 2
fi

# 4. /tmp/<encoded> write paths.
if echo "$NORMALIZED" | grep -qE "(>|>>|tee)\s+/tmp/[A-Za-z0-9+/]{12,}={0,2}" 2>/dev/null; then
  block "$COMMAND" "write to /tmp/<encoded> — side-channel exfil (elevated, failure_count=$FAILURE_COUNT)"
  exit 2
fi

exit 0
