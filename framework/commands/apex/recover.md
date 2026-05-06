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

## RECOVERY_MENU.md AWARENESS [R5-005]
Before doing anything else: if `.apex/RECOVERY_MENU.md` exists, READ it and prepend its `## Reason` and `## Options` sections to the user-facing menu below. RECOVERY_MENU.md is written by `circuit-breaker.sh` (and any other blocking guard that follows the R5-014 pattern) and contains contextual fix-plan options tailored to the trip cause. The static menu (steps 1–3) is the fallback when RECOVERY_MENU.md is absent.

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