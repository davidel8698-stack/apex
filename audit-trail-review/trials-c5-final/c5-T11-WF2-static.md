# Trial C5-T11 — W-F2 static probe (CR-05 orchestrator-glob closure)

## Probe definition

Per `audit-trail-review/EXPERIMENT-PROTOCOL.md` §10.1 / §11 (W-F2 class):
verify the self-heal orchestrator glob includes **both** the per-wave
`NEW-FINDINGS-R<N>-W<X>.md` pattern **and** the
`NEW-FINDINGS-ORCHESTRATOR-R<N>.md` pattern, so cross-wave findings emitted
by the orchestrator (not the wave-executors) are NOT silently dropped.

Source orchestrator: `framework/commands/apex/self-heal.md` (live, current
HEAD post Phase-7 closure including R-DH-P7-02 budget-bump and all
R-AT-C-NN closures).

## Execution

Command:
```bash
grep -nE 'NEW-FINDINGS-R<N>-W<X>\.md|NEW-FINDINGS-ORCHESTRATOR' \
  framework/commands/apex/self-heal.md
```

Output:
```
354:  `$REPO_ROOT/NEW-FINDINGS-R<N>-W<X>.md` where they exist, **and**
355:  `$REPO_ROOT/NEW-FINDINGS-ORCHESTRATOR-R<N>.md` if it exists
370:    new_findings: [list of NEW-FINDINGS-R<N>-W<X>.md paths
371:                   plus NEW-FINDINGS-ORCHESTRATOR-R<N>.md if it exists],
```

Per-pattern counts:
- `NEW-FINDINGS-R<N>-W<X>.md`: 2 occurrences (prose + structured field)
- `NEW-FINDINGS-ORCHESTRATOR`: 2 occurrences (prose + structured field)

## Verdict

**PASS.** Both required patterns are present in the orchestrator glob
at lines 354–355 (prose) and 370–371 (structured field). CR-05 is closed
in this orchestrator copy. The wave-executor's NEW-FINDINGS files AND the
orchestrator's own NEW-FINDINGS-ORCHESTRATOR file are both consumed by
the round-end aggregation step.

Wave-4 result identical to Wave-1 (B5-T11): PASS. Line numbers shifted
from B5's 313–314/329–330 to C5's 354–355/370–371 due to spec growth
through Phase-7 additions (R-DH-P7-02 budget-bump prose, R-AT-C-04
clauses) — pattern integrity preserved across additions.

## Coverage map

```json
{
  "trial": "C5-T11",
  "class": "W-F2 (static)",
  "lab": "framework/commands/apex/self-heal.md (no per-trial lab; tests the source orchestrator)",
  "axes_covered": ["axis_2 (Orchestration)", "axis_7 (Finding-aggregation)"],
  "findings_count": 0,
  "fabricated": 0,
  "expected": "patterns present",
  "actual": "patterns present at L354–L355 and L370–L371"
}
```

audit_trail_v=2; subagent_transcript_ok=n/a; gap1_closed=n/a; sgc=0
