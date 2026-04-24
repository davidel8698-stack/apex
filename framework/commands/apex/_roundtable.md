---
description: Multi-specialist roundtable protocol for complex architectural decisions. Sourced by /apex:next when task.roundtable_needed == true.
---

## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## ROUNDTABLE SESSION — FILE-BASED ISOLATION

This protocol convenes 3-5 specialists for multi-faceted architectural decisions.
Unlike debate (2-advocate consensus) or critic (negation), roundtable seeks **depth** —
each specialist presents their perspective, architect synthesizes.

Appropriate for: tech stack choices, trade-off decisions, architectural choices.
NOT appropriate for routine tasks — this is overhead.

## SECTION 1 — Briefing

Ensure directory exists: `mkdir -p .apex/roundtable-log/`

Write .apex/roundtable-log/[decision]-brief.md containing:
- Decision name and context
- Options under consideration
- Relevant SPEC.md requirements
- Constraints (timeline, budget, technical)

## SECTION 2 — Specialist Position Papers

For each relevant specialist from {security, performance, cost, UX, data}
(select 3-5 based on decision scope — not all are needed for every decision):

## RENDER: Mission Briefing (Section 10-B abbreviated — agent card + task goal only)
Task("[specialist]", "You are the [SPECIALIST] perspective in a roundtable on: [decision].
Read .apex/roundtable-log/[decision]-brief.md and SPEC.md.
Write your position paper to .apex/roundtable-log/[decision]-[specialist].md.
Do NOT read other specialists' position papers.

STRUCTURE:
## [SPECIALIST] Perspective on: [decision]
### Impact on [specialist domain] (cite SPEC where relevant)
### Recommended Option and Why
### Risks and Mitigations from [specialist] Viewpoint
### Trade-offs I Accept
### Non-negotiable Requirements from My Domain")
## RENDER: Flight Recorder (Section 10-C abbreviated — agent + verdict)

Repeat for each selected specialist. Each writes to their own file.
Order does not matter — specialists are blind to each other's papers.

## SECTION 3 — Synthesis

## RENDER: Mission Briefing (Section 10-B abbreviated — agent card + task goal only)
Task("architect", "You are the SYNTHESIZER for this roundtable on: [decision].
Read ALL position papers:
.apex/roundtable-log/[decision]-security.md (if exists)
.apex/roundtable-log/[decision]-performance.md (if exists)
.apex/roundtable-log/[decision]-cost.md (if exists)
.apex/roundtable-log/[decision]-UX.md (if exists)
.apex/roundtable-log/[decision]-data.md (if exists)
And SPEC.md.

Weigh each specialist's input. Prefer: better SPEC alignment, lower risk, more reversible.

WRITE to .apex/DECISIONS.md:
## ROUNDTABLE DECISION: [Name] — [date]
### Decision: [Chosen option]
### Specialists Consulted: [list]
### Synthesis (how each perspective was weighted)
### Key Trade-offs Accepted (which specialist concerns were overridden and why)
### Risks Acknowledged (from specialist papers)
### Reversibility Note
### Position Papers Preserved: [file paths]")
## RENDER: Flight Recorder (Section 10-C abbreviated — agent + verdict)

## SECTION 4 — Cleanup

Log roundtable outcome to session log.
Position papers remain in .apex/roundtable-log/ for audit trail.
