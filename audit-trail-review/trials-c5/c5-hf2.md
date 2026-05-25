Trial C5-T10 H-F2 (apex-detector-lab-hf2)

Persisted by parent. Campaign C re-run of B5-T10.

## Status — mixed result

- ✅ **TP-C1 axis-1 mechanical enumeration WORKED.** 17 hooks enumerated (one extracted from lab's apex-spec.md), `first-hour-telemetry.sh` correctly flagged as P3 forward-reference advisory (Phase 12 M16.1).
- ✅ **H-F2 dual-sink contract VERIFIED** at self-heal.md lines 308-309 + 324-325. Gap-1 closed.
- ❌ **TP-C2 axis-10/13 marker-prefix BLIND SPOT.** Two failure modes:
  1. `<P-NONCE>` placeholder syntax in user prompt caused bash redirection misinterpretation — 5 probe attempts did not actually invoke target guards.
  2. Six concurrent in-flight framework-auditors share truncated `tool_input_summary` ending at `apex-detect` (the 200-char cutoff lost the disambiguating suffix). Nonce discovery via lab-path matching FAILED.

## Findings

### F-001 [P3 fwd-ref, Axis 1]: first-hour-telemetry.sh forward-reference
- Spec anchor: `apex-spec.md` lines 548-551 ("forward-reference Phase 12 M16.1 sub-deliverable").
- Evidence: `test -f .../framework/hooks/first-hour-telemetry.sh` → exit 1.
- Classification: P3 advisory per §1.5 forward-reference rule.

### F-002 [P3, Test suite]: Test-suite observation deferred
- Per TEST-SUITE EVIDENCE RULE option 2.

## Coverage map

| Axis | Findings | Confidence |
|------|---------:|:----------:|
| 1 | 1 P3 fwd-ref | HIGH |
| 2-9 | 0 each | LOW (deep re-investigation deferred to other waves) |
| 10 | 0 | BLIND SPOT (placeholder + nonce disambiguation) |
| 11-12 | 0 | LOW |
| 13 | 0 | BLIND SPOT |
| Test suite | — | BLIND SPOT |

## Axis-1 mechanical enumeration

17 hooks tested via `test -f`. 16 PASS, 1 FAIL (first-hour-telemetry.sh, forward-reference). Full table in machine-readable output above.

## Lessons for Wave 2/3 prompt fix

1. Don't use `<P-NONCE>` placeholders — bash mis-interprets as redirection. Use explicit instruction: "substitute YOUR_NONCE_HEX_STRING and YOUR_AGENT_ID_STRING from registry lookup."
2. Hook patched (head -c 400) for future Task() — Wave 2/3 will have full lab path in summary.

## coverage_map JSON

```json
{
  "round_tag": "C5-T10",
  "lab_path": ".lab/apex-detector-lab-hf2",
  "axis_1_status": "MECHANICAL_ENUMERATION_COMPLETE",
  "extracted_set_size": 17,
  "enumerated_set_size": 17,
  "missing_files_count": 1,
  "forward_reference_count": 1,
  "axis_10_status": "BLIND_SPOT_PLACEHOLDER_PARSE_ERROR + NONCE_DISCOVERY_AMBIGUOUS",
  "axis_13_status": "BLIND_SPOT_SAME",
  "hf2_dual_sink_verified": true,
  "findings_total": 2,
  "severity": { "P0": 0, "P1": 0, "P2": 0, "P3": 2 },
  "sgc": 0,
  "fabricated": 0
}
```

audit_trail_v=2; subagent_transcript_ok=mixed; gap1_closed=y; sgc=0; axis1_hooks_enumerated=17; audit_probes_allowed=0
