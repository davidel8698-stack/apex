# AC-6B Independent Probe — Prompt for a Fresh Claude Code Session

> **OWNER INSTRUCTIONS:**
>
> 1. Open a **brand new Claude Code session** in the APEX project directory. Do NOT reuse the Phase-7 main session.
> 2. Make sure no prior context is loaded (fresh terminal, fresh `claude` invocation).
> 3. Enter Plan Mode (press `Shift+Tab` twice, or type `/plan`).
> 4. Paste **the prompt below** verbatim — everything between the `---PROMPT START---` and `---PROMPT END---` markers.
> 5. Let the agent work to completion in Plan Mode (it will not modify any files — only research and produce a plan document).
> 6. When it reaches `ExitPlanMode`, review the plan it produced. Save its findings to `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md`.
> 7. Return to the Phase-7 main session with the findings file path.

---

---PROMPT START---

You are a fresh framework auditor with no prior context about this project. I'm hiring you to do a single thing: **find real defects in the APEX framework that prior auditors may have missed**.

## Background you need

APEX is a meta-framework for Claude Code: it consists of slash-commands, hook scripts, agent definitions, and JSON schemas. It is documented in `apex-spec.md` at the project root.

Prior audit rounds against this framework's pristine state returned **0 findings**. The acceptance criterion for that audit class (AC-6b) requires the count be in the range **[10, 35]**. I suspect the prior auditors were too shallow. **Your job is to determine empirically whether the framework is genuinely defect-free at this audit depth — or whether deeper probing surfaces real issues.**

## Your scope

Investigate the APEX framework at the current `HEAD` commit. Focus areas (in priority order):

1. **`framework/hooks/`** (60+ hook scripts) — read the source of each guard hook. Look for:
   - Silent-failure branches (any `2>/dev/null` swallowing real errors; any `return 0` or `exit 0` on a failure code path)
   - Regex deny patterns that have known bypass classes (case-folding gaps; word-boundary anchors that admit edge cases; Unicode-equivalent confusables)
   - Stateful guards (exfil-guard, sequence-guard) whose state-transition logic has gaps (off-by-one on threshold; race conditions)
   - Hooks declared in `framework/HOOK-CLASSIFICATION.md` whose actual exit-code behavior differs from their declared category (block/flag/log-only)

2. **`framework/agents/`** — agent definition files (executor.md, critic.md, verifier.md, framework-auditor.md, round-checker.md, etc.). Look for:
   - Procedural instructions that lack enforcement (instruction says "MUST X" but no test fixture verifies)
   - Three-place-contract violations (a contract declared in agent.md but missing from settings.json OR from test layer)
   - Audit-trail emission claims that aren't checkable (says "emit event X" but no schema validates X)

3. **`framework/schemas/`** — JSON schemas. Look for:
   - Schema-vs-implementation drift (schema says field X required; implementation emits without X)
   - `additionalProperties: false` violations
   - Missing schemas for emitted event types in `.apex/event-log.jsonl`

4. **`apex-spec.md`** — the binding specification. Look for:
   - Internal contradictions (TOC entry pointing to non-existent body section; principles that contradict each other)
   - "MUST" statements that aren't anchored to any specific file/mechanism
   - Forward-references that should have shipped by now (any "Phase N" deliverable whose phase has passed)

5. **`framework/tests/`** — the test suite itself. Run `bash framework/tests/run-all.sh` and observe. Look for:
   - Failing tests (any failed:>0 in the summary)
   - Tests that PASS but assert nothing meaningful (vacuous tests; `+0` counter patterns; comment-only assertions)
   - Tests missing for spec-named hooks (some guard has no dedicated test file)

## Your procedure (BINDING)

### Phase 1 — Open exploration

Spend at least **15 minutes** of pure read-only investigation. Use Explore agents in parallel if helpful. Do NOT yet decide what's a "real defect" — just GATHER observations.

### Phase 2 — Anchor every observation

For each observation from Phase 1, verify:
- The observation is anchored to a SPECIFIC file + line number
- The observation contradicts a SPECIFIC apex-spec.md anchor OR an internal cross-reference
- The observation is REPRODUCIBLE by an independent reader

If you can't anchor it, drop it. Anti-fabrication discipline is mandatory.

### Phase 3 — Classify severity

For each anchored observation, assign:
- **P0** — Spec-mandated mechanism missing or broken; affects a P0/P1 IMP in apex-spec.md
- **P1** — Spec-mandated mechanism degraded; affects P1/P2 IMP
- **P2** — Cross-contract drift between two artifacts (schema↔impl, doc↔code, etc.)
- **P3** — Documentation gap or forward-reference inconsistency

### Phase 4 — Output a structured plan document

Per Plan Mode protocol: write your findings to the plan file the harness specifies. Structure:

```markdown
# AC-6B Independent Probe — Findings

## Methodology used
[Describe: what specific search strategies did you employ? What did you grep for? What files did you read?]

## Total observations
- Anchored findings: N
- P0/P1/P2/P3 breakdown
- Confidence assessment per area

## Findings list (F-NNN format)

### F-001 [Severity]: <title>
- **File / Line:** ...
- **Spec anchor:** apex-spec.md line N or cross-reference
- **Evidence:** ...
- **Reproduction:** ...
- **Suggested fix (optional):** ...

[Repeat for each finding]

## Areas explicitly investigated with 0 findings
- ...

## Methodology lessons (most important!)

If you found N findings: describe **what specific technique surfaced them that a shallow audit would have missed**. Examples:
- "I grepped for `2>/dev/null` and found 3 silent-failure paths"
- "I ran `diff` between schema X and impl Y and found 2 drifts"
- "I ran the test suite and observed 2 failures"

The owner cares about HOW you found them as much as WHAT you found.

If you found 0 findings after rigorous Phase-1+2+3 investigation, say so explicitly — that confirms the framework is genuinely clean at this depth.
```

## Anti-fabrication rules (BINDING)

- **NEVER manufacture findings to meet a quota.** If the framework is clean, report it clean. Honest 0 is better than dishonest 10.
- **NEVER inherit findings from any prior audit.** You have no prior context; do not invent one.
- **EVERY finding MUST cite a file + line + spec anchor.** Unanchored claims are dropped.
- **Test the framework. Don't trust documentation.** If a doc says "X exists," verify X exists. If a spec says "MUST Y," verify Y is enforced.

## Tool budget

Use up to **300 tool calls**. If you reach the budget without finishing Phase-1+2+3 honestly, report your incomplete state with `BLIND SPOT — investigation incomplete due to budget.`

## Output

Output goes to the plan file via Plan Mode workflow. The owner will paste your output into the Phase-7 master session's findings file.

---PROMPT END---

---

## Owner's expected outcome routing (from PHASE-7-MASTER-PLAN.md §3)

- **Fresh agent reports 0 findings after rigorous investigation** → framework genuinely clean. Owner approves §14 amendment to AC-6b: lower bound from 10 → 0. Close R-AT-C-04.
- **Fresh agent reports N≥1 findings** → analyze HOW the agent found them. Apply the methodology to `framework/agents/specialist/framework-auditor.md` (axis-1, axis-12, or new axis as needed). Re-run T7 NC trial to verify the upgraded auditor surfaces ≥10. Then close R-AT-C-04 with empirical evidence.

In both cases the Phase-7 master session resumes with concrete evidence rather than guessing.
