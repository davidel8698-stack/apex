---
description: Browse and select from pre-built workflow recipes. Workflows provide phase blueprints that the architect can adopt for common tasks.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Read `~/.claude/apex-workflows/_index.json`.

If `$ARGUMENTS` is empty:
  Display the workflow menu:
  ```
  APEX Workflow Library
  =====================
  Available workflows:
  ```
  For each workflow in _index.json:
    `[N] {name} — {description} (complexity: {complexity}, ~{estimated_phases} phases)`
  
  Ask user to select by number or name.

If `$ARGUMENTS` matches a workflow ID or name:
  Read the matching workflow .md file from `~/.claude/apex-workflows/`.
  Display its contents to the user.
  
  Present options:
  1. **Adopt this workflow** — inject its phases into the architect context for the current project. The architect will use these phases as a starting template when creating PLAN.md.
  2. **View another workflow** — return to the menu.
  3. **Cancel** — exit without changes.

  If user selects "Adopt":
    Store the selected workflow ID in STATE.json under `active_workflow`.
    Confirm: "Workflow '{name}' selected. The architect will use its phase blueprint when planning."
    Note: The architect reads STATE.json.active_workflow and loads the corresponding workflow file as context for phase planning.

## Error handling
- If `_index.json` is missing or invalid: "Workflow library not found. Run /apex:start to initialize."
- If selected workflow .md file is missing: "Workflow file not found: {file}. The library may be incomplete."
</context>
