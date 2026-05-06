#!/usr/bin/env bash
# Hook type: Library — Sourced (CLI: sqlite3 wrapper)
#
# _state-sqlite.sh — opt-in SQLite mirror for APEX state plane (R5-002).
#
# Purpose
#   Mirror .apex/STATE.json snapshots and event-log.jsonl events into
#   .apex/state.db when APEX_SQLITE_MIRROR=1 and the sqlite3 CLI is on
#   PATH. The mirror is a side-effect of state writes; it never blocks
#   the canonical JSON+JSONL writes. See framework/docs/STATE-PLANE.md
#   for the contract.
#
# Spec anchor
#   "State management היברידי. Markdown + JSONL + jq (with SQLite+FTS5
#   as future migration path …)."
#
# Subcommands
#   mirror [state-file] [event-log]
#       Snapshot the current STATE.json into state_snapshot and tail
#       new events from event-log.jsonl into events. Idempotent for
#       state_snapshot (upsert by ts); appends to events.
#   status
#       Print whether the mirror is enabled, whether sqlite3 is
#       available, and the row counts in state_snapshot and events.
#
# Activation
#   Mirror writes only happen when APEX_SQLITE_MIRROR=1. With the env
#   var unset, every entry point is a fast no-op (exit 0). With the
#   env var set but sqlite3 missing, the mirror prints a fail-loud
#   message to stderr and exits 0 (does not crash the host write).
#
# Fail-loud, never fail-silent: the mirror prints diagnostics to
# stderr; it never silently swallows errors. But it never returns
# non-zero into the host write path — the host JSON+JSONL writes are
# canonical and must not be aborted by mirror trouble.

set -u

_apex_sqlite_db() {
  local state_file="${1:-.apex/STATE.json}"
  local state_dir
  state_dir=$(dirname "$state_file")
  printf '%s/state.db' "$state_dir"
}

_apex_sqlite_init() {
  local db="$1"
  sqlite3 "$db" <<'SQL' 2>/dev/null || return 1
CREATE TABLE IF NOT EXISTS state_snapshot (
  ts        TEXT PRIMARY KEY,
  json_blob TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS events (
  ts      TEXT NOT NULL,
  type    TEXT,
  agent   TEXT,
  payload TEXT
);
CREATE VIRTUAL TABLE IF NOT EXISTS events_fts
  USING fts5(payload, content='events', content_rowid='rowid');
SQL
}

# _state_sqlite_mirror — main side-effect entry point.
# Args: $1 = state-file path (default .apex/STATE.json)
#       $2 = event-log path (default sibling event-log.jsonl)
# Returns 0 always (never blocks host). Prints fail-loud diagnostics.
_state_sqlite_mirror() {
  # Gate: only fire when explicitly enabled.
  if [ "${APEX_SQLITE_MIRROR:-}" != "1" ]; then
    return 0
  fi

  local state_file="${1:-.apex/STATE.json}"
  local state_dir
  state_dir=$(dirname "$state_file")
  local event_log="${2:-${state_dir}/event-log.jsonl}"

  if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "⚠️ APEX SQLite mirror requested (APEX_SQLITE_MIRROR=1) but sqlite3 CLI not on PATH — mirror disabled for this write. State write itself unaffected." >&2
    return 0
  fi

  if [ ! -f "$state_file" ]; then
    # Nothing to mirror yet (initial-write race). Not an error.
    return 0
  fi

  local db
  db=$(_apex_sqlite_db "$state_file")

  if ! _apex_sqlite_init "$db"; then
    echo "⚠️ APEX SQLite mirror: could not initialize $db — mirror skipped." >&2
    return 0
  fi

  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date +%Y-%m-%dT%H:%M:%SZ)
  local blob
  blob=$(cat "$state_file" 2>/dev/null) || return 0

  # Upsert STATE.json snapshot at this ts. Escape single quotes for SQL.
  local esc_blob
  esc_blob=$(printf '%s' "$blob" | sed "s/'/''/g")
  if ! sqlite3 "$db" "INSERT OR REPLACE INTO state_snapshot(ts, json_blob) VALUES ('$ts', '$esc_blob');" 2>/dev/null; then
    echo "⚠️ APEX SQLite mirror: state_snapshot upsert failed at $ts." >&2
    return 0
  fi

  # Append the most recent event-log.jsonl line, if any.
  if [ -f "$event_log" ]; then
    local last_event
    last_event=$(tail -n 1 "$event_log" 2>/dev/null)
    if [ -n "$last_event" ]; then
      local e_ts e_type e_agent e_payload
      e_ts=$(printf '%s' "$last_event" | jq -r '.ts // empty' 2>/dev/null)
      e_type=$(printf '%s' "$last_event" | jq -r '.type // empty' 2>/dev/null)
      e_agent=$(printf '%s' "$last_event" | jq -r '.agent // .source // empty' 2>/dev/null)
      e_payload=$(printf '%s' "$last_event" | sed "s/'/''/g")
      [ -z "$e_ts" ] && e_ts="$ts"
      sqlite3 "$db" "INSERT INTO events(ts, type, agent, payload) VALUES ('$e_ts', '$e_type', '$e_agent', '$e_payload');" 2>/dev/null || true
      sqlite3 "$db" "INSERT INTO events_fts(rowid, payload) SELECT rowid, payload FROM events ORDER BY rowid DESC LIMIT 1;" 2>/dev/null || true
    fi
  fi

  return 0
}

_state_sqlite_status() {
  local state_file="${1:-.apex/STATE.json}"
  local db
  db=$(_apex_sqlite_db "$state_file")
  echo "APEX_SQLITE_MIRROR=${APEX_SQLITE_MIRROR:-(unset)}"
  if command -v sqlite3 >/dev/null 2>&1; then
    echo "sqlite3 CLI: present"
  else
    echo "sqlite3 CLI: missing"
  fi
  if [ -f "$db" ]; then
    local snap_count event_count
    snap_count=$(sqlite3 "$db" "SELECT COUNT(*) FROM state_snapshot;" 2>/dev/null || echo "?")
    event_count=$(sqlite3 "$db" "SELECT COUNT(*) FROM events;" 2>/dev/null || echo "?")
    echo "state.db: $db"
    echo "state_snapshot rows: $snap_count"
    echo "events rows:         $event_count"
  else
    echo "state.db: (not yet created at $db)"
  fi
}

# CLI surface — allows ad-hoc invocation:
#   bash framework/hooks/_state-sqlite.sh mirror [state-file] [event-log]
#   bash framework/hooks/_state-sqlite.sh status [state-file]
# When sourced (BASH_SOURCE != $0) the functions are exported and no
# CLI dispatch fires.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-}" in
    mirror)
      shift
      _state_sqlite_mirror "$@"
      ;;
    status)
      shift
      _state_sqlite_status "$@"
      ;;
    *)
      echo "Usage: _state-sqlite.sh {mirror|status} [state-file] [event-log]" >&2
      exit 1
      ;;
  esac
fi
