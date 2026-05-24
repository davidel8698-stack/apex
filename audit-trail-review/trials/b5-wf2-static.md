# Trial B5-T11 — W-F2 static probe (CR-05 orchestrator-glob closure)

## Probe definition

Per `audit-trail-review/EXPERIMENT-PROTOCOL.md` §10.1 / §11 (W-F2 class):
verify the self-heal orchestrator glob includes **both** the per-wave
`NEW-FINDINGS-R<N>-W<X>.md` pattern **and** the
`NEW-FINDINGS-ORCHESTRATOR-R<N>.md` pattern, so cross-wave findings emitted
by the orchestrator (not the wave-executors) are NOT silently dropped.

## Execution

Command:
```bash
grep -nE 'NEW-FINDINGS-R<N>-W<X>\.md|NEW-FINDINGS-ORCHESTRATOR' \
  framework/commands/apex/self-heal.md
```

Output:
```
313:  `$REPO_ROOT/NEW-FINDINGS-R<N>-W<X>.md` where they exist, **and**
314:  `$REPO_ROOT/NEW-FINDINGS-ORCHESTRATOR-R<N>.md` if it exists
329:    new_findings: [list of NEW-FINDINGS-R<N>-W<X>.md paths
330:                   plus NEW-FINDINGS-ORCHESTRATOR-R<N>.md if it exists],
```

## Verdict

**PASS.** Both required patterns are present in the orchestrator glob
at lines 313–314 (prose) and 329–330 (structured field). CR-05 is closed
in this orchestrator copy. The wave-executor's NEW-FINDINGS files AND the
orchestrator's own NEW-FINDINGS-ORCHESTRATOR file are both consumed by
the round-end aggregation step.

## Coverage map

```json
{
  "trial": "B5-T11",
  "class": "W-F2 (static)",
  "lab": "framework/commands/apex/self-heal.md (no per-trial lab; tests the source orchestrator)",
  "axes_covered": ["axis_2 (Orchestration)", "axis_7 (Finding-aggregation)"],
  "findings_count": 0,
  "fabricated": 0,
  "expected": "patterns present",
  "actual": "patterns present at L313–L314 and L329–L330"
}
```

audit_trail_v=1; subagent_transcript_ok=n/a; gap1_closed=n/a; sgc=0
