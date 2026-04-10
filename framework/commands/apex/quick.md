---
description: Execute small task without full planning.
---

<context>
Task from $ARGUMENTS.

## INPUT GUARD (The Guessing Entry — anti-pattern)
REQUIRED (both must be present, boolean checks only — no judgment):
  1. Target identifier: $ARGUMENTS contains ONE of — file path (has `/`), function name (has `()` or camelCase identifier), or module/component name (PascalCase or recognized prefix)
  2. Action described: $ARGUMENTS contains an action verb (`add`, `remove`, `extract`, `rename`, `refactor`, `fix`, `update`, `replace`, `create`, `validate`) AND a concrete object following it

If either missing:
  "❌ /apex:quick requires target + change.
   Examples:
     /apex:quick 'add email validation to src/auth/signup.ts'
     /apex:quick 'extract getUser logic into helpers/user.ts'
   Your input: '[$ARGUMENTS]' is missing: [list what is missing — 'target identifier', 'action verb', or both]"
  STOP. Do not invoke planner or executor.

Rationale: critic downstream evaluates against done_criteria derived from $ARGUMENTS. Ambiguous input produces ambiguous done_criteria, which lets phantom verification slip past. Fail-fast at entry is cheaper than partial-verdict recovery.

If > 30 minutes: warn + suggest /apex:next

Else:
1. TASK_ID="quick-$(date +%s)"
   # Dedicated directory for quick tasks — isolated from phase-specific tasks.
   # Neither pre-task-snapshot.sh nor generate-task-map.sh creates this directory,
   # so we create it explicitly before any hook writes a SUMMARY there.
   mkdir -p .apex/phases/quick/
2. bash ~/.claude/hooks/pre-task-snapshot.sh "$TASK_ID"
   If hook exit code == 2: snapshot verification failed (filesystem-level).
     STATE.snapshots.pre_task_stash is null. Prompt user:
     "🚫 Pre-task snapshot could not be verified — no rollback available.
      (1) Abort task   (2) Proceed without snapshot (risk: no rollback)"
     If (1): STOP. If (2): log warning to SESSION-LOG.md, continue.
   Else (exit 0): proceed.
3. bash ~/.claude/hooks/generate-task-map.sh "$TASK_ID" [שיפור 11]
4. Read SPEC.md, DECISIONS.md, TASK_MAP.md
5. Determine specialist needed
6. Build context using CONTEXT_BUDGET.json limits [שיפור 19]
7. Task("[agent]", "Execute: [$ARGUMENTS]. Context in SPEC, DECISIONS, TASK_MAP.")
8. Task("critic", "Review: [$ARGUMENTS]. Read git diff HEAD~1. Diff-based review.") [שיפור 25]
9. bash ~/.claude/hooks/phantom-check.sh .apex/phases/quick/${TASK_ID}-SUMMARY.md [שיפור 17]
10. Update learnings if notable
11. Update STATE.json.tokens [שיפור 20]
</context>