---
description: Final verification and release tag. Ship the project.
---

<context>
## PURPOSE
Run final verification across all phases, then create a release tag if everything passes.

## PROCEDURE
1. Read .apex/STATE.json — verify project exists and all phases are complete.
   If STATE does not exist: "No APEX project found." STOP.
   If not all phases complete:
     "Not all phases are complete. Current: phase {current}/{total}.
     Complete remaining phases before shipping."
     STOP.

2. Run full test suite:
   Read .apex/phases/*/PLAN_META.json — collect all verify_commands across all phases.
   Execute each verify command:
     Run: bash -c "$cmd" 2>&1
     Record result.

   Display:
   "## Full Test Suite
   | Phase | Command | Result |
   |-------|---------|--------|
   | ... | ... | PASS/FAIL |

   {passed}/{total} passed."

   If any failed:
     "Cannot ship with failing tests. Fix failures first."
     STOP.

3. Run cross-phase audit on all phases:
   For each phase N from 1 to total_phases:
     bash ~/.claude/hooks/cross-phase-audit.sh {N}
   
   If any audit fails:
     "Cross-phase audit found issues. Resolve before shipping."
     Display audit output.
     STOP.

4. Check for unresolved items:
   - Read .apex/DECISIONS.md — any entries marked "unresolved" or "TODO"?
   - Read .apex/todos/ — any pending items?
   If unresolved items exist:
     "Warning: unresolved items found:
     [list items]
     (1) Proceed anyway
     (2) Stop and resolve"
     Wait for user choice.

5. Create release tag:
   project_name = STATE.project
   version = $ARGUMENTS or "v1.0.0" (if no version specified)
   
   git tag -a "{version}" -m "APEX release: {project_name} {version}

   Phases: {total_phases}
   Tasks completed: {total_tasks}
   Built with APEX v6"

6. Display:
   "## Ship Complete
   Project: {project_name}
   Tag: {version}
   Phases: {total_phases}
   Tasks: {total_tasks}

   To push: git push origin {version}

   Update STATE.json:
   - status: 'shipped'
   - shipped_at: [now]
   - shipped_version: {version}"

7. Log event:
   bash ~/.claude/hooks/session-log.sh "ship" "Project shipped as {version}"
</context>