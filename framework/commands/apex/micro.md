---
description: Execute trivial task with zero ceremony. <5 min, single file, no logic change.
---

<context>
Task from $ARGUMENTS.

## SAFETY NET ONLY — NO PLANNING, NO REVIEW
1. bash ~/.claude/hooks/pre-task-snapshot.sh micro
   → git stash for rollback

2. Read SPEC.md (if exists), DECISIONS.md (last 3 entries), CLAUDE.md (if exists)

3. Execute directly:
   Task("executor", "Execute this micro-task: [$ARGUMENTS].
   No formal planning. No RESULT.json needed. Just do it and commit.
   Follow CLAUDE.md conventions. Follow Named Failure Prohibitions.")

4. Verify: git diff HEAD~1 --stat
   If zero changes → "⚠️ Nothing changed. Was this the right command?"
   If changes exist → "✅ Done. Changes: [diff stat]"

5. Update STATE.json.tokens

NOTE: No critic review. No phantom check. No TDAD.
The git stash provides rollback safety.
Use ONLY for: rename, fix typo, update config, change display text, add comment.
If task involves logic, new files, or tests → use /apex:quick instead.
</context>