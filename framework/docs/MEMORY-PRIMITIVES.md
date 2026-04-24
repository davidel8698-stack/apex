# APEX Memory Primitives — Directory Ownership

The APEX spec (`apex-spec.md`, Failure 2) names four memory primitives:

- `.apex/todos/`
- `.apex/threads/`
- `.apex/seeds/`
- `.apex/backlog/`

These directories are part of every APEX project's `.apex/` tree. This document records **which component owns each directory** — who creates it and who writes to it — because that ownership is not symmetric, and R2's `REMEDIATION-PLAN-R2.md §"New findings during planning"` left an open question ("does `/apex:todo` have R-008's mkdir gap?") that needed a definitive answer.

## Ownership map

| Directory | Created by | Populated by | User-facing command? |
|---|---|---|---|
| `.apex/todos/` | `/apex:start` (initial `mkdir -p`) | `memory-synthesis` dream-cycle agent only | **No** — no `/apex:todo` command exists by design |
| `.apex/threads/` | `/apex:start` + `/apex:thread` defensive `mkdir -p` (R-008) | `/apex:thread` | **Yes** — `/apex:thread "slug: content"` |
| `.apex/seeds/` | `/apex:start` + `/apex:plant-seed` defensive `mkdir -p` (R-008) | `/apex:plant-seed` | **Yes** — `/apex:plant-seed "idea"` |
| `.apex/backlog/` | `/apex:start` + `/apex:add-backlog` defensive `mkdir -p` (R-008) | `/apex:add-backlog` | **Yes** — `/apex:add-backlog "task"` |

## Why `todos/` has no user-facing command

`.apex/todos/` is populated exclusively by the `memory-synthesis` dream-cycle agent during long sessions (see `framework/commands/apex/next.md` — the trigger block under `MEMORY_FILE_COUNT > 10` near the time-gate section). The dream cycle observes the current session, decides what deferred work is worth remembering, and writes todo files itself.

Users who want to capture a one-off task use `/apex:add-backlog` (long-term queue) or `/apex:plant-seed` (future idea). The absence of `/apex:todo` is intentional: todos are **system-generated reminders**, not user-written tasks. Duplicating them as a user command would blur the retrospective-vs-prospective memory distinction.

## R3-008 closure

R2's open question about `/apex:todo` mkdir parity is **resolved as non-issue**:

- There is no `/apex:todo` or `/apex:add-todo` command.
- The `todos/` directory is created once by `/apex:start` (see `framework/commands/apex/start.md` in the `mkdir -p .apex/{...todos,...}` section) and never written to by a user command.
- `memory-synthesis` writes into the directory only when it exists, and the dream cycle itself is invoked from within `/apex:next`, where the working directory is guaranteed to be a valid APEX project root with `.apex/` already present.

## How to add a new user-facing memory primitive

If APEX ever grows a 5th primitive with a user command, follow this contract:

1. Add the directory to the `mkdir -p .apex/{...}` block in `framework/commands/apex/start.md`.
2. Add a defensive `mkdir -p .apex/<dir>/` instruction inside the new command, before any `Write`.
3. Update this file's ownership map.
4. Add a smoke test in `framework/tests/test-wiring.sh` along the pattern:
   `assert_contains "$COMMANDS_DIR/<command>.md" "mkdir -p .apex/<dir>" "<command> has defensive mkdir"`

This contract is what R-008 (R2) and the R3-012 sweep generalize from — the goal is to make "file-not-found" errors unreachable for non-technical users.
