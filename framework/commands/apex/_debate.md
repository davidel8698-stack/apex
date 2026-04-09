---
description: Architecture debate protocol for irreversible decisions. Sourced by /apex:next Step D.
---

## ARCHITECTURE DEBATE — FILE-BASED ISOLATION

Write .apex/debate-log/[decision]-brief-A.md
Write .apex/debate-log/[decision]-brief-B.md

Task("architect", "You are ADVOCATE A. Read .apex/debate-log/[decision]-brief-A.md and SPEC.md.
Write argument to .apex/debate-log/[decision]-advocate-A.md.
Do NOT read any other debate files. Argue FOR your option only.
Acknowledge downsides honestly. Cite SPEC.md requirements.

STRUCTURE:
## Argument For: [OPTION A]
### Why This Fits This Project (3 spec citations)
### Implementation Path
### Acknowledged Downsides
### Reversibility Assessment")

Task("architect", "You are ADVOCATE B. Read .apex/debate-log/[decision]-brief-B.md and SPEC.md.
Write argument to .apex/debate-log/[decision]-advocate-B.md.
Do NOT read advocate-A.md. Argue FOR your option only.
[Same structure]")

Task("architect", "You are JUDGE. Read BOTH:
.apex/debate-log/[decision]-advocate-A.md
.apex/debate-log/[decision]-advocate-B.md
And SPEC.md.

Prefer: more reversible, better SPEC evidence, lower risk for THIS project.

WRITE to .apex/DECISIONS.md:
## ARCHITECTURE DECISION: [Name] — [date]
### Decision: [Chosen option]
### Reasoning (3-4 sentences citing SPEC)
### How Other Advocate's Arguments Were Weighted
### Reversibility Note
### Arguments Preserved: [file paths]")