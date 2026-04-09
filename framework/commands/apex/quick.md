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
1. bash ~/.claude/hooks/generate-task-map.sh quick [שיפור 11]
2. Read SPEC.md, DECISIONS.md, TASK_MAP.md
3. Determine specialist needed
4. Build context using CONTEXT_BUDGET.json limits [שיפור 19]
5. Task("[agent]", "Execute: [$ARGUMENTS]. Context in SPEC, DECISIONS, TASK_MAP.")
6. Task("critic", "Review: [$ARGUMENTS]. Read git diff HEAD~1. Diff-based review.") [שיפור 25]
7. bash ~/.claude/hooks/phantom-check.sh [task]-SUMMARY.md [שיפור 17]
8. Update learnings if notable
9. Update STATE.json.tokens [שיפור 20]
</context>