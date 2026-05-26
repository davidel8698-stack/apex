# G5 Critic — R-AT-P7-06 (closed-artifact review)

**Date:** 2026-05-26
**Reviewer:** clean-room critic
**Commits reviewed:** `d8de013` (impl) + `a0c65d6` (closure follow-up)
**Verdict:** **PASS** (7/7 criteria verified)

---

## §1. Acceptance criteria table

| # | Criterion | Status | Evidence |
|---|-----------|:------:|----------|
| 1 | `test-circuit-breaker-recovery.sh` → 12/12 PASS | VERIFIED | live run: `Results: 12 passed, 0 failed` |
| 2 | `test-fix-plan-emit.sh` → 37/37 PASS | VERIFIED | live run: `=== Results: PASS=37 FAIL=0 ===` |
| 3 | No regression in `test-audit-trail-layer.sh` (55/55) | VERIFIED | live run: `── 55/55 passed (skipped: 0)` |
| 3 | No regression in `test-subagent-cache.sh` (26/26) | VERIFIED | live run: `── 26/26 passed (skipped: 0)` |
| 4 | Closure notes in FINAL-CERTIFICATION §3 + MASTER-PLAN §5 | VERIFIED | FINAL-CERT lines 255-256 (R-AT-P7-06a/b CLOSED 2026-05-26); MASTER-PLAN line 170 (`R-AT-P7-06 — CLOSED 2026-05-26`) + §6 risk row 192 |
| 5 | Fixtures use v8 unhealthy-fire shape (`max=60, total=60, last_change=0, cap_original=60`) | VERIFIED | grep hit at test-circuit-breaker-recovery.sh:113-116, 140-143; test-fix-plan-emit.sh:184-187 — exact shape, STALE_DELTA = 60-0 = 60 > 50 |
| 6 | Comment blocks explain v7→v8 reconciliation | VERIFIED | test-circuit-breaker-recovery.sh:97-104 + test-fix-plan-emit.sh:171-174 (both cite IMP-V8-CB2 + STALE_DELTA derivation) |
| 7 | Hook source NOT modified in R-AT-P7-06 commit range | VERIFIED | `git log HEAD~3..HEAD -- framework/hooks/circuit-breaker.sh` returned empty; `git show --stat d8de013` lists only the 2 test files + 2 docs |

---

## §2. Hook-contract cross-check (independent)

Read `framework/hooks/circuit-breaker.sh` lines 178-181:
```
STALE_DELTA=$(( TOOL_CALLS - TC_AT_CHANGE ))
if [ "$STALE_DELTA" -gt 50 ]; then
   ...
   REASON="no file changes in last ${STALE_DELTA} tool calls (stagnant)"
```
Fixture math: TOOL_CALLS=60, TC_AT_CHANGE=0 → STALE_DELTA=60 → `60 > 50` is TRUE → probe 1 stagnant detection trips → HEALTH_OK=0 → unhealthy fire branch → exit 2. The fixture exercises EXACTLY the path the tests assert.

The old v7 fixtures (max=2,total=2 or max=1,total=1) yielded STALE_DELTA=2 or 1 (both ≤ 50) → HEALTH_OK=1 → cap extended → exit 0 → assert exit 2 fails. The Wave-0 diagnosis is structurally correct.

---

## §3. Adversarial probes (5 attempted, 0 hit)

1. **Does `cap_original=60` create downstream incoherence?** No. Hook line 134 reads `cap_original` only on the healthy-extend path (`max_tool_calls_per_task = cap_original * (TOOL_CALLS/cap_original + 1)`). The fixture forces the unhealthy branch (probe 1 trips before line 134 is reached), so `cap_original` is read for the initial snapshot only — `60` is internally consistent with `max_tool_calls_per_task=60`.

2. **Does the menu assertion ("three options") survive the new fixture?** Yes. The menu content (`/apex:forensics`, `/apex:rollback`, `/apex:recover`) is emitted by the unhealthy-fire branch identically to the old code path; the new fixture only changes WHICH branch fires, not the menu content. 12/12 confirms.

3. **Could a stale `consecutive_no_change_actions=0` block probe 1?** Checked hook: probe 1 (`STALE_DELTA > 50`) is independent of `consecutive_no_change_actions` (which feeds the no-change-loop probe, not the stagnant-tool-call probe). Independent trigger paths; no coupling.

4. **Is `cap_original` field actually a known/valid STATE.json key, or is it being invented?** `git grep cap_original` shows the hook itself reads + writes this field (line 134 `cap_original = .cap_original // .max_tool_calls_per_task // 80`). Confirmed schema-valid.

5. **Could the test now pass for the WRONG reason (e.g., a different probe firing)?** The test assertions are: exit 2 + RECOVERY_MENU.md written + 3 options present + stderr names the menu. All four are common to every unhealthy-fire path (probe 1, 2, or 3 all converge to the same emit). So even if probe 1 weren't the active trigger, the test would still validate the v8 unhealthy-fire contract correctly. Defense-in-depth: the assertion set is not over-specified for probe 1.

---

## §4. Closure-note inspection

- **FINAL-CERTIFICATION.md §5** (lines 253-256): R-AT-P7-06a and -06b each annotated `**CLOSED 2026-05-26 (R-AT-P7-06):** ...` with the correct root cause (v7-vs-v8 IMP-V8-CB2 drift) and the correct evidence (12/12 + 37/37).
- **PHASE-7-MASTER-PLAN.md §5** (line 170): `R-AT-P7-06 — Closes pre-existing test failures — CLOSED 2026-05-26`.
- **PHASE-7-MASTER-PLAN.md §6** (line 192) risk row: "If real: fix the defect, not the test" — the commit message explicitly invokes this rule and correctly identifies the test as the defect (not the hook).
- **PHASE-7-RITEM-R-AT-P7-06-DESIGN.md**: confirmed NEW in `d8de013` via `git show --stat`.

---

## §5. STEP 1.5 git-trace check

All 4 files listed in commit `d8de013` are visible in `git log --name-only HEAD~2..HEAD`:
- `audit-trail-review/PHASE-7-MASTER-PLAN.md` (modified)
- `audit-trail-review/PHASE-7-RITEM-R-AT-P7-06-DESIGN.md` (NEW)
- `framework/tests/test-circuit-breaker-recovery.sh` (modified)
- `framework/tests/test-fix-plan-emit.sh` (modified)

Follow-up commit `a0c65d6` adds `audit-trail-review/FINAL-CERTIFICATION.md` (modified). All declared changes are on the git trail. `git_trace_check: PASS (5 files matched git views)`.

---

## §6. Verdict

**PASS — 7/7 G5 criteria verified.**

Single-iteration R-item executed cleanly. Wave-0 probe correctly identified root cause as v7-vs-v8 IMP-V8-CB2 contract drift; fixtures updated minimally and surgically (4 STATE.json blocks across 2 files) to force the v8 unhealthy-fire branch via STALE_DELTA > 50. Hook source untouched (spec contract preserved). Closure notes propagated to both FINAL-CERTIFICATION and MASTER-PLAN. 4 affected test files green (12/12 + 37/37 + 55/55 + 26/26 = 130/130 PASS).

No critical findings. No major findings. No phantom evidence. R-AT-P7-06 closes Campaign B's L-AT-PreExistingTests-01 limitation cleanly.

**Closure approved.**
