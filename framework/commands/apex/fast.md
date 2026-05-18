---
description: Execute trivial task with zero ceremony. <5 min, single file, no logic change. Auto-detects micro tasks for opt-in batch mode (M15).
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Task from $ARGUMENTS.

## INPUT GUARD (The Guessing Entry — anti-pattern)
REQUIRED (both must be present, boolean checks only — no judgment):
  1. Explicit file path: $ARGUMENTS contains `/` OR starts with recognized prefix (`src/`, `./`, `lib/`, `app/`, `components/`, `hooks/`, `utils/`, `tests/`)
  2. Concrete verb + target: $ARGUMENTS contains one of (`rename`, `fix typo`, `update config`, `change text`, `add comment`) AND names a specific identifier

If either missing:
  "❌ /apex:fast requires BOTH:
     (1) explicit file path
     (2) exact change (verb + target)
   Example: /apex:fast 'rename getUserById → fetchUser in src/users.ts'
   Your input: '[$ARGUMENTS]' is missing: [list what is missing — 'file path', 'verb', or both]"
  STOP. Do not invoke executor.

Rationale: /apex:fast has no critic downstream. Ambiguous input here has no safety net — the executor will guess, commit, and git stash will only rescue from clear errors, not from silent mis-targeting.

---

## M15 BATCH MODE — AUTO-DETECT + ONCE-PER-SESSION MODAL

### Manual overrides (honor these before auto-detect)
Parse $ARGUMENTS for trailing flags:
  - `--batch`     → force batch_mode=enabled for this call (skip modal)
  - `--no-batch`  → force batch_mode=disabled for this call (skip modal)

Strip the flag from $ARGUMENTS before passing to executor. Manual overrides
NEVER persist to STATE — they apply only to the current /apex:fast invocation.

### Auto-detect rules (ALL must hold → task is "micro")
The four-rule heuristic, evaluated in order; first FAIL bumps out of micro:

  1. **File count.**  Declared `files <= 3` (parse from $ARGUMENTS — count slashes / explicit file mentions).
  2. **LOC budget.**  Declared `est_loc <= 30`. If $ARGUMENTS does not state estimated LOC, **conservative default: NOT micro** (bias).
  3. **Risk keywords.**  Read framework/docs/RISK-KEYWORDS.md (Class C + D sets). Case-insensitive substring match against $ARGUMENTS. ANY single match → NOT micro. The shared list is the single source of truth — same list M08 uses to assign task_class; this prevents micro auto-detect from contradicting task_class.
  4. **Task type.**  Inferred type must NOT be in {bug_fix, refactor} — those want a critic. Only `new_code` (or trivial config / text edits matching the INPUT GUARD verb list) qualifies for auto-detect.

If ALL four pass → `is_micro=true`. Otherwise → `is_micro=false` and run normal (non-batch) flow.

### Modal once-per-session
Read `.apex/STATE.json` → `session.batch_mode` (enum: unset | asked | enabled | disabled).

If `is_micro=true` AND `batch_mode IN {unset, asked}` AND no manual override:
  Render the plain-language modal exactly once and persist the user's choice.

#### MODAL TEXT — DEFAULT-ENTER = כן (DOCUMENTED OPPOSITE OF TRACK D)

```
⚡ זוהתה משימה קטנה (micro): [$ARGUMENTS]

האם להפעיל מצב מקובץ (Batch Mode) לסשן הזה?
במצב הזה משימות זריזות מצטברות ונסקרות יחד —
פחות הפסקות, פחות הסחות דעת.

  [k] כן, הפעל מצב מקובץ   (yes, enable batch) — default if you press Enter
  [l] לא, רץ רגיל          (no, run normally)

Choice [k/l, default=k]:
```

**LOAD-BEARING DESIGN DISTINCTION — DO NOT CHANGE.**
- /apex:fast micro modal:  default Enter = **כן** (k, proceed/enable).
- track-d-modal.sh Track D modal: default Enter = **לא** (l, stop).
- Rationale: Track D is irreversible — safe default is STOP.
  /apex:fast micro is reversible (git stash + scoped scope) — safe default is
  PROCEED/ENABLE so the user is not nagged every command. The opposite-default
  distinction is intentional and surfaces in track-d-modal.sh L151-L163 and
  here. Documentation also lives in framework/docs/RISK-KEYWORDS.md and the
  M15 spec section of PLAN.md.

State machine transitions (write back to `.apex/STATE.json` → `session.batch_mode`):
  - unset      → asked (modal rendered, awaiting choice)
  - asked + k  → enabled  (persist; modal never re-asked this session)
  - asked + l  → disabled (persist; modal never re-asked this session)
  - enabled / disabled → terminal for the session; no modal

On a fresh session id (`session.id` change), `batch_mode` resets to `unset` by
session-init — that is the only re-asking surface.

### Batch queue — `.apex/batch_queue.json`
When `batch_mode=enabled` (or `--batch` override) AND `is_micro=true`, append
the task to the FIFO before executing:

```json
{
  "session_id": "<from STATE.session.id>",
  "opened_at": "<ISO8601 of first append>",
  "last_surfaced_at": "<ISO8601 or null>",
  "tasks": [
    {
      "id": "<short hash of $ARGUMENTS>",
      "ts": "<ISO8601>",
      "files_changed": ["src/users.ts"],
      "loc_delta": 7,
      "diff_stat": "<git diff --stat output>",
      "commit_sha": "<sha or null if pre-commit>",
      "critic_flagged": false
    }
  ]
}
```

Append via atomic temp+mv (jq `tasks += [$entry]`); create file with empty
tasks[] if absent. Mirror the FIFO length to
`STATE.session.batched_tasks_count` for /apex:status display.

### Surface check — OR-gated thresholds
After each append, evaluate (first match wins):
  - **Critic flag.**  ANY task with `critic_flagged=true` → IMMEDIATE surface
    (bypass all thresholds). Async-critic events that arrive AFTER a task is
    committed also trigger this path the next time /apex:fast or /apex:next
    runs.
  - **Time.**  `now - max(last_surfaced_at, opened_at) >= 3600s` (1 hour).
  - **Count.**  `length(tasks) >= 5`.
  - **LOC.**   `sum(loc_delta) >= 50`.

When ANY threshold trips → render the batch surface (list of tasks, diff_stat
per task, any critic flags), update `last_surfaced_at = now`, and pass control
to the user for review/approval. The user can:
  - Accept all → leave queue intact (post-surface), reset count/loc accumulators.
  - Reject any → unwind via git revert per the flagged task.commit_sha.
  - Suspend batch → set `session.batch_mode=disabled` for the remainder of the session.

### Async batch-verifier specialist
On every append AND on every surface event, dispatch the batch-verifier
specialist (framework/agents/specialist/batch-verifier.md) **async** — the
user is not blocked waiting. The verifier classifies each batched task's
diff for semantic risk via RISK-KEYWORDS.md and sets task.critic_flagged
on hits. If a flag lands after the task is already committed, the
next /apex:fast or /apex:next surfaces it via the critic-flag bypass path.

---

## SAFETY NET ONLY — NO PLANNING, NO REVIEW
1. bash ~/.claude/hooks/pre-task-snapshot.sh fast
   → git stash for rollback

2. Read SPEC.md (if exists), DECISIONS.md (last 3 entries), CLAUDE.md (if exists)

3. Execute directly:
   ## RENDER: Mission Briefing (Section 10-B abbreviated — agent card + task goal only)
   Task("executor", "Execute this fast-task: [$ARGUMENTS].
   No formal planning. No RESULT.json needed. Just do it and commit.
   Follow CLAUDE.md conventions. Follow Named Failure Mode Prohibitions.")
   ## RENDER: Flight Recorder (Section 10-C abbreviated — agent + verdict)

4. Verify: git diff HEAD~1 --stat
   If zero changes → "⚠️ Nothing changed. Was this the right command?"
   If changes exist → "✅ Done. Changes: [diff stat]"

5. If batch_mode=enabled AND is_micro=true: append to .apex/batch_queue.json
   (per the schema above), dispatch batch-verifier async, then evaluate
   surface thresholds. Surface immediately when any threshold trips.

6. bash ~/.claude/hooks/session-log.sh "checkpoint" "פאסט: [$ARGUMENTS]"

7. Update STATE.json.tokens

NOTE: No critic review. No phantom check. No TDAD.
The git stash provides rollback safety.
Use ONLY for: rename, fix typo, update config, change display text, add comment.
If task involves logic, new files, or tests → use /apex:quick instead.

Batch mode (M15) layers semantic-risk classification asynchronously on top of
the same micro task list — it does not relax the INPUT GUARD or replace the
critic for non-micro tasks.
</context>
