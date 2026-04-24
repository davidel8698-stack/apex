---
description: Create a custom specialist agent from template with validation.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Generates a new specialist agent .md file from the established agent template structure.
Validates the agent name doesn't conflict with existing agents and creates the file
with the correct frontmatter, sections, and conventions.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.

Parse $ARGUMENTS:
- Expected format: `<agent-name> [domain description]`
- If $ARGUMENTS is empty: "❌ /apex:new-agent requires an agent name. Example: /apex:new-agent analytics 'Data analytics and dashboard specialist'" STOP.

Extract AGENT_NAME = first word of $ARGUMENTS.
Extract DOMAIN = remaining words (optional — will prompt if empty).

## VALIDATION

1. Normalize AGENT_NAME: lowercase, hyphens only (no spaces, no underscores).
2. Check existing agents — scan `~/.claude/agents/` and `~/.claude/agents/specialist/`:
   If file `{AGENT_NAME}.md` already exists: "❌ Agent '{AGENT_NAME}' already exists at {path}. Choose a different name." STOP.
3. Reserved names check — reject: executor, critic, verifier, architect, planner, test-architect.
   "❌ '{AGENT_NAME}' is a core agent name and cannot be overridden." STOP.

## TEMPLATE GENERATION

Create `~/.claude/agents/specialist/{AGENT_NAME}.md` with this structure:

```markdown
---
name: {AGENT_NAME}
description: {DOMAIN or "Custom specialist agent"}
model: sonnet
tools: Read, Write, Edit, Bash, Glob, Grep
---

## Role
You are the {AGENT_NAME} specialist agent for APEX projects.
{DOMAIN description if provided}

## Domain Invariants
<!-- Add domain-specific rules that MUST always hold -->
<!-- Example: "All database queries MUST use parameterized statements" -->

## Named Failure Prohibitions
<!-- List specific failure modes this agent must never produce -->
<!-- Example: "NEVER generate SQL without WHERE clause on UPDATE/DELETE" -->

## Output Contract
Write results to the file path specified in task XML.
Follow RESULT.json schema: status (pass|fail|partial), summary, files_changed.
```

## CONFIRMATION

Display the generated file content.
"✅ Agent '{AGENT_NAME}' created at ~/.claude/agents/specialist/{AGENT_NAME}.md"
"Edit the Domain Invariants and Named Failure Prohibitions sections to customize."

## ERROR HANDLING
- If agents directory doesn't exist: create `~/.claude/agents/specialist/` first.
- If write fails: display error message with path.
</context>
