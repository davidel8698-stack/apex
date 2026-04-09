---
description: Review or update specification.
---

<context>
If empty: show SPEC.md, ask "Update anything?"
If changes:
  Task("planner", "Update spec only (skip Phase 1). Current: [SPEC.md]. Change: [$ARGUMENTS].
  Update Error Flows section if affected. Log in DECISIONS.md with phase impact.")
  "✅ Updated. ⚠️ Review DECISIONS.md for downstream impact."
</context>