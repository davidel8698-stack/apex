---
description: Create an isolated APEX workspace using git worktree.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Creates an isolated workspace using git worktree for parallel work streams.
Each workspace gets its own working directory and branch while sharing git history.

## GUARD
Verify git repository exists: `git rev-parse --git-dir`
If not a git repo: "❌ Not a git repository. Initialize with git init first." STOP.

Parse $ARGUMENTS:
- Expected format: `<workspace-name>`
- If $ARGUMENTS is empty: "❌ /apex:new-workspace requires a name. Example: /apex:new-workspace feature-auth" STOP.

Extract WORKSPACE_NAME = $ARGUMENTS (first word, sanitized).

## VALIDATION

1. Sanitize name: lowercase, alphanumeric + hyphens only.
2. Check if worktree already exists:
   `git worktree list` — if any entry contains the workspace name: 
   "❌ Workspace '{WORKSPACE_NAME}' already exists. Use a different name or remove it with: git worktree remove {path}" STOP.
3. Check if branch already exists:
   `git branch --list "apex/{WORKSPACE_NAME}"` — if exists:
   "⚠️ Branch apex/{WORKSPACE_NAME} already exists. Attaching to existing branch."

## EXECUTION

1. Get project directory name:
   `PROJECT_DIR=$(basename "$(pwd)")`

2. Create worktree:
   ```
   git worktree add "../${PROJECT_DIR}-${WORKSPACE_NAME}" -b "apex/${WORKSPACE_NAME}"
   ```
   If branch already exists (from validation step 3):
   ```
   git worktree add "../${PROJECT_DIR}-${WORKSPACE_NAME}" "apex/${WORKSPACE_NAME}"
   ```

3. Copy APEX state snapshot (read-only reference):
   ```
   cp .apex/STATE.json "../${PROJECT_DIR}-${WORKSPACE_NAME}/.apex/STATE.json" 2>/dev/null
   ```
   This is a snapshot — the new workspace should run /apex:start or /apex:onboard.

4. List all worktrees for context:
   `git worktree list`

## OUTPUT

```
✅ Workspace created
   Name:      {WORKSPACE_NAME}
   Path:      ../{PROJECT_DIR}-{WORKSPACE_NAME}
   Branch:    apex/{WORKSPACE_NAME}
   
   Next steps:
   1. cd "../{PROJECT_DIR}-{WORKSPACE_NAME}"
   2. Run /apex:start (new project) or /apex:onboard (continue work)
   
   Active worktrees:
   {git worktree list output}
```

## ERROR HANDLING
- If git worktree add fails: display git's error message.
- If parent directory is not writable: "❌ Cannot create worktree. Check directory permissions."
- If .apex/ doesn't exist in source: skip STATE.json copy (warn only).
</context>
