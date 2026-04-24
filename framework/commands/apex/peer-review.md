---
description: Cross-AI peer review via manual copy/paste workflow. Optional quality layer.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Optional cross-AI peer review — sends current work to an external AI for independent
quality assessment. Uses manual copy/paste workflow (no API keys or MCP required).

This is OPTIONAL. The internal cross-model critic already provides quality assurance.
Peer review adds an independent, different-vendor perspective.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
Read STATE.json → current_phase.
If no completed tasks in current phase: "❌ No completed work to review. Complete at least one task first." STOP.

## DATA COLLECTION

1. Collect the diff for the current phase:
   ```
   git diff $(git merge-base HEAD main)..HEAD
   ```
   If diff is too large (>500 lines): summarize by file with change counts.

2. Collect key context:
   - SPEC.md summary (first 20 lines)
   - Current phase PLAN_META.json task list (names and verify_levels only)
   - RESULT.json verdicts for completed tasks
   - CRITIC.md verdicts (if any)

## REVIEW PROMPT GENERATION

Format the following review prompt for the user to copy:

```
━━━ CROSS-AI PEER REVIEW REQUEST ━━━

Project context:
{SPEC.md summary — first 20 lines}

Phase: {current_phase}
Tasks completed: {N}
Internal critic verdict: {overall verdict}

Review this diff for:
1. Missed edge cases — inputs, states, or conditions not handled
2. Security gaps — injection, traversal, auth bypass, data exposure
3. Performance regressions — O(n²) loops, unnecessary re-renders, unbounded queries
4. Incorrect error handling — swallowed errors, wrong error types, missing cleanup
5. Spec violations — does the implementation match the stated requirements?

Diff:
{git diff output or summary}

Respond with:
- VERDICT: PASS | FAIL | PARTIAL
- FINDINGS: numbered list of issues (empty if PASS)
- SEVERITY per finding: P0 (critical) | P1 (important) | P2 (minor)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## USER INTERACTION

Display the formatted prompt in a code block.

"📋 Review prompt ready. Copy the block above and paste it into your preferred AI tool."
"When you receive the review response, paste it back here."

Wait for user to paste the external AI's response.

## RESPONSE PROCESSING

When the user pastes the response:
1. Parse the verdict (PASS/FAIL/PARTIAL) and findings.
2. Record in `.apex/DECISIONS.md`:
   ```
   ## Cross-AI Peer Review — {timestamp}
   - Type: cross_ai_review
   - Phase: {current_phase}
   - External verdict: {verdict}
   - Findings: {count}
   - {findings list}
   ```
3. Display summary:
   "📊 Peer review recorded in DECISIONS.md"
   "External verdict: {verdict} | {N} findings"

If verdict is FAIL:
  "⚠️ External reviewer found critical issues. Consider addressing before shipping."

## ERROR HANDLING
- If git diff fails: "⚠️ Cannot generate diff. Provide file paths manually."
- If user doesn't paste a response: "No review response received. Skipping."
- If response can't be parsed: record raw response in DECISIONS.md as-is.
</context>
