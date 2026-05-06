---
description: Recover from crash or stuck state.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## TECHNICAL LEVEL ADAPTATION
Read technical level from CLAUDE.md ## User Profile section.
Adapt recovery options display:
- non-programmer: explain each option in plain language, recommend the safest choice (option 3 or 5), hide internal details like "reflexion counter"
- junior: explain options briefly, highlight recommended choice
- senior/architect: show options as-is (current behavior)

## FIX_PLAN.md / RECOVERY_MENU.md AWARENESS [R5-005 → R5-014]
Before doing anything else: if `.apex/FIX_PLAN.md` exists, READ it and prepend
its `## Reason`, `## Context`, and `## Recommended commands` sections to the
user-facing menu below. FIX_PLAN.md is the canonical fix-plan format
(R5-014 generalized): every blocking guard (path-guard, destructive-guard,
workflow-guard, quarantine-guard, schema-drift, phantom-check, post-write,
circuit-breaker) writes it via the shared `framework/hooks/_fix-plan-emit.sh`
helper.

For backward compatibility with the W1 R5-005 contract, `.apex/RECOVERY_MENU.md`
remains as an alias filename — circuit-breaker.sh mirrors FIX_PLAN.md to
RECOVERY_MENU.md so callers that still read the legacy path continue to
work. When both files are present, prefer FIX_PLAN.md (newer format with
`## Recommended commands`). When only RECOVERY_MENU.md is present, read that.

The static menu (steps 1–3) is the fallback when neither file is present.

## RECONSTRUCT FROM EVENT LOG [R5-004]
If `.apex/STATE.json` is missing (corruption, accidental delete, fresh-clone-after-crash) AND `.apex/event-log.jsonl` exists:
  Offer the user a "Reconstruct from event log" option that runs `bash ~/.claude/hooks/state-rebuild.sh`. The hook is idempotent and fail-soft — if reconstruction is impossible, it exits 0 without writing a partial file. After it runs successfully, STATE.json reappears with at least `current_phase` and `decision_mode` populated from the event log; control then returns to the standard menu (steps 1–3 below).
  Spec anchor: "State derives from disk."

1. Check .apex/STATE.json.lock
2. No lock: "No crash. /apex:next to continue. Or /apex:resume for fresh session."
3. Lock exists, process dead:
   "Interrupted: $UNIT (attempt $ATTEMPT)
   (1) Retry from scratch (resets reflexion counter)
   (2) Retry with reflexion (keeps failure context)
   (3) Mark failed, skip to next unit
   (4) Mark manually complete
   (5) Revert to last phase tag and re-plan [שיפור 23]"
   Handle, update STATE, remove lock.

   ## DORA RECOVERY TRACKING [R-011]
   After successful recovery (options 1-4):
   If STATE.dora._last_failure_at is non-null:
     RECOVERY_HOURS = (now - STATE.dora._last_failure_at) in hours
     If STATE.dora.recovery_time_avg is null:
       STATE.dora.recovery_time_avg = RECOVERY_HOURS
     Else:
       STATE.dora.recovery_time_avg = (STATE.dora.recovery_time_avg + RECOVERY_HOURS) / 2
     STATE.dora._last_failure_at = null
     STATE.dora.last_updated = now
</context>