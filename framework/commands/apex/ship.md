---
description: Final verification and release tag. Ship the project.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Run final verification across all phases, then create a release tag if everything passes.

## PROCEDURE
1. Read .apex/STATE.json — verify project exists and all phases are complete.
   If STATE does not exist: "No APEX project found." STOP.
   If not all phases complete:
     "Not all phases are complete. Current: phase {current}/{total}.
     Complete remaining phases before shipping."
     STOP.

   Activate strict mode before verification:
   Set STATE.strict_mode = true and write updated STATE.json.
   This ensures all subsequent verification (test suite, cross-phase audit, unresolved items check)
   runs at D-level strictness — every task treated as verify_level D.

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

8. **M18.1 DORA delta emission (additive — existing steps 1–7 are untouchable):**
   Refresh `.apex/DORA.json` from the git-log engine and capture a
   ship-time snapshot so a future cohort report can correlate ship
   events with DORA deltas.

   ```
   # Snapshot the prior DORA reading (if present) before regeneration.
   PRIOR_DORA=""
   if [ -f .apex/DORA.json ]; then
     PRIOR_DORA=$(cat .apex/DORA.json)
   fi

   # Regenerate against the post-tag state (the release tag from step 5
   # is now visible to the engine if it matches APEX_DORA_DEPLOY_TAG_PATTERN
   # — by default release/*; users who tag as v1.0.0 should set
   # APEX_DORA_DEPLOY_TAG_PATTERN="v*" before invoking).
   bash framework/hooks/dora-collect.sh 2>/dev/null || true
   ```

   Append a ship-event line to `.apex/event-log.jsonl` carrying the
   prior and current DORA-quartet headline numbers, so M16.1's
   telemetry pipeline (task 12.09 — forward-reference; not wired
   here) can later compute deltas against the ship-event timeline:

   ```
   if [ -f .apex/DORA.json ]; then
     CURRENT_DORA=$(cat .apex/DORA.json)
     TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
     printf '{"ts":"%s","severity":"MINOR","hook":"ship","type":"dora.ship_delta","version":"%s","prior":%s,"current":%s}\n' \
       "$TS" "{version}" \
       "${PRIOR_DORA:-null}" \
       "$CURRENT_DORA" >> .apex/event-log.jsonl 2>/dev/null || true
   fi
   ```

   Failure of either command is **non-blocking** — `/apex:ship` MUST
   complete successfully even if DORA collection fails (the engine is
   instrumentation, not a release gate).

   Methodology + committed definitions: `framework/docs/CLAIMS-MEASUREMENT.md`
   §"DORA measurement engine".
</context>