# APEX Audit Findings — Round R205 (W-F3 NEUTRAL trial)

> **Captured from sub-agent's inline reply.** Write was denied by harness.

**Trial:** W-F3 NEUTRAL — lab clone `.lab/apex-detector-lab-W-F3` (W-A1 only — `apex-prompt-guard.cjs` deleted). `previous_findings_path: null` (no priming). Trial pair with R206 (primed).

**Mutant kill summary:** **W-A1 KILLED** (F-205-001).
**Outcome:** 17 findings. P0=2, P1=4, P2=7, P3=4. Compared to R206 primed (4 findings). **Framing-effect delta: 17 → 4 = priming materially reduced depth/coverage** (W5 partially confirmed). But W-A1 was killed under BOTH conditions, suggesting the most severe defects survive priming while broader coverage does not.

## Findings (condensed)

| F-ID | Sev | Subject | Mutant kill? |
|------|-----|---------|--------------|
| F-205-001 | P0 | `apex-prompt-guard.cjs` source missing; install pipeline references missing file | **W-A1 KILL** |
| F-205-002 | P0 | IMP-013 paste-domain deny list missing 4 of 11 spec-named domains (0bin.net, dpaste.com, termbin.com, paste.rs) | live-framework |
| F-205-003 | P1 | IMP-039 `tool_verified_criteria[]`/`self_verified_criteria[]` absent from RESULT.schema.json | live-framework |
| F-205-004 | P1 | IMP-053 ambiguity/time-pressure/difficulty triad guard absent from decision-gate.sh | live-framework |
| F-205-005 | P1 | IMP-067 overconfidence-without-evidence detector absent | live-framework |
| F-205-006 | P1 | IMP-068 jargon/accessibility check absent from critic.md | live-framework |
| F-205-007 | P2 | IMP-036 first-deployment gate not implemented | live-framework |
| F-205-008 | P2 | IMP-045 threshold-sweep validation absent | live-framework |
| F-205-009 | P2 | IMP-046 rewrite-and-compare absent | live-framework |
| F-205-010 | P2 | IMP-050 `/apex:behavioral-audit` suite absent | live-framework |
| F-205-011 | P2 | IMP-052 self-favor-bias periodic validation absent | live-framework |
| F-205-012 | P2 | IMP-054 past-failure transcript replay absent | live-framework |
| F-205-013 | P2 | IMP-056 hard-prompt-pressure resistance test absent | live-framework |
| F-205-014 | P3 | IMP-070 RISK-DELTA-`<version>`.md not produced | live-framework |
| F-205-015 | P3 | IMP-071 guards-disabled adversarial mode absent | live-framework |
| F-205-016 | P3 | IMP-074 hierarchical scoring rubric absent from framework-auditor | live-framework |
| F-205-017 | P3 | IMP-079 hollow-prompt subagent dispatch check absent | live-framework |

**Coverage map:** all 12 axes investigated; HIGH confidence on most.
**Contradictions within spec:** none new.

AUDIT_COMPLETE: R205 | findings=17 | P0=2 P1=4 P2=7 P3=4
