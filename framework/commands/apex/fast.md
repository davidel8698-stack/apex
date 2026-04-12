---
description: Execute trivial task with zero ceremony. <5 min, single file, no logic change.
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

5. bash ~/.claude/hooks/session-log.sh "checkpoint" "פאסט: [$ARGUMENTS]"

6. Update STATE.json.tokens

NOTE: No critic review. No phantom check. No TDAD.
The git stash provides rollback safety.
Use ONLY for: rename, fix typo, update config, change display text, add comment.
If task involves logic, new files, or tests → use /apex:quick instead.
</context>
