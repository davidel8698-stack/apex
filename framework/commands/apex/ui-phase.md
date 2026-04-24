---
description: UI-specific phase execution with 6-Pillar Design Contract enforcement.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

Task from $ARGUMENTS.

## PURPOSE
Dedicated pipeline for UI/frontend phase execution. Enforces the 6-Pillar Design Contract
as structural constraints on every UI task, using the frontend-specialist agent.

For non-UI work, use /apex:build or /apex:refine instead.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
If $ARGUMENTS is empty: "❌ /apex:ui-phase requires a task description." STOP.
Read STATE.json → pipeline_mode.
If pipeline_mode not in ["build", "refine"]: Set pipeline_mode = "build".

## 6-PILLAR DESIGN CONTRACT
Every UI task executed through this command MUST satisfy these 6 pillars.
Pass these as task XML constraints to the frontend-specialist agent — do NOT expand
the agent's permanent prompt.

```
<ui_contract>
  <pillar id="1" name="Responsive Layout">
    Range: 320px to 2560px. Mobile-first breakpoints.
    No horizontal scroll at any viewport width.
  </pillar>
  <pillar id="2" name="Accessibility">
    WCAG 2.1 AA compliance. Semantic HTML. ARIA labels where needed.
    Color contrast ratio >= 4.5:1 for text.
  </pillar>
  <pillar id="3" name="State Coverage">
    Every component must handle: loading, error, empty, and populated states.
    No blank screens. No unhandled promise rejections in UI.
  </pillar>
  <pillar id="4" name="Keyboard Navigation">
    All interactive elements reachable via Tab.
    Focus indicators visible. No keyboard traps.
    Escape key closes modals/dropdowns.
  </pillar>
  <pillar id="5" name="Form Validation UX">
    Inline validation on blur. Error messages next to the field.
    Submit button disabled until valid (or clear error on submit).
    No silent failures.
  </pillar>
  <pillar id="6" name="Performance Budget">
    LCP < 2.5s. CLS < 0.1. FID < 100ms.
    Images lazy-loaded below the fold. No render-blocking resources.
  </pillar>
</ui_contract>
```

## EXECUTION

1. Read .apex/SPEC.md for project context.
2. Read current phase PLAN_META.json (if exists) for task breakdown.
3. For each UI task in the phase:
   a. Compose task XML with:
      - Task description from $ARGUMENTS or PLAN_META
      - The 6-pillar `<ui_contract>` block above as constraints
      - Relevant file paths from TASK_MAP.md
   b. Spawn frontend-specialist agent:
      `Task("frontend-specialist", TASK_XML, model=resolve_model("frontend-specialist"))`
   c. Read the agent's output.
   d. Ensure phase directory exists: `mkdir -p .apex/phases/${current_phase}/`
   e. Write RESULT.json to `.apex/phases/${current_phase}/${task_id}-RESULT.json`
   f. Write SUMMARY.md to `.apex/phases/${current_phase}/${task_id}-SUMMARY.md`

4. After all tasks complete:
   "✅ UI phase complete. ${completed}/${total} tasks done."
   "Run /apex:ui-review to verify 6-pillar compliance."

## PILLAR COMPLIANCE NOTE
The 6-pillar contract is a CHECKLIST, not a scoring system.
Each pillar is pass/fail. A task that violates any pillar is PARTIAL, not PASS.
The frontend-specialist agent receives pillars as task context and is responsible
for self-checking compliance before reporting PASS.

## ERROR HANDLING
- If frontend-specialist agent fails: log error, mark task as FAIL, continue to next task.
- If no PLAN_META.json exists: treat $ARGUMENTS as a single-task phase.
- If SPEC.md is missing: warn but continue (spec is recommended, not required for UI work).
</context>
