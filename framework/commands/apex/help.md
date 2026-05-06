---
description: Context-aware conversational navigator in natural language. Routes free-text questions to the correct APEX command.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Natural language help — closes the "framework vocabulary gap".
User types a free-text question; you route them to the correct APEX command with contextual explanation.
If no argument given, list all available commands grouped by category.

## NO-ARG MODE
If user typed `/apex:help` with no question, list all commands grouped by category:

### Pipeline — Core Build Loop
| Command | Purpose |
|---------|---------|
| `/apex:start` | Initialize new APEX project |
| `/apex:next` | Advance to next logical step |
| `/apex:precheck` | Mark pre-build checklist items |
| `/apex:spec` | Review or update specification |
| `/apex:onboard` | Onboard to existing project |

### Phase Lifecycle
| Command | Purpose |
|---------|---------|
| `/apex:discuss-phase` | Discuss phase before planning |
| `/apex:plan-phase` | Create detailed phase plan |
| `/apex:execute-phase` | Execute phase plan |
| `/apex:validate-phase` | Validate phase completion |
| `/apex:ui-phase` | UI-focused phase execution |
| `/apex:ship` | Ship completed phase |

### Execution Tiers
| Command | Purpose |
|---------|---------|
| `/apex:fast` | Fastest execution, minimal ceremony |
| `/apex:quick` | Small task without full planning |
| `/apex:full` | Full ceremony execution |
| `/apex:build` | Build/compile project |

### Quality & Review
| Command | Purpose |
|---------|---------|
| `/apex:test` | Run test suite |
| `/apex:peer-review` | Code peer review |
| `/apex:ui-review` | UI/UX review |
| `/apex:refine` | Refine and improve code |
| `/apex:walkthrough` | Guided code walkthrough |

### Recovery & Diagnostics
| Command | Purpose |
|---------|---------|
| `/apex:forensics` | Diagnose what went wrong |
| `/apex:rollback` | Revert to previous state |
| `/apex:recover` | Recover from crash or stuck state |
| `/apex:resume` | Resume after context rotation |

### Session & State
| Command | Purpose |
|---------|---------|
| `/apex:status` | Current project status |
| `/apex:pause` | Save state and pause |
| `/apex:pause-work` | Pause mid-phase with handoff |
| `/apex:resume-work` | Resume from handoff |
| `/apex:session-report` | Generate session summary |
| `/apex:milestone-summary` | Milestone completion summary |

### Memory & Knowledge
| Command | Purpose |
|---------|---------|
| `/apex:thread` | Async conversation thread |
| `/apex:plant-seed` | Plant idea for future |
| `/apex:add-backlog` | Add item to backlog |
| `/apex:review-backlog` | Review backlog items |

### Operations & Setup
| Command | Purpose |
|---------|---------|
| `/apex:list` | List project artifacts |
| `/apex:new-workspace` | Create new workspace |
| `/apex:new-agent` | Create custom agent |
| `/apex:gen-skill` | Generate stack-specific skill |
| `/apex:workflow` | Run predefined workflow |
| `/apex:health-check` | Validate framework integrity |

### Framework Maintenance
| Command | Purpose |
|---------|---------|
| `/apex:self-heal` | Run framework gap-closure loop until convergence |

## INTENT-TO-COMMAND ROUTING TABLE

When user provides a question, match their intent to the best command:

| Intent Pattern | Route To | Explanation |
|---------------|----------|-------------|
| "I'm stuck" / "something broke" / "what happened" | `/apex:forensics` | Reconstructs timeline and diagnoses failures |
| "How do I undo" / "revert" / "go back" | `/apex:rollback` | Reverts to previous known-good state |
| "What's the status" / "where am I" / "what's left" | `/apex:status` | Shows current project state and progress |
| "Walk me through" / "explain this" / "I don't understand" | `/apex:walkthrough` | Guided explanation of code or decisions |
| "Start new project" / "begin" / "initialize" | `/apex:start` | Initializes new APEX project from scratch |
| "What should I do next" / "next step" | `/apex:next` | Advances to next logical pipeline step |
| "Stop" / "pause" / "save and quit" | `/apex:pause` | Saves state for later resumption |
| "Continue" / "resume" / "pick up where I left off" | `/apex:resume` | Resumes from saved state |
| "Fix the tests" / "tests failing" / "run tests" | `/apex:test` | Runs test suite with diagnostics |
| "Review my code" / "check quality" | `/apex:peer-review` | Initiates code peer review |
| "Ship it" / "deploy" / "we're done" | `/apex:ship` | Ships completed phase |
| "Plan this phase" / "how should we build" | `/apex:plan-phase` | Creates detailed execution plan |
| "I have an idea" / "save this for later" | `/apex:plant-seed` | Stores idea for future consideration |
| "Show me everything" / "list" / "what exists" | `/apex:list` | Lists all project artifacts |
| "Health check" / "is APEX working" / "validate framework" | `/apex:health-check` | Runs framework integrity checks |
| "Improve APEX itself" / "close framework gaps" / "run audit loop" / "fix everything broken in APEX" / "self-heal" | `/apex:self-heal` | Runs framework gap-closure loop (audit → plan → schedule → execute → check) until two consecutive clean rounds |

## ROUTING LOGIC

1. Read the user's free-text question.
2. Match against the intent patterns above (fuzzy — use semantic similarity, not exact match).
3. If confident match: recommend the command with a 1-2 sentence contextual explanation of WHY this command fits their situation.
4. If ambiguous (multiple possible matches): present top 2-3 options with brief explanations, let user choose.
5. If no match: suggest `/apex:status` as default starting point, and list the most likely category of commands.

## DYNAMIC DISCOVERY
For completeness, also scan `ls ~/.claude/commands/apex/*.md` at runtime to catch any commands not in the static table above.
</context>
