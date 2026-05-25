#!/bin/bash
# _audit-probe-marker.sh — Campaign C TP-C2 (three-factor audit-probe carve-out).
#
# Sourced by: destructive-guard.sh, exfil-guard.sh, sequence-guard.sh, prompt-guard.sh.
# (apex-prompt-guard.cjs has parallel logic in node; security.cjs exports it.)
#
# Purpose
#   Allow legitimate framework-auditor procedural axis-10/axis-13 probes
#   through the host's PreToolUse guards, so the auditor can construct
#   bypass payloads in isolation without the host's own guards firing
#   first (which collapsed coverage to BLIND-SPOT in Campaign B; see
#   SGC-001 in audit-trail-review/trials/b5-heldout-t1.md).
#
# Three-factor protocol (frozen, FIX-DESIGN-C-R4.md §2)
#   F1 — Marker prefix:  COMMAND starts with
#        `__APEX_AUDIT_PROBE__:<nonce>:<agent_id> ...`
#   F2 — Exact agent_id lookup: the parsed agent_id resolves to an
#        in-flight registry entry with agent_name=framework-auditor.
#   F3 — Nonce match: the parsed nonce equals that entry's
#        audit_probe_nonce field.
#
# All three factors must succeed; otherwise the function returns 1 and
# the calling guard falls through to its existing pattern-matching path
# (fail-closed default).
#
# Calling convention
#   apex_check_audit_probe "$COMMAND"   # for argv-style guards (.sh hooks)
#
# Returns 0 if all three factors verified (caller should `exit 0`).
# Returns 1 otherwise (caller continues to its existing logic).
#
# Audit-trail integrity
#   Every successful allowance emits an `audit_probe_allowed` event to
#   `.apex/event-log.jsonl` with payload_sha1, agent_id, calling_hook.
#   Round-checker TP-2 §6.b verifies the event chain.
#   Event-log write failure is announced to stderr (fail-loud per
#   apex-spec.md §"עקרונות העבודה").

apex_check_audit_probe() {
  local cmd="$1"
  local marker_prefix="__APEX_AUDIT_PROBE__:"
  local registry=".apex/in-flight-subagents.jsonl"

  command -v jq >/dev/null 2>&1 || return 1
  [ -z "$cmd" ] && return 1

  # F1: marker-prefix check
  case "$cmd" in "${marker_prefix}"*) ;; *) return 1 ;; esac

  # Parse marker grammar: __APEX_AUDIT_PROBE__:<nonce>:<agent_id> <command>
  # CR-C-R3-03 closure: explicit colon-presence checks before extraction.
  local after_prefix="${cmd#$marker_prefix}"
  case "$after_prefix" in
    *:*) ;;  # second colon present
    *) return 1 ;;  # malformed marker — no second colon
  esac
  local nonce="${after_prefix%%:*}"
  local rest="${after_prefix#*:}"
  case "$rest" in
    ?*) ;;
    *) return 1 ;;  # nothing after second colon
  esac
  local agent_id="${rest%% *}"
  [ -z "$nonce" ] && return 1
  [ -z "$agent_id" ] && return 1
  [ "$nonce" = "$agent_id" ] && return 1  # defensive — degenerate same-string

  # F2 + F3: exact agent_id lookup + nonce match in same registry entry.
  [ -f "$registry" ] || return 1
  local match
  match=$(jq -c \
    --arg id "$agent_id" --arg nonce "$nonce" \
    'select(.agent_id==$id and .status=="in_flight" and .agent_name=="framework-auditor" and .audit_probe_nonce==$nonce)' \
    "$registry" 2>/dev/null | tail -n 1)
  [ -z "$match" ] && return 1

  # All three factors satisfied — emit audit_probe_allowed event.
  local payload_sha1 calling_hook payload_head now_iso
  payload_sha1=$(printf '%s' "$cmd" | sha1sum 2>/dev/null | awk '{print $1}')
  calling_hook="${BASH_SOURCE[1]##*/}"
  payload_head="${cmd:0:200}"
  now_iso=$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)

  local evt
  evt=$(jq -nc \
    --arg ts "$now_iso" \
    --arg agent_id "$agent_id" \
    --arg payload_sha1 "$payload_sha1" \
    --arg payload_head "$payload_head" \
    --arg hook "$calling_hook" \
    '{schema_version:"1", ts:$ts, type:"audit_probe_allowed", source:"audit-probe-marker", agent_id:$agent_id, agent_name:"framework-auditor", payload_sha1:$payload_sha1, payload_head:$payload_head, calling_hook:$hook}' 2>/dev/null)

  if [ -n "$evt" ]; then
    if ! printf '%s\n' "$evt" >> .apex/event-log.jsonl 2>/dev/null; then
      printf '[apex-audit-probe-marker] audit_probe_allowed event write failed at %s (calling_hook=%s)\n' "$now_iso" "$calling_hook" >&2
    fi
  fi

  return 0  # all three factors satisfied — allow
}
