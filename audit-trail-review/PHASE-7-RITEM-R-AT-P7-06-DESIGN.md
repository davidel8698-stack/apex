# R-AT-P7-06 — Design + Closure (single-iteration) · fix pre-existing v7/v8 test fixture drift

**Closes:** Pre-existing 3-FAIL in `test-circuit-breaker-recovery.sh` + 3-FAIL in `test-fix-plan-emit.sh` (Campaign A `cece2a1` baseline; Campaign B FINAL-CERTIFICATION §3 reservation).
**Spec anchor:** `apex-spec.md` §1 IMP-V8-CB2 (lines 85-86) — "CHECK 2 חייב לעבוד כ-health checkpoint תקופתי, לא כ-cap קשה."
**Date:** 2026-05-26.

---

## §1. Root cause (G0)

The Wave-0 independent probe (`AC-6B-INDEPENDENT-PROBE-FINDINGS.md` F-004 + F-005) diagnosed the failures precisely:

> "F-004 P1: test-circuit-breaker-recovery.sh asserts the v7 tool-call cap behaviour; circuit-breaker.sh now implements the v8 health-probe (IMP-V8-CB2). The test's Case B preloads `total_tool_calls_this_task=2, max_tool_calls_per_task=2` and expects exit 2. The hook's `STALE_DELTA=3` is not `>50`, no recurring error, no result-fishing — health probe HEALTHY → cap extended → exit 0."

Same root in `test-fix-plan-emit.sh` 5g circuit-breaker block (uses `max=1, total=1` — healthy trajectory → cap extension → no FIX_PLAN.md written → 3 assertions FAIL).

**The hook v8 behavior is CORRECT per IMP-V8-CB2; the test fixtures assert the v7 contract that was removed. Fix is in the test fixtures, not in the hook.** Per master plan §6 risk row: "If real: fix the defect, not the test" — here the "defect" IS the test (asserts wrong contract).

## §2. Design + implementation (single iteration)

### Fix A — `framework/tests/test-circuit-breaker-recovery.sh` Cases B + C

Update STATE.json fixtures to force the unhealthy fire branch via probe 1 (stagnant detection: `STALE_DELTA = TOTAL - TC_AT_CHANGE > 50`):

```json
{
  "circuit_breaker": {
    "consecutive_no_change_actions": 0,
    "max_allowed": 3,
    "last_file_hash": "",
    "max_tool_calls_per_task": 60,
    "total_tool_calls_this_task": 60,
    "tool_calls_at_last_change": 0,
    "cap_original": 60,
    "triggered": false
  }
}
```

`STALE_DELTA = 60 - 0 = 60 > 50` → HEALTH_OK=0 → fires exit 2 + emits FIX_PLAN.md / RECOVERY_MENU.md.

### Fix B — `framework/tests/test-fix-plan-emit.sh` 5g block

Same fixture pattern as Fix A. Comment block explains the v8 contract.

### G4 validation (mechanical)

- `bash framework/tests/test-circuit-breaker-recovery.sh` → "Results: 12 passed, 0 failed"
- `bash framework/tests/test-fix-plan-emit.sh` → "Results: PASS=37 FAIL=0"
- `bash framework/tests/test-audit-trail-layer.sh` → "55/55 passed" (no regression)
- `bash framework/tests/test-subagent-cache.sh` → 26/26 (R-DH-P7-03 not regressed)

### G5 PASS criteria

1. Both target tests pass (12/12 + 37/37).
2. No regression in baseline suite.
3. Test name + assertion labels updated to reflect v8 contract ("exits 2 (unhealthy trajectory)").
4. Comment block in each test explains the v7→v8 reconciliation and the STALE_DELTA mechanism.

### Out-of-scope

- Refactoring v8 health-probe logic itself (the hook is correct).
- Adding test coverage for the healthy-cap-extension branch (separate test scope; not blocking R-AT-P7-06).

## §3. Blast radius

| File | Lines | Risk |
|------|------:|------|
| `framework/tests/test-circuit-breaker-recovery.sh` (Case B + C STATE.json + comment) | -22 / +30 | Test-fixture only; no behavior change |
| `framework/tests/test-fix-plan-emit.sh` (5g block) | -7 / +11 | Test-fixture only |
| `detector-review/FINAL-CERTIFICATION.md` §3 L-AT-PreExistingTests-01 / R-AT-P7-06 | +3 (closure note) | Tracking |
| `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-AT-P7-06 | +3 (closure note) | Tracking |

4 files. Minimal scope. Test-fixture-only change.

## §4. Decision summary

Single-iteration R-item (no G2 critic round needed — the Wave-0 probe pre-diagnosed the root cause + the fix; the design is purely "update fixtures to v8 contract per probe's recommended remediation"). G3 + G4 already executed; G5 verification next.

**Strategy:** update 2 test fixtures to force the v8 unhealthy fire branch via stagnant-detection probe. Trust the hook (v8 is correct per IMP-V8-CB2); fix the test.

**Blast radius:** 4 files.

**Next gate:** G5 final critic.
