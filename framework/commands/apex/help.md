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
| `/apex:walkthrough` | Guided explanation of code or decisions (walkthrough) |

### Recovery & Diagnostics
| Command | Purpose |
|---------|---------|
| `/apex:forensics` | Diagnose what went wrong (timeline reconstruction / forensics) |
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

**Cross-language directive [R5-006]:** Match across English AND Hebrew. Both columns map to the same command. If the input is Hebrew, the matched row's English column is irrelevant — pick the command in the Route To column. The framework's primary user is Hebrew-speaking; Hebrew variants are first-class, not fallback.

When user provides a question, match their intent to the best command:

| Intent Pattern (English) | Hebrew variant | Route To | Explanation |
|---------------|---------|----------|-------------|
| "I'm stuck" / "something broke" / "what happened" | "אני תקוע" / "משהו נשבר" / "לא עובד" / "מה קרה" | `/apex:forensics` | Reconstructs timeline and diagnoses failures |
| "How do I undo" / "revert" / "go back" | "תבטל" / "בטל את זה" / "תחזיר אחורה" / "תבטל את השינוי" | `/apex:rollback` | Reverts to previous known-good state |
| "What's the status" / "where am I" / "what's left" | "מה המצב" / "איפה אנחנו" / "מה נשאר" | `/apex:status` | Shows current project state and progress |
| "Walk me through" / "explain this" / "I don't understand" | "תסביר לי" / "לא הבנתי" / "המודל טעה" / "תעבור איתי על הקוד" | `/apex:walkthrough` | Guided explanation of code or decisions |
| "Start new project" / "begin" / "initialize" | "פרויקט חדש" / "תתחיל" / "אתחול" | `/apex:start` | Initializes new APEX project from scratch |
| "What should I do next" / "next step" | "מה הצעד הבא" / "מה עכשיו" / "המשך" / "תמשיך" | `/apex:next` | Advances to next logical pipeline step |
| "Stop" / "pause" / "save and quit" | "הפסקה" / "תעצור" / "שמור וצא" | `/apex:pause` | Saves state for later resumption |
| "Continue" / "resume" / "pick up where I left off" | "המשך" / "חידוש עבודה" / "תמשיך מאיפה שעצרנו" | `/apex:resume` | Resumes from saved state |
| "Fix the tests" / "tests failing" / "run tests" | "תקן את הבדיקות" / "הבדיקות נופלות" / "תריץ בדיקות" | `/apex:test` | Runs test suite with diagnostics |
| "Review my code" / "check quality" | "תסקור את הקוד" / "בדוק איכות" | `/apex:peer-review` | Initiates code peer review |
| "Ship it" / "deploy" / "we're done" | "להעלות לפרודקשן" / "לשגר" / "סיימנו" | `/apex:ship` | Ships completed phase |
| "Plan this phase" / "how should we build" | "תכנן את השלב הזה" / "איך לבנות" | `/apex:plan-phase` | Creates detailed execution plan |
| "I have an idea" / "save this for later" | "יש לי רעיון" / "שמור לי את זה" | `/apex:plant-seed` | Stores idea for future consideration |
| "Show me everything" / "list" / "what exists" | "תראה לי הכל" / "רשימה" / "מה קיים" | `/apex:list` | Lists all project artifacts |
| "Health check" / "is APEX working" / "validate framework" | "בדיקת תקינות" / "האם APEX עובד" | `/apex:health-check` | Runs framework integrity checks |
| "Improve APEX itself" / "close framework gaps" / "run audit loop" / "fix everything broken in APEX" / "self-heal" | "תקן את APEX" / "סגור פערים ב-APEX" / "ריצה אוטומטית של תיקונים" | `/apex:self-heal` | Runs framework gap-closure loop (audit → plan → schedule → execute → check) until two consecutive clean rounds |
| "Help" / (no input) | "עזרה" / "מה אפשר לעשות" | `/apex:help` (self) | Lists available commands |

## ROUTING LOGIC

1. Read the user's free-text question.
2. Match against the intent patterns above (fuzzy — use semantic similarity, not exact match).
3. If confident match: recommend the command with a 1-2 sentence contextual explanation of WHY this command fits their situation.
4. If ambiguous (multiple possible matches): present top 2-3 options with brief explanations, let user choose.
5. If no match: suggest `/apex:status` as default starting point, and list the most likely category of commands.

## STUCK DETECTION RULE [R5-007]
If the input contains any of these signals — `stuck`, `blocked`, `broken`, `אני תקוע`, `לא עובד`, `נתקעתי`, `נשבר` — prefer `/apex:forensics` over `/apex:status` as the routed command. Reason: when the user signals stuckness, "what's the status" gives them more state but no path forward; forensics reconstructs the timeline and produces a fix plan. `/apex:status` is the no-match fallback for *neutral* inputs only.

## AMBIGUITY POLICY [R5-007]
When intent matching does NOT produce a single high-confidence row (i.e., top-1 score is close to top-2, or the wording fits two categories such as "stuck" + "deploy"):
1. Present the top-2 candidates as a numbered proposal block (per `## PROPOSALS MODE GUARD` above): `[1] /apex:forensics — <one-line reason>` and `[2] /apex:rollback — <one-line reason>`. Mark the higher-scoring candidate as `[recommended]`.
2. Wait for the user to pick `1` or `2`. Do NOT ask an open-ended question — propose, don't ask.
3. If the user does not pick within the same turn, route to the `[recommended]` default.
This is the "fuzzy semantic similarity" mechanism made observable: ambiguity produces a proposal, not silence and not an open question.

## LOGGING DIRECTIVE [R5-007]
After EVERY routing decision (confident match, ambiguous proposal, or no-match fallback), emit a `help_routing` event to the session log so routing quality is audit-able and re-derivable from disk:
```
bash ~/.claude/hooks/session-log.sh "help_routing" "intent='<user's text, single quotes escaped>' matched='<command>' confidence='<high|ambiguous|fallback>'"
```
This event is consumed by `state-rebuild.sh` (R5-004 — events become disk-derivable state) and surfaces in `/apex:status` history. Spec anchor: "Proof-of-process beats proof-of-promise."

## DYNAMIC DISCOVERY
For completeness, also scan `ls ~/.claude/commands/apex/*.md` at runtime to catch any commands not in the static table above.

## TOPIC: telemetry [M16.1 / Phase 12.09 / User Decision #3]
When the user runs `/apex:help telemetry` (or asks about telemetry, privacy,
data collection, opt-out, "what does APEX collect", "מה APEX אוסף",
"איך לבטל את הטלמטריה"), render the following summary verbatim and link to
`framework/docs/PRIVACY-POLICY.md` for the full policy. Hebrew + English
together (the user's primary language is Hebrew per CLAUDE.md).

```
🔒 APEX Telemetry — Quick Summary
─────────────────────────────────
What's collected (numeric counters only):
  • Timestamps (ts), event names, project_hash (sha256[0:8]).
  • Phase identifier (optional).
  • Counters: drift_pct, baseline_avg, current_avg, tasks_completed, etc.

What's NOT collected (ever):
  • File paths, source code, commit messages, branch names.
  • Repository URLs, user identity (name/email).
  • Free-text strings from RESULT.json prose fields.

Where it lives:
  • .apex/telemetry.jsonl — project-local file. No remote upload in v0.1.x.

How to opt out (either path works — defense-in-depth):
  • Per-session:  export APEX_TELEMETRY=off
  • Persistent:   touch ~/.claude/telemetry-opt-out.flag

How to delete:
  • rm .apex/telemetry.jsonl   (single-file removal; no backups, no remote)
  • TODO: apex telemetry purge command — v1.0+ backlog.

Full policy: framework/docs/PRIVACY-POLICY.md
─────────────────────────────────
🔒 APEX טלמטריה — סיכום קצר
מה נאסף (מוני מספרים בלבד):
  • חותמות זמן, שמות אירועים, project_hash (sha256[0:8]).
  • מזהה שלב (אופציונלי).
  • מונים: drift_pct, baseline_avg, current_avg, tasks_completed וכו'.

מה לא נאסף (אף פעם):
  • נתיבי קבצים, קוד מקור, הודעות commit, שמות branch.
  • כתובות URL, זהות משתמש (שם/אימייל).
  • מחרוזות טקסט חופשי משדות prose ב-RESULT.json.

היכן הנתונים:
  • .apex/telemetry.jsonl — קובץ מקומי של הפרויקט. אין העלאה מרחוק ב-v0.1.x.

איך לבטל הסכמה (שני הנתיבים עובדים — הגנה לעומק):
  • לסשן בודד:    export APEX_TELEMETRY=off
  • קבוע:         touch ~/.claude/telemetry-opt-out.flag

איך למחוק:
  • rm .apex/telemetry.jsonl   (מחיקת קובץ בודד; אין גיבויים, אין מרוחק)
  • TODO: פקודה apex telemetry purge — ב-backlog לגרסה v1.0+.

המדיניות המלאה: framework/docs/PRIVACY-POLICY.md
```

## INTENT-TO-COMMAND ROUTING — TELEMETRY ADDITION
Add the following row to the routing table above (intent → telemetry topic):
| "telemetry" / "privacy" / "what does APEX collect" / "opt out" | "טלמטריה" / "פרטיות" / "מה APEX אוסף" / "ביטול הסכמה" | `/apex:help telemetry` (this topic) | Renders the telemetry/privacy summary above + links to PRIVACY-POLICY.md |
</context>
