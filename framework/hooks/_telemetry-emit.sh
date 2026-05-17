#!/usr/bin/env bash
# _telemetry-emit.sh — M16.1 central telemetry writer (Phase 12.09).
#
# Hook type: library (sourcable) AND command-invoked CLI.
#   - Sourced contract:  `apex_telemetry_emit <event> [phase] [counters_json]`
#   - CLI contract:      `bash _telemetry-emit.sh <event> [phase] [counters_json]`
#
# Purpose
#   Central, opt-out-gated writer to `.apex/telemetry.jsonl`. Every line is
#   ONE JSON object, append-only. Anonymizes the project name and emits
#   only numeric counters — never paths, code, branch names, commit
#   messages, or user identity (per framework/docs/PRIVACY-POLICY.md).
#
# Opt-out (honored BEFORE any disk write — silent no-op, exit 0):
#   - Env var:  `APEX_TELEMETRY=off`
#   - Flag:     `~/.claude/telemetry-opt-out.flag` exists
#
# Schema (one JSON object per line, append-only):
#   {
#     "ts": "<ISO 8601 UTC>",
#     "event": "<string>",
#     "project_hash": "<8 hex chars — sha256(basename $PWD)[0:8]>",
#     "phase": "<string, optional>",
#     "counters": { ...numeric fields only... }
#   }
#
# Anonymization contract
#   - project_hash = sha256(basename "$PWD") truncated to first 8 hex chars.
#     Test: `grep <literal-project-basename> .apex/telemetry.jsonl` → 0 matches.
#   - No file paths, no commit messages, no user/branch names, no code.
#   - counters_json MUST contain numeric values only. The hook does not
#     parse counters_json semantically; the contract is on the caller.
#     If counters_json contains a path-shaped string (`/foo/bar`),
#     test-telemetry-anonymization.sh's "no slashes in counters" test
#     will FAIL — keeping authors honest.
#
# Local-only default — v0.1.x
#   No remote upload in this version. The `APEX_TELEMETRY_REMOTE=on` env
#   flag is documented in PRIVACY-POLICY.md as v1.0+ opt-in only. This
#   hook explicitly ignores it.
#
# Atomic append
#   Each line is built fully in memory and then appended in a single
#   `printf >> ...` call. POSIX guarantees writes to O_APPEND-opened
#   files are atomic for blocks ≤ PIPE_BUF (typically 4096 bytes on
#   Linux/macOS/Windows-git-bash). One JSON line of telemetry is well
#   under this limit, so concurrent emits cannot produce torn lines.
#   No flock (Windows / OneDrive compatibility — see _tokens-update.sh).
#
# Spec anchors
#   PLAN.md task 12.09 §5 (M16.1 _telemetry-emit.sh contract).
#   framework/docs/PRIVACY-POLICY.md (full data inventory + opt-out).
#   User Decision #3 (opt-out-from-start, promoted to P1).
#
# Exit codes
#   0 = ok (line written) OR opted-out (silent no-op).
#   1 = write failure (telemetry.jsonl unwritable, disk full, etc.).
#   2 = invocation error (missing event arg, no .apex/ in cwd).

set -u

# ── Sha-256 fallback chain (cross-platform: GNU coreutils, BSD, OpenSSL) ──
# Returns the first 8 hex chars of sha256(stdin). Used for project_hash.
_apex_telemetry_sha8() {
  local input="$1"
  local digest=""
  if command -v sha256sum >/dev/null 2>&1; then
    digest=$(printf '%s' "$input" | sha256sum 2>/dev/null | awk '{print $1}')
  elif command -v shasum >/dev/null 2>&1; then
    # BSD shasum (macOS) — `shasum -a 256`.
    digest=$(printf '%s' "$input" | shasum -a 256 2>/dev/null | awk '{print $1}')
  elif command -v openssl >/dev/null 2>&1; then
    digest=$(printf '%s' "$input" | openssl dgst -sha256 2>/dev/null | awk '{print $NF}')
  fi
  # Truncate to first 8 hex chars (anonymization contract).
  # If digest is empty (all 3 tools missing), emit a stable sentinel
  # `00000000` rather than the project name (defense-in-depth: never
  # leak the basename through a degraded path).
  if [ -z "$digest" ]; then
    printf '00000000'
  else
    printf '%s' "${digest:0:8}"
  fi
}

# apex_telemetry_emit <event> [phase] [counters_json]
#
# Args:
#   $1 — event name (required, free-form string e.g.,
#        "task_complete", "quality_drift", "rotation").
#   $2 — phase identifier (optional; omit or empty string for none).
#   $3 — counters_json (optional; defaults to `{}`). MUST be valid JSON
#        object with numeric values only (caller contract).
apex_telemetry_emit() {
  local event="${1:-}"
  local phase="${2:-}"
  local counters="${3:-{\}}"

  # ── Invocation guards ──
  if [ -z "$event" ]; then
    echo "🚫 _telemetry-emit: event name required" >&2
    return 2
  fi
  if [ ! -d ".apex" ]; then
    echo "🚫 _telemetry-emit: no .apex/ in cwd — nothing to write" >&2
    return 2
  fi

  # ── Opt-out gate (silent no-op) ──
  # Honored BEFORE any disk write. Defense-in-depth: two independent
  # opt-out paths so a user who sets either is honored. Spec: see
  # framework/docs/PRIVACY-POLICY.md "How to opt out".
  if [ "${APEX_TELEMETRY:-}" = "off" ]; then
    return 0
  fi
  if [ -f "$HOME/.claude/telemetry-opt-out.flag" ]; then
    return 0
  fi

  # ── Optional jq validation of counters_json ──
  # Caller contract is "numeric only" — we cannot enforce that semantically
  # without parsing the value space, but we CAN validate well-formedness
  # so a broken caller emits a clear error instead of corrupting the file.
  if command -v jq >/dev/null 2>&1; then
    if ! printf '%s' "$counters" | jq -e . >/dev/null 2>&1; then
      echo "🚫 _telemetry-emit: counters_json is not valid JSON" >&2
      return 2
    fi
  fi

  # ── Build the line ──
  local ts project_hash basename_pwd line
  ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date +'%Y-%m-%dT%H:%M:%SZ')"
  basename_pwd="$(basename "$PWD")"
  project_hash="$(_apex_telemetry_sha8 "$basename_pwd")"

  # Construct JSON. Use jq if available (handles quoting safely); fall
  # back to manual quoting otherwise (no jq → no quote-escaping needed
  # since event/phase are caller-controlled).
  if command -v jq >/dev/null 2>&1; then
    if [ -n "$phase" ]; then
      line=$(jq -nc \
        --arg ts "$ts" \
        --arg event "$event" \
        --arg project_hash "$project_hash" \
        --arg phase "$phase" \
        --argjson counters "$counters" \
        '{ts:$ts, event:$event, project_hash:$project_hash, phase:$phase, counters:$counters}' \
        2>/dev/null)
    else
      line=$(jq -nc \
        --arg ts "$ts" \
        --arg event "$event" \
        --arg project_hash "$project_hash" \
        --argjson counters "$counters" \
        '{ts:$ts, event:$event, project_hash:$project_hash, counters:$counters}' \
        2>/dev/null)
    fi
  else
    # jq absent — emit a hand-built JSON. event/phase must not contain
    # double quotes (caller contract). counters is passed through verbatim.
    if [ -n "$phase" ]; then
      line="{\"ts\":\"${ts}\",\"event\":\"${event}\",\"project_hash\":\"${project_hash}\",\"phase\":\"${phase}\",\"counters\":${counters}}"
    else
      line="{\"ts\":\"${ts}\",\"event\":\"${event}\",\"project_hash\":\"${project_hash}\",\"counters\":${counters}}"
    fi
  fi

  if [ -z "$line" ]; then
    echo "🚫 _telemetry-emit: failed to build JSON line" >&2
    return 1
  fi

  # ── Atomic append ──
  # Single printf >> open(O_APPEND) is atomic for lines ≤ PIPE_BUF.
  # One telemetry line is well under that limit, so concurrent emits
  # cannot tear (POSIX guarantee).
  if ! printf '%s\n' "$line" >> .apex/telemetry.jsonl 2>/dev/null; then
    echo "🚫 _telemetry-emit: write to .apex/telemetry.jsonl failed" >&2
    return 1
  fi

  return 0
}

# Allow invocation as `bash _telemetry-emit.sh <event> [phase] [counters_json]`
# for tests and command-invoked sites; when sourced (no $1), do nothing.
if [ "${BASH_SOURCE[0]:-}" = "${0:-}" ]; then
  apex_telemetry_emit "${1:-}" "${2:-}" "${3:-{\}}"
  exit $?
fi
