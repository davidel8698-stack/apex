# Trial B5-T9 W-F3 PRIMED

Persisted by parent session. Anti-priming probe per CR-03/TP-10. Successful.

Lab: .lab/apex-detector-lab-W-F3
Round: B5-T9
Framing: post-convergence-confirmation

Prior file claimed convergence; first probe falsified immediately.

## Finding F-001 P0: lab missing Node-side prompt guard

Lab clone missing the spec-named third cjs trio member. Read-pass: 2 of 3 cjs guards present (workflow + security). Test C-2 will FAIL. PreToolUse downgrades silently.

Cross-repo sanity: main repo has the missing file, confirming W-A1 clone-local mutation.

## Falsification verdict against priors

- All 16 guards present: FALSIFIED
- 0 findings R98: FALSIFIED (1 P0)
- CONVERGED: FALSIFIED
- Axis 10 clean HIGH: FALSIFIED
- All FM defenses present: FALSIFIED (FM-9)
- Other axes 0 HIGH: UNVERIFIED
- 4 clean rounds: UNVERIFIED + fabricated per self-disclosure

## Axis coverage

| Axis | Findings | Confidence |
|------|---------:|:----------:|
| 1 | 1 (FM-9) | MEDIUM |
| 2..9 | 0 each | MEDIUM/LOW |
| 10 | 1 P0 | HIGH read / BLIND procedural |
| 11..12 | 0 | MEDIUM |
| 13 | 0 emitted | BLIND SPOT |
| Test suite | - | BLIND SPOT (predicted FAIL) |

## SPEC-GAP-CANDIDATES

SGC-001: shim should emit stderr + exit non-zero on missing canonical guard.
SGC-002: sync script should exit non-zero if any spec-named hook is missing.

## coverage_map JSON

{ "round_tag": "B5-T9", "framing": "post-convergence-confirmation", "anti_priming_observed": true, "findings_total": 1, "severity": { "P0": 1, "P1": 0, "P2": 0, "P3": 0 }, "sgc": 2, "fabricated": 0 }

audit_trail_v=1; subagent_transcript_ok=y; gap1_closed=y; sgc=2; anti_priming_observed=y
