# APEX STATE Plane — Today (JSON+JSONL) and the SQLite+FTS5 Migration Path

**Spec anchors:**
- "STATE.json + event-log.jsonl control plane (git-diff-able, jq-queryable)."
- "State management היברידי. Markdown + JSONL + jq (with SQLite+FTS5 as future migration path when query needs exceed jq — zero binary dependencies today, git-diff-able proof-of-process)."

**Purpose:** This document captures the contract between today's JSON state plane and the opt-in SQLite mirror that becomes available when query needs exceed `jq`. The contract makes the migration path real (a wired-but-opt-in mirror) without taking on the binary dependency on the default install path.

---

## The two planes

### 1. Today plane — JSON + JSONL (canonical, always on)

- `.apex/STATE.json` — atomic snapshot, the canonical state source-of-truth. All reads go here.
- `.apex/event-log.jsonl` — append-only structured event stream. One JSON object per line.
- All hooks that mutate state go through `framework/hooks/_state-update.sh` which writes STATE.json atomically and appends an event line to event-log.jsonl.
- All hooks that read state use `framework/hooks/_state-read.sh` (or jq directly).

This plane has zero binary dependencies beyond `jq` (already required by every APEX hook) and stays git-diff-able.

### 2. Migration plane — opt-in SQLite mirror (off by default)

- Activates only when the environment variable `APEX_SQLITE_MIRROR=1` is set.
- Implemented by `framework/hooks/_state-sqlite.sh` (Bash wrapper around the `sqlite3` CLI).
- Stores at `.apex/state.db` next to STATE.json.
- Mirrors STATE.json snapshots (`state_snapshot` table) and structured events (`events` table) and exposes an FTS5 virtual table (`events_fts`) over the event payload.
- Reads continue to flow through STATE.json. The mirror is write-side only in this round; an FTS5-backed search command is a follow-up.

**Why opt-in.** Spec mandate: "zero binary dependencies today." Many install paths (Windows Git Bash without scoop, minimal Linux containers) lack the `sqlite3` CLI. The default APEX install must keep working there. The mirror is therefore engaged by an explicit env-var flip, not by a config file or auto-detect.

---

## Activation contract

- **Default (`APEX_SQLITE_MIRROR` unset or empty):** `_state-update.sh` writes STATE.json, appends event-log.jsonl, and returns. Zero SQLite calls. Existing behavior — byte-identical to pre-mirror outputs.
- **Mirror requested (`APEX_SQLITE_MIRROR=1`) AND `sqlite3` present:** after every successful state mutation, `_state-update.sh` invokes `_state-sqlite.sh mirror` to copy the new STATE.json into `state_snapshot` and append the structured event into `events`. The FTS5 virtual table (`events_fts`) is populated by an explicit FTS5 INSERT after each event row insert; future migration to a SQLite trigger is a candidate when bulk-ingestion is wired (see F-013 / R6-013).
- **Mirror requested AND `sqlite3` absent:** `_state-sqlite.sh mirror` prints a fail-loud message ("`sqlite3` CLI not on PATH; APEX SQLite mirror disabled for this write") and returns 0. The state write itself does **not** crash. This is the spec's "fail-loud, never fail-silent" applied to the mirror — the mirror is informative, not catastrophic.

The state write is never blocked by mirror errors. The mirror is a side-effect, not a precondition.

---

## Schema

`framework/hooks/_state-sqlite.sh` creates the database lazily on the first `mirror` invocation:

```sql
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
```

`state_snapshot` is upsert-by-timestamp (latest STATE.json blob, indexed by mutation ts). `events` is append-only and mirrors the JSONL stream. `events_fts` is the FTS5 surface over the event payload.

---

## STATE.json schema field

`framework/schemas/STATE.schema.json` declares an optional `sqlite_mirror` object so that projects which engage the mirror can record bookkeeping. The field is optional — projects that do not enable the mirror omit it entirely.

```json
"sqlite_mirror": {
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "enabled":          { "type": "boolean" },
    "last_synced_at":   { "type": ["string", "null"], "format": "date-time" },
    "threshold_events": { "type": "integer", "minimum": 0 }
  }
}
```

`schema-drift.sh` validates the field shape when present, and tolerates absence (it is not a required key).

---

## Read surface — preservation contract

- `framework/hooks/_state-read.sh` and every read-path consumer continue to read from `.apex/STATE.json`. There is no `read-from-SQLite` path in this round.
- The event-log.jsonl format remains append-only and unchanged. It is the canonical event stream; the mirror is a read-optimization, not a replacement.

These preservation contracts are enforced by the do-not-touch zones in the R5-002 execution plan — `_state-read.sh` is untouched and STATE.json semantics are unchanged.

---

## Future work (out of scope for R5)

- An FTS5-backed `/apex:search` command that queries `events_fts` directly when the mirror is active.
- A threshold-driven auto-engage (e.g., "mirror engages once event-log.jsonl exceeds N events"), gated on the same opt-in flag plus `sqlite3` availability.
- Read-from-SQLite path for cross-session cold-cache reads.

These are deliberate non-goals for R5-002. The R5 commitment is: contract documented, mirror wired, opt-in, fail-loud-and-skip when the CLI is absent.
