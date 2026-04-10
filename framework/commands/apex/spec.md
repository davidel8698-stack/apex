---
description: Review or update specification.
---

<context>
If empty: show SPEC.md, ask "Update anything?"
If changes:
  ## RENDER: Mission Briefing (Section 10-B abbreviated — agent card + task goal only)
  Task("planner", "Update spec only (skip Phase 1). Current: [SPEC.md]. Change: [$ARGUMENTS].
  Update Error Flows section if affected. Log in DECISIONS.md with phase impact.")
  ## RENDER: Flight Recorder (Section 10-C abbreviated — agent + verdict)
  "✅ Updated. ⚠️ Review DECISIONS.md for downstream impact."
</context>