# `owns_files` Population Contract — Single Source of Truth

**Spec anchor:** "One-file-one-owner im git worktree isolation" + "Read-
parallel, write-serial im Vertical Slices Enforcement."

**Owning agent:** `architect.md` (the agent that finalizes
`.apex/phases/<phase>/WAVE_MAP.json`).

**Consumer:** `framework/hooks/owner-guard.sh` (PreToolUse
Write|Edit) — reads `APEX_CURRENT_TASK_ID` + the active
WAVE_MAP and refuses any write whose target is not in the current
task's `owns_files` list.

**Why this doc exists:** R5-013 wired `owner-guard.sh` and added the
contract to `planner.md`. But `planner.md` does NOT emit
WAVE_MAP.json — `architect.md` does. R6-010 lifts the contract into
this single doc so both agents reference the same source of truth.
Future drift is single-edit.

---

## 1. What `owns_files` is

`owns_files` is a per-task array of repository-relative file paths
that the task is allowed to write within its wave.

```json
{
  "phase_id": "01",
  "waves": [
    {
      "wave_id": "1",
      "tasks": [
        {
          "task_id": "01-01",
          "owns_files": ["src/api/users.ts", "tests/api/users.test.ts"]
        },
        {
          "task_id": "01-02",
          "owns_files": ["src/api/orders.ts", "tests/api/orders.test.ts"]
        }
      ]
    }
  ]
}
```

When a task running with `APEX_CURRENT_TASK_ID=01-01` attempts to
write `src/api/orders.ts`, `owner-guard.sh` blocks the write
(exit 2) and emits a structured FIX_PLAN.md naming the boundary
violation. This is how the spec's "one-file-one-owner" invariant is
enforced at the tool-call layer.

---

## 2. How to populate it

For every task in every wave:

1. List every file the task will Write or Edit. Be exhaustive —
   missing entries are runtime blocks, not warnings.
2. Use repository-relative paths (no leading `./`, no absolute
   paths, no `~/` expansion).
3. Use forward slashes regardless of host OS — `owner-guard.sh`
   normalizes path separators internally.
4. Glob patterns are NOT supported in R6 — every path must be a
   literal file. (Glob support is a future round; record as a
   finding if a wave needs it.)
5. Read-only tasks (verify, audit, summarize, lint) MAY omit the
   field. The guard's fast-path exits 0 when no Write/Edit occurs.
6. Sole-task waves MAY set `owns_files: ["*"]` to opt out of
   gating entirely. Use sparingly — multi-task waves cannot opt
   out (it would defeat the invariant).

---

## 3. Owner-guard fast-path (advisory mode)

During the R5-013 transition window, `owner-guard.sh` operates in
advisory mode for missing fields:

- **Field present, target listed →** write proceeds (exit 0).
- **Field present, target NOT listed →** write blocked (exit 2),
  FIX_PLAN.md emitted naming `task_id`, attempted target, and the
  task's `owns_files` list.
- **Field absent (legacy WAVE_MAP) →** write proceeds (exit 0),
  but a one-line advisory is logged to
  `~/.claude/apex-learnings.md` so the gap surfaces in audits.

After the transition window closes (target: R7), the schema in
`framework/schemas/WAVE_MAP.schema.json` will require `owns_files`
on every task that performs writes. Advisory-pass becomes
schema-validation-fail at that point. Plan accordingly.

---

## 4. Examples

### Example A — multi-task parallel wave

Two tasks edit different files. Both are written by Wave 1.

```json
{
  "wave_id": "1",
  "tasks": [
    {"task_id": "01-01", "owns_files": ["src/auth/login.ts"]},
    {"task_id": "01-02", "owns_files": ["src/auth/logout.ts"]}
  ]
}
```

`owner-guard.sh` enforces the boundary: `01-01` cannot touch
`logout.ts`, `01-02` cannot touch `login.ts`.

### Example B — task touches multiple files

```json
{
  "task_id": "02-03",
  "owns_files": [
    "src/payment/stripe.ts",
    "src/payment/types.ts",
    "tests/payment/stripe.test.ts",
    "docs/api/payment.md"
  ]
}
```

All four paths must be listed. Adding a fifth file mid-task without
updating WAVE_MAP triggers a guard block.

### Example C — sole-task wave (opt out)

A solo wave (e.g., a rename or a sweep) sets `["*"]` to skip
gating:

```json
{
  "wave_id": "5",
  "tasks": [
    {"task_id": "05-01", "owns_files": ["*"]}
  ]
}
```

Use only when the wave intentionally has one owner across the whole
repo (e.g., a global rename).

### Example D — read-only task (field omitted)

```json
{
  "task_id": "03-01",
  "task_type": "verify"
}
```

No `owns_files` field. Guard fast-path exits 0 because no
Write/Edit occurs. Adding a Write to such a task without adding
the field triggers the advisory-pass legacy branch (and a
learnings-log entry); the architect should populate the field
when the task type changes.

### Example E — overlap is a planning error

If two tasks in the same wave both list `src/api/users.ts`, the
WAVE_MAP is malformed:

```json
{
  "wave_id": "1",
  "tasks": [
    {"task_id": "01-01", "owns_files": ["src/api/users.ts"]},
    {"task_id": "01-02", "owns_files": ["src/api/users.ts"]}
  ]
}
```

Resolution: split the wave (move one task to a later wave) or merge
the two tasks. Overlap within a wave defeats the
write-serial-within-a-file invariant.

---

## Cross-references

- `framework/agents/architect.md` STEP 2 — invokes this contract
  during WAVE_MAP.json finalization.
- `framework/agents/planner.md` ONE-FILE-ONE-OWNER section —
  references this contract for any planner-emitted wave-map
  artifact.
- `framework/hooks/owner-guard.sh` — the consumer; reads the
  field at PreToolUse Write|Edit.
- `framework/schemas/WAVE_MAP.schema.json` — schema declaration of
  the field (currently optional; planned mandatory in R7).
- F-010 (R6 audit finding) — the gap this contract closes.
- R5-013 (R5 closure) — the owner-guard wiring that depends on
  this contract being populated.
