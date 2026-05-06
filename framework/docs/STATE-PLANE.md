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

## Dual-emit contract (R6-004) — semantic events for canonical fields

`_state-update.sh` writes the canonical `state_mutation` event for every
successful jq update. In addition, when the `expr` argument matches one
of the canonical-field patterns it appends a **semantic event** at the
same timestamp:

| jq expression pattern (anchored) | Semantic event type | Field carried |
|----------------------------------|---------------------|---------------|
| `.current_phase = "<val>"`       | `phase_set`         | `current_phase` |
| `.decision_mode = "<val>"`       | `decision_mode_set` | `decision_mode` |
| `.complexity_level = <n>`        | `complexity_set`    | `complexity_level` |

The detection rule is intentionally conservative — only the
literal-assignment shape `.<field> = <value>` (with optional whitespace
around `=`) is matched. jq pipe-operator updates, conditional updates,
and computed expressions are **not** matched, so they remain
single-emit `state_mutation` events.

**Why dual-emit, not parse-on-rebuild?** `state-rebuild.sh` could in
principle parse `state_mutation.expr` strings, but jq expression syntax
is too rich to recover deterministically. Emitting a structured
semantic event at write time is the robust path. The `state_mutation`
event format remains byte-compatible (no schema change to the existing
event type); the semantic event is additive.

**Order semantics.** The rebuild contract is *last-wins* — the most
recent `phase_set` (etc.) determines the rebuilt field value. Multiple
emitters may legitimately set the same canonical field in one session.

**Consumers.**

- `state-rebuild.sh` already reads `phase_set` / `decision_mode_set` /
  `complexity_set` (its read pipeline pre-dates this contract).
  Dual-emit closes the production-side loop so the rebuild produces the
  actual session state, not the hardcoded defaults.
- `_state-sqlite.sh` (when the opt-in mirror is engaged) ingests every
  event-log line, so both the `state_mutation` event and any matching
  semantic event end up in the `events` table. R6-013 wires the
  watermark logic that ingests multi-event windows.

## Watermark-based ingestion (R6-013) — every event-log line, not every state-write

`_state-sqlite.sh mirror` ingests **every** event-log.jsonl line written
since the last mirror call, not just the most recent one. This is the
"events table mirrors the JSONL stream" contract from the spec, applied
honestly to the heterogeneous event traffic that production emits
(`state_mutation` from `_state-update.sh`, session-log lines from
`session-log.sh`, dream-cycle lines from `_dream-cycle-emit.sh`, plus
the R6-004 dual-emit semantic events that ride alongside canonical-field
state writes).

**Sidecar watermark.** Each `mirror` call reads `.apex/.sqlite-mirror.offset`
(line number of the last mirrored event-log line; default 0 on first
run — bootstrap case ingests the full log). It tails every line past
the offset, INSERTs each into `events` and `events_fts`, then writes the
new line count back to the sidecar.

**Why a line-number watermark, not a byte offset.** event-log.jsonl is
line-delimited; line numbers survive log rotation when the rotation
contract preserves line continuity. If log rotation is later wired with
a body-rewrite step, the watermark switches to event hash (flagged for a
future round; see NF-R6-P-005).

**Why not multi-emitter wiring.** The alternative is to wire
`_state_sqlite_mirror` into all three emitters so each fires the mirror.
That has lower latency but couples three hooks to the mirror — heavier
blast radius and a stronger preservation-contract obligation on every
emitter touch. The watermark approach decouples mirror frequency from
emitter frequency: the mirror catches up on its own schedule (after the
next state write or an explicit `bash _state-sqlite.sh mirror` call).

**Trigger-versus-explicit-INSERT note.** The `events_fts` virtual table
is populated by an explicit FTS5 INSERT after each `events` row insert
(see Activation contract above). When the watermark approach ingests a
multi-line window, this means N row inserts and N FTS5 inserts per
mirror call. A SQLite trigger (`AFTER INSERT ON events`) would produce
the same outcome with one ingestion path — that migration is the
candidate documented under R6-012 / F-013 follow-up; the explicit-INSERT
form is preserved here because the watermark logic emits per-row in a
shell loop rather than a bulk SQL INSERT.

**Idempotency.** Running `mirror` twice with no new lines is a no-op:
total_lines == offset → no INSERTs, watermark unchanged. External
truncation (rotation, manual edit) that shrinks the log below the
offset triggers a defensive reset to 0 and a re-ingestion of the full
log on the next call.

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
