# R-DH-P7-02 — Critic R1 Verdict
**Verdict:** PASS-WITH-CHANGES
**Date:** 2026-05-26
**Reviewer:** clean-room adversarial critic
**Anchor docs read:** `audit-trail-review/PHASE-7-RITEM-R-DH-P7-02-DESIGN.md`,
`framework/commands/apex/self-heal.md` (lines 1-428), `framework/hooks/circuit-breaker.sh`,
`detector-review/FINAL-CERTIFICATION.md` §3 / §7, `apex-spec.md` IMP-DR-011 (line 99).

---

## Per-criterion verdicts [1-7]

### 1. 400 → 800 mechanical safety — **PASS**

`circuit-breaker.sh` reads `max_tool_calls_per_task` via `jq -r ... // 80` (line 142)
and compares as a shell integer in CHECK 2 (`[ "$TOOL_CALLS" -ge "$SOFT_CAP" ]`,
line 173). Bash integer arithmetic handles 800 — and indeed handles `cap_original/2`
extensions (e.g. 800 + 400 = 1200, 1200 + 400 = 1600 …) without any upper bound
in code. **No upper cap exists** (CHECK 2 comments explicitly say "no upper bound
on extensions"). The numeric guard `[ "$BASIS" -le 0 ] && BASIS="$SOFT_CAP"` (line
203) only catches degenerate zero. 800 is mechanically safe.

### 2. First-Run Initialization location — **PASS-WITH-MINOR-NOTE**

The design says "insert at lines 138-140 (or equivalent — after the First-Run
Initialization persist step, before Step A invocation)". The actual line numbers
are stale: lines 138-140 of `self-heal.md` are inside step (c) "Compute
`consecutive_clean_rounds_before`" of First-Run Init, NOT after the persist
step. The persist step (e) ends around line 162; MAIN LOOP starts at line 169.
**The correct insertion line is ~165-168** (after step (e) persist, before "## MAIN
LOOP"). The prose description in the design is correct; only the numeric anchor
is wrong. G3 implementer must use the prose description, not the line numbers.

Non-blocking suggestion: update the design's "lines 138-140" → "lines 165-168
(after First-Run Init step (e) persist, before `## MAIN LOOP`)".

### 3. Budget-bump jq idempotency — **PASS-WITH-LATENT-EDGE-CASE**

The jq:
```
if (.circuit_breaker.max_tool_calls_per_task // 0) < 800
then .circuit_breaker.max_tool_calls_per_task = 800
     | .circuit_breaker.cap_original = 800
else . end
```

**Syntax:** valid jq (verified by reading: `if/then/end` form with `else` is
correct, `|` pipes work between assignments).

**Idempotency on the happy path (default 80 OR previously 400):** PASS.
- 80 < 800 → both fields set to 800. Re-run: 800 is NOT < 800 → no change. Stable.
- 400 < 800 → both fields set to 800. Re-run: stable.

**Latent edge case (HIGH severity, non-blocking for closure):** consider the
state `max_tool_calls_per_task = 1200` (legitimate after a healthy CHECK-2
extension during a long Step A) AND `cap_original = 400` (the original cap from
before this R-item landed). The bump's predicate `1200 < 800` is FALSE → `else
.` → no change → `cap_original` stays at 400. Then the existing RESET_BREAKER
snippet at lines 63-64 reads `cap_original // max_tool_calls_per_task` = 400 →
resets `max_tool_calls_per_task = 400`. **The bump effectively undoes itself on
the next wave boundary.**

This is a real concern given the install scenario: users with an in-flight
self-heal session on R-DH-P7-02's commit boundary may carry `cap_original = 400`
in their STATE.json. The fix is a tighter jq:

```
if (.circuit_breaker.cap_original // 0) < 800
then .circuit_breaker.max_tool_calls_per_task = 800
     | .circuit_breaker.cap_original = 800
else . end
```

(predicate keyed on `cap_original`, not `max_tool_calls_per_task`, because
`cap_original` is the durable floor; `max_tool_calls_per_task` is the volatile
extension target). With this swap, the bump becomes truly idempotent across
healthy-extension states.

**Verdict: works on fresh STATE.json + on previously-400-bumped STATE.json.
Edge case affects only mid-flight upgrade scenarios. Recommend tightening the
predicate per above before G3 implementation.**

### 4. Per-unit consistency across wave transitions — **PASS**

Trace, assuming the predicate-fix from §3 is adopted:

- T0 (First-Run Init): bump runs, `max=800, cap_original=800`.
- T1 (RESET before Step A): line 63-64 reads `cap_original // max = 800` → sets
  `max = 800`. Stable.
- T2 (Step A runs 500 tool calls; CHECK 2 fires healthy extension at 800 →
  `max = 1200`). Probe healthy → continues.
- T3 (Step A completes; RESET before Step B). Line 63-64 reads `cap_original =
  800` (set by Init), preserves it. `max = (cap_original // max) = 800`. **Floor
  restored to 800.**
- T4 (Wave 1 RESET inside Step D): same — `cap_original = 800` survives, `max =
  800`.
- T5 (next round, RESET at line 384): same.

**Each step + wave boundary gets a fresh 800-call budget, cap_original = 800
locks the floor.** Per-unit consistency is sound IF §3's predicate-on-cap_original
fix lands. With the design's current predicate-on-max, the §3 edge case can
silently degrade the floor back to a previous lower value.

### 5. IMP-DR-011 deferral justification — **PASS**

Verified `apex-spec.md` line 99: IMP-DR-011 is a **P1** doctrinal-research
implementation requiring (a) PLAN_META.schema.json extension with stage-typed
budget fields, (b) circuit-breaker.sh refactor from task-scoped to stage-scoped
budgeting, (c) new per-stage `budget_tokens / budget_calls / stop_on` fields.
This is genuinely separable from L-DH-02 closure:
- L-DH-02's root cause per FINAL-CERTIFICATION.md §3 is **per-task budget
  insufficient at 400** during Axis 13 probing — NOT a granularity-of-budgeting
  problem.
- The auditor only spans one stage (Step A = single Task() invocation = single
  budgeting unit from the breaker's POV). Stage-typed budgets would benefit
  multi-stage executor flows (scan/edit/test/critic), not the single-stage
  auditor.
- Doubling the per-task budget to 800 empirically gives the auditor headroom
  (per detector-review §3 quantitative estimate). IMP-DR-011 would also raise
  the auditor budget but as a side-effect of a much larger refactor.

**Deferral is defensible.** The design's framing as "Phase-8 or later cycle"
candidate is correct. Spec anchor cited (line 99) matches the design's claim.

### 6. W-D/W-E reachability empirical claim — **PASS (qualitative)**

Per `detector-review/FINAL-CERTIFICATION.md` §3 L-DH-02:
- Phase 2 R201: 70 tool calls → 0 of 6 axis-13 targets caught.
- Phase 6 R311: 400+ tool calls → 6 caught (axes 13.a/13.b reached but 4/6/7/11/12
  declared BLIND SPOT in 3 of 6 trials).
- 800 cap: should let the auditor finish 13.c source-literal scan (R-DH-P7-01
  delivered) + 13.e runtime-contract probes + axes 4/6/7/11/12 read-pass.

**Caveat:** the claim is qualitative, not measured. The design has no empirical
800-cap trial (and G5 explicitly says "self-heal command invocation … out of
scope for layer test; verified via prose contract"). This is acceptable because
(a) the alternative is a multi-hour Phase-6-equivalent re-run, (b) the math is
defensible (going from 400→800 mirrors the 70→400 jump that yielded the
0→6 improvement), and (c) the cost of being wrong is "re-open L-DH-02 in a
later R-item" — not silent failure.

**Acceptable as a documented hypothesis to be empirically validated post-merge
during the next live self-heal round.** Recommend adding a §9 note: "L-DH-02
closure is contingent on the next live self-heal round reaching W-D/W-E targets;
if axes 4/6/7/11/12 again decline as BLIND SPOT at 800, re-open as R-DH-P7-02b
with IMP-DR-011 stage-typed budgets."

### 7. Adversarial probe: doubling weakens no-change-loop detection? — **PASS**

The two breaker modes use **independent fields**:
- Tool-call cap (CHECK 2): `max_tool_calls_per_task` (the field this R-item
  doubles, default 80).
- No-change loop (CHECK 1): `max_allowed` (default 3; verified via
  `circuit-breaker.sh:43` — `jq -r '.circuit_breaker.max_allowed // 3'`).

These two fields are read separately, compared separately, and trip separately.
Doubling `max_tool_calls_per_task` to 800 has **zero effect** on the no-change-loop
detection logic. CHECK 3 (recurring error) and CHECK 4 (result fishing) use
their own threshold of 5 and FIFO window of 20 — also unaffected.

**No adversarial-weakening failure mode identified.**

---

## Blocking findings

**None.** No CRITICAL or BLOCKING findings.

## Non-blocking suggestions (3, ordered by impact)

1. **[MINOR-MEDIUM]** Tighten the budget-bump jq predicate to key off
   `cap_original` instead of `max_tool_calls_per_task`:
   ```
   if (.circuit_breaker.cap_original // 0) < 800
   then .circuit_breaker.max_tool_calls_per_task = 800
        | .circuit_breaker.cap_original = 800
   else . end
   ```
   Closes the latent edge case in §3 where a mid-flight `max=1200,
   cap_original=400` state silently degrades the floor back to 400 on the next
   RESET. The fix is a one-token swap with no other consequences.

2. **[MINOR]** Update the design's "lines 138-140" anchor to "lines 165-168
   (after First-Run Init step (e) persist, before `## MAIN LOOP`)". Current
   line numbers point inside step (c), not after the persist step. The prose
   description is correct; only the numeric anchor is stale.

3. **[MINOR]** Add a §9 caveat to the design: "L-DH-02 closure is contingent on
   the next live self-heal round empirically reaching W-D/W-E axes at the
   800-call budget. If axes 4/6/7/11/12 again decline as BLIND SPOT, re-open as
   R-DH-P7-02b with IMP-DR-011 stage-typed budgets." Makes the deferral
   reversible by explicit criterion.

## Final verdict

**PASS-WITH-CHANGES.** The R-DH-P7-02 design closes L-DH-02 mechanically
(circuit-breaker.sh handles 800 safely; no-change-loop detection is independent
and unaffected; IMP-DR-011 deferral is defensible per spec anchor). The
per-unit consistency claim holds IF suggestion 1 (predicate-on-cap_original) is
adopted; otherwise a narrow mid-flight-upgrade edge case can degrade the floor.
Suggestion 2 is a documentation-correctness fix. Suggestion 3 makes the deferral
falsifiable.

**Recommended G3 actions:**
- Apply suggestion 1 to the budget-bump jq before commit.
- Apply suggestion 2 to the design doc's line-number anchor.
- Apply suggestion 3 as a §9 caveat.

None of the three suggestions blocks merge; all three improve robustness or
clarity. The R-item is structurally sound — proceed to G3.
