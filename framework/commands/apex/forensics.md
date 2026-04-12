---
description: Diagnose what went wrong. Timeline reconstruction and failure analysis.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Reconstruct a timeline of recent events and identify what went wrong.
Read project history, present findings, and suggest recovery actions.

## DATA GATHERING
1. Read .apex/STATE.json — extract:
   - current_stage, status, current_phase, current_unit
   - reflexion object (attempts, failures)
   - session object (errors, auto_pause history)
   - dora metrics (if present)

2. Read .apex/SESSION-LOG.md — extract last 30 lines.
   Parse events into a timeline: timestamp | event_type | detail

3. Run: git log --oneline -20
   Extract recent commits with timestamps.

4. Check for crash indicators:
   - .apex/STATE.json.lock exists? → crash detected
   - STATE.status == "failed" or "blocked"? → failure state
   - STATE.reflexion.current_unit_attempts > 2? → stuck loop
   - STATE.session.auto_paused == true? → auto-pause triggered

5. Check .apex/phases/ for recent RESULT.json and CRITIC.md files:
   - Any CRITIC.md with verdict: "FAIL"?
   - Any RESULT.json with status: "failure"?

## TIMELINE RECONSTRUCTION
Present findings as a chronological timeline:

"## Forensics Report

### Timeline (most recent first)
| Time | Source | Event |
|------|--------|-------|
| ... | git | commit: [message] |
| ... | session-log | [event_type]: [detail] |
| ... | STATE | status changed to [status] |

### Failure Analysis
[If failure indicators found:]
- **Root cause**: [describe what went wrong based on evidence]
- **Impact**: [what was affected — which phase/unit/task]
- **Contributing factors**: [reflexion attempts, context usage, etc.]

[If no failure found:]
- No active failure detected. Project status: [status]

### Suggested Recovery Actions
[Based on findings, suggest 1-3 specific actions:]
1. [action] — use /apex:[command]
2. [action] — use /apex:[command]
3. [action] — use /apex:[command]"

## NO SPECULATIVE CLAIMS
Only report what the data shows. Do not invent causes not supported by the timeline.
If data is insufficient, say: "Insufficient data to determine root cause. Consider checking [source]."
</context>