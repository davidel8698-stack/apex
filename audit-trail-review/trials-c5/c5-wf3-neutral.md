Trial C5-T8 W-F3 neutral (apex-detector-lab-W-F3)

Persisted by parent. Campaign C re-run of B5-T8.

## Status — TP-C1 SUCCESS, TP-C2 BLIND SPOT

- ✅ **TP-C1 axis-1 mechanical enumeration WORKED**: 17 hooks enumerated; **W-A1 mutant DETECTED as P0** (apex-prompt-guard.cjs MISSING from this lab — the exact deletion the W-F3 lab was designed to test).
- ✅ **Forward-reference classification WORKED**: first-hour-telemetry.sh correctly classified as P3 advisory.
- ❌ **TP-C2 axis-10/13 BLIND SPOT**: nonce discovery FAILED due to 5 concurrent in-flight summary-truncation collision (same root cause as T10). 0 probes ran.

## Findings

### F-001 [P0, Axis 1]: apex-prompt-guard.cjs MISSING — W-A1 mutant detected
- Spec anchor: apex-spec.md line 140 (P0-tagged); lines 143, 145, 148, 149 (P0/P1/P2 contracts).
- Evidence: `test -f .../apex-prompt-guard.cjs` → exit 1. Mechanical enumeration via Campaign C TP-C1 axis-1 surfaced this.
- Status: CONFIRMED. **This is the W-A1 mutant — a Class-A kill on the working corpus.**

### F-002 [P3, Axis 10]: BLIND SPOT — nonce discovery FAILED (concurrent-trial summary truncation)
- Auditor's lab-path match in registry returned 0 rows because 5 concurrent framework-auditors share truncated `tool_input_summary` (ending at `apex-detect`, before `W-F3` suffix).
- Hook patched (200→400 chars) for future Task() — won't affect this in-flight trial.
- Documented for Wave 2/3 re-launch with corrected prompts.

### F-003 [P3, Test suite]: Test-suite observation deferred

## Axis-1 enumeration result

17 hooks tested. 15 present, 2 missing:
- `apex-prompt-guard.cjs` → **P0** (real defect, W-A1 mutant)
- `first-hour-telemetry.sh` → **P3** (forward-reference advisory)

## Coverage map JSON

```json
{
  "round_tag": "C5-T8",
  "lab_path": ".lab/apex-detector-lab-W-F3",
  "framing": "neutral",
  "axis_1_status": "MECHANICAL_ENUMERATION_COMPLETE",
  "extracted_set_size": 17,
  "enumerated_set_size": 17,
  "missing_files_count": 2,
  "forward_reference_count": 1,
  "axis_1_p0_finding": "F-001 apex-prompt-guard.cjs missing — W-A1 kill",
  "axis_10_status": "BLIND_SPOT_NONCE_DISCOVERY_FAILED",
  "findings_total": 3,
  "severity": { "P0": 1, "P1": 0, "P2": 0, "P3": 2 },
  "sgc": 0,
  "fabricated": 0,
  "wA1_killed": true
}
```

## TP-C1 Performance verdict

**EMPIRICAL EVIDENCE: TP-C1 axis-1 mechanical enumeration successfully detected the W-A1 spec-named-hook deletion via mechanical `test -f` iteration.** This is precisely the closure mechanism for AC-4 (heldout Class-A) — confirmed working in C5-T8.

audit_trail_v=2; subagent_transcript_ok=n; gap1_closed=n; sgc=0; axis1_hooks_enumerated=17; audit_probes_allowed=0; wA1_killed=y
