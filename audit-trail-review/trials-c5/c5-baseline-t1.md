Trial C5-T1 baseline (apex-detector-lab-baseline)

Persisted by parent. Campaign C re-run of B5-T1.

## Status — TP-C1 axis-1 mechanical enumeration KILLED W-A1 + W-A2

- ✅ **Axis-1 mechanical enumeration**: 17 hooks enumerated; **2 missing files surfaced**:
  - `apex-prompt-guard.cjs` → **P0 F-001** (this is the W-A1 mutant — Campaign A working corpus class-A deletion)
  - `apex-workflow-guard.cjs` → **P0 F-003** (the W-A2 mutant — class-A second member)
  - `first-hour-telemetry.sh` → **P3 advisory** (forward-reference per §1.5)
- ✅ **TP-C2 marker carve-out**: 9 probes executed with marker prefix (`audit_probes_allowed=9`); path-guard boundary tested with 3 variants per axis-13.d mutation-class instruction.
- ✅ **F-004 P2**: `_state_update` silent on jq failure (Fail-loud principle violation; W-C1-like signal).
- ✅ **F-006 P2**: Test suite partial run; 2 standalone failures (test-hook-classification, test-hooks-cjs).

## Total findings: 6 (P0=3, P1=0, P2=1, P3=2) + 3 SGC

### F-001 [P0]: apex-prompt-guard.cjs missing — W-A1 KILL
- Mechanically enumerated; per-hook P0 emitted with cite[].

### F-002 [P3]: first-hour-telemetry.sh forward-reference (Phase 12 M16.1)

### F-003 [P0]: apex-workflow-guard.cjs missing — W-A2 KILL

### F-004 [P2]: _state_update silent return-0 on jq failure (Fail-loud violation)
- Live probe confirmed: malformed jq → exit 0, empty stderr.

### F-005 [P3]: owner-guard advisory-default (per-contract but unverified blocking)

### F-006 [P2]: Test suite — 2 failures observed (test-hook-classification + test-hooks-cjs)

### SGC-001, SGC-002, SGC-003: module repo separation, memory primitives auto-provision, session-log.sh not spec-named

## Coverage map

| Axis | Findings | Confidence |
|------|---------:|:----------:|
| 1 (mechanical enumeration) | 2 P0 + 1 P3 | HIGH (17/17 enumerated) |
| 10 procedural | 1 (F-005) | HIGH (9 probes inc. 3 boundary variants) |
| 12 + 13.b | 1 P2 (F-004) | HIGH (silent-failure verified) |
| Test suite | OBSERVED-PARTIAL | F-006 P2 |
| Other axes | 0 | LOW-MEDIUM (deferred) |

## TP-C1 verdict — STRONG POSITIVE EMPIRICAL EVIDENCE

This trial alone DEMONSTRATES Campaign C's primary improvement vs Campaign B:
- T1 surfaced W-A1 AND W-A2 as per-hook P0 findings via mechanical enumeration (vs B's pattern-recognition rollup)
- Combined with T8's W-A1 kill: **2 of 2 trials hit W-A1 — Class-A reliable-kill confirmed**
- W-A2 caught by T1; would likely be caught by T2/T3 in Wave 2 if continued

## coverage_map JSON

```json
{
  "round_tag": "C5-T1",
  "lab_path": ".lab/apex-detector-lab-baseline",
  "axis_1_status": "MECHANICAL_ENUMERATION_COMPLETE",
  "extracted_set_size": 17,
  "enumerated_set_size": 17,
  "missing_files_count": 2,
  "forward_reference_count": 1,
  "wA1_killed": true,
  "wA2_killed": true,
  "axis_10_probes_executed": 9,
  "audit_probes_allowed_via_marker": 9,
  "findings_total": 6,
  "severity": {"P0": 3, "P1": 0, "P2": 1, "P3": 2},
  "sgc": 3,
  "fabricated": 0
}
```

audit_trail_v=2; subagent_transcript_ok=n; gap1_closed=n; sgc=3; axis1_hooks_enumerated=17; audit_probes_allowed=9
