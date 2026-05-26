# R-DH-P7-02 — Design (G1) · raise self-heal Step A budget 400 → 800

**Closes:** L-DH-02 (Working-corpus Class D/E joint 1/4 — auditor budget exhaustion at ~400 tool calls).
**Spec anchor:** `apex-spec.md` IMP-007 + IMP-V8-CB2 (circuit-breaker contract); `detector-review/FINAL-CERTIFICATION.md` §3 L-DH-02.
**Date:** 2026-05-26.

---

## §1. Root cause (G0)

Per `detector-review/FINAL-CERTIFICATION.md` §3 L-DH-02:

> "Every Phase-6 detector trial hit the circuit-breaker at 400-410 tool calls during Axis 13 probing. Axes 4, 6, 7, 11, 12 were declared BLIND SPOT in 3 of 6 trials. W-D1/W-D2 (vacuous tests) and W-E1/W-E2 (credential-shaped string and dead-function-removing-STATE) live in axes the trials didn't reach in budget."

The 400 cap is a self-heal Step A convention. Doubling to 800 gives the framework-auditor enough headroom to reach axes 4/6/7/11/12 + new axis-13.c source-literal scan + axis-13.e runtime-contract probes without circuit-breaker trip.

## §2. Design (2 changes)

### Change A — `framework/commands/apex/self-heal.md` BREAKER COUNTER MANAGEMENT

**Three descriptive "400" references** at lines 43, 85, 268 → change to "800". These are prose mentions of the conventional budget.

**Add explicit budget-bump step** at "First-Run Initialization" (before Step A invocation): if `STATE.circuit_breaker.max_tool_calls_per_task < 800`, raise to 800 via `_state_update`. This makes self-heal actively ensure the budget rather than relying on the user's STATE.json default.

Insert at lines 138-140 (or equivalent — after the First-Run Initialization persist step, before Step A invocation):

```
**Phase-7 R-DH-P7-02 budget contract:** ensure
`STATE.circuit_breaker.max_tool_calls_per_task >= 800` before
Step A. If lower, raise to 800 via:

source framework/hooks/_state-update.sh
APEX_HOOK_SOURCE=self-heal _state_update '
  if (.circuit_breaker.max_tool_calls_per_task // 0) < 800
  then .circuit_breaker.max_tool_calls_per_task = 800
       | .circuit_breaker.cap_original = 800
  else . end
'

Rationale: closes L-DH-02 (D/E class reachability) per
detector-review/FINAL-CERTIFICATION.md §3 — Phase-6 trials hit
the breaker at 400-410 calls before reaching axes 4/6/7/11/12.
Doubling the per-unit budget gives the auditor headroom for the
expanded axis-13 sub-passes (13.c source-literal scan +
13.e runtime-contract probe + the existing 13.a/13.b).
```

### Change B — `framework/commands/apex/self-heal.md` reset block update

The `RESET_BREAKER` snippet at lines 52-66 reads `cap_original // max_tool_calls_per_task` — this means after the bump, the cap_original locks at 800 and subsequent resets honor that. **No change needed** to the snippet itself — Change A's budget-bump is sufficient.

Optional clarifying note appended to the snippet's surrounding prose:

> "After R-DH-P7-02 (Phase-7), the canonical per-unit budget is **800** tool calls (was 400). Each step transition + wave boundary still gets a fresh 800-call budget; cap_original = 800 locks the floor."

---

## §3. Out-of-scope (explicit)

**Stage-typed budget per IMP-DR-011** — the master plan §5 mentions adding stage-typed budgets per IMP-DR-011 ("scan/edit/test/critic stages with budget_tokens, budget_calls, stop_on per-stage"). IMP-DR-011 is a Phase-12 sub-deliverable per its DR-prefix and would require:
- `framework/schemas/PLAN_META.schema.json` extension
- `framework/hooks/circuit-breaker.sh` refactor from task-scoped to stage-scoped budgeting
- New PLAN_META.json fields per task

This is significant scope and IS NOT REQUIRED to close L-DH-02 empirically — the simple 400→800 raise gives the auditor enough headroom (W-D/W-E class budget reachability is the binding criterion, not stage-typed accounting). 

**Reserved as R-AT-P7-08 candidate** (Phase-8 or future Phase-7 extension if owner authorizes). L-DH-02 closes via Change A alone.

## §4. Blast radius

| File | Touched? | Lines | Consumers |
|------|---------:|------:|-----------|
| `framework/commands/apex/self-heal.md` | MODIFIED (3 descriptive `400→800` swaps + 1 budget-bump insertion) | -3 / +14 | Self-heal orchestrator runs |
| `detector-review/FINAL-CERTIFICATION.md` §7 R-item 2 | MODIFIED (closure note) | +3 lines | Phase-7 closure tracking |
| `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-DH-P7-02 | MODIFIED (closure note) | +3 lines | Phase-7 closure tracking |

3 files. No agent/schema changes.

## §5. G4 validation

Manual verification:
1. `grep -c '800' framework/commands/apex/self-heal.md` returns ≥4 (3 prose mentions + 1 budget-bump block).
2. `grep -c '400' framework/commands/apex/self-heal.md` returns 0 (all `400` descriptive mentions replaced; only the budget-bump's `< 800` remains).
3. Self-heal command invocation (if testable in this session) would persist `max_tool_calls_per_task=800` in `.apex/STATE.json` — out of scope for layer test; verified via prose contract.

No layer test extension — the change is configuration prose, not enforceable mechanism.

## §6. G5 PASS criteria

1. ✅ Three `400` references in self-heal.md replaced with `800`.
2. ✅ Budget-bump block inserted at First-Run Initialization.
3. ✅ Stage-typed budget per IMP-DR-011 explicitly documented as out-of-scope.
4. ✅ Detector-review FINAL-CERT + PHASE-7-MASTER-PLAN closure notes.
5. ✅ No regression in existing 55/55 layer tests (this R-item doesn't touch the test suite).

## §7. Implementation plan (G3 — 1 commit)

Single commit:
1. Edit `framework/commands/apex/self-heal.md` — 3 prose swaps + budget-bump insertion + RESET_BREAKER clarifying note.
2. Append closure note to `detector-review/FINAL-CERTIFICATION.md` §7 R-item 2.
3. Append closure note to `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-DH-P7-02.

Sync to `~/.claude/commands/apex/` install path.

## §8. Decision summary

**Strategy:** simple 400→800 raise in self-heal.md prose + explicit budget-bump step in First-Run Initialization. Stage-typed budget per IMP-DR-011 deferred as out-of-scope (separate Phase-12 deliverable).

**Blast radius:** 3 files. Minimal.

**Next gate:** G2 critic R1.
