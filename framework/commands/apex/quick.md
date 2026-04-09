---
description: Execute small task without full planning.
---

<context>
Task from $ARGUMENTS.
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