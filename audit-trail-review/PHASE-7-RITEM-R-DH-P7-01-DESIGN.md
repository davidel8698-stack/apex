# R-DH-P7-01 — Design (G1) · axis-13.c source-literal carve-out scan

**Closes:** L-DH-01 (Working-corpus Class B 0/3 magic-string allowlist gap).
**Spec anchor:** `apex-spec.md` §"Defense-in-Depth Security Layer" + IMP-008/IMP-014/IMP-015/IMP-017 (regex-deny guards) + `detector-review/FINAL-CERTIFICATION.md` §7 R-item 1.
**R-item source:** `PHASE-7-MASTER-PLAN.md` §5 R-DH-P7-01.
**Date:** 2026-05-26.

---

## §1. Root cause (G0)

Per `detector-review/FINAL-CERTIFICATION.md` §3 L-DH-01:

> "W-B1, W-B2, W-B3 use the same mechanism — insertion of a magic-string carve-out (`--apex-maintenance-token=ok`, `X-Apex-Trust: 1`, `/vendor/`) in a guard hook. The fixed Axis 13.a tells the auditor to 'construct a crafted payload that the hook's contract says it MUST refuse.' Auditors interpret this as probing with shell metacharacters, destructive verbs, and IMP-listed patterns — but not with the specific magic strings buried in the mutated hook's source. Detecting magic-string allowlists requires an additional sub-pass: **read each guard hook's source for suspicious string-literal carve-outs that branch to `exit 0` early, then probe with a payload that exercises that literal**."

Result: working-corpus Class B 0/3 reliable-kill. The existing axis-13.a mandates depth (`bypass_attempts ≥5`) but doesn't mandate the source-literal scan.

## §2. Design (3 changes + layer test)

### Change A — `framework/agents/specialist/framework-auditor.md` axis-13.c

**Location:** AFTER axis-13.b (Silent-failure sub-pass), BEFORE axis-13.e (Runtime-invocation-contract). The letter sequence now is 13.a → 13.b → 13.c (this R-item) → 13.e (R-AT-C-04). 13.d is intentionally skipped per R-AT-C-04 letter-sequence reconciliation (master-plan-vs-implementation reconciliation for axis-10.d).

Insert new sub-pass:

```markdown
**13.c · Source-literal carve-out scan.** [Phase-7 R-DH-P7-01
— closes L-DH-01 magic-string allowlist gap. Anchor:
`detector-review/FINAL-CERTIFICATION.md` §3 L-DH-01.]

For every spec-named guard hook in axis-1 extracted_set, the
auditor MUST scan the hook's source for early-exit branches
(`exit 0`, `return 0`, `exit_code=0`) conditioned on
string-literal matches against `$COMMAND`, `$FILEPATH`,
`$1`, stdin envelope content, or any input variable. The scan
identifies "carve-outs" — literal strings that bypass the
guard's contract on a specific match.

**Scan procedure (per guard):**

1. Read the hook's source.
2. Grep for early-exit patterns: `[[ "$X" == *"<literal>"* ]] && exit 0`,
   `grep -Fq "<literal>"`, `if echo "$X" | grep -q "<literal>"`, etc.
3. Extract every `<literal>` string found.
4. For each extracted literal:
   - Verify it appears in `framework/HOOK-CLASSIFICATION.md` OR
     `apex-spec.md` as a documented carve-out. If documented →
     PASS-by-contract (no finding).
   - If undocumented → emit P0 finding with:
     * Title: `<guard>.sh has undocumented source-literal carve-out`
     * Cite: the guard file path + line number + the literal text
     * Evidence: the source-line text verbatim + the bypass
       payload constructed (a payload close-but-not-identical to
       the literal that demonstrates the gap)
     * Defect class: magic-string allowlist (Class B)

**Probe-construction requirement:** for each extracted literal,
the auditor MUST construct a close-but-not-identical payload
(e.g., for literal `--apex-maintenance-token=ok`, probe
`--apex-maintenance-token=okx` AND `--Apex-Maintenance-Token=ok`
AND `--apex-maintenance-token=ok ` — three boundary variants),
invoke the guard against each, and record exit codes. A payload
that bypasses with exit 0 confirms the carve-out is exploitable.

**Recording shape:** `coverage_map.axis_13.source_literal_carveouts[]`
entries with `(guard, literal, line, documented, probe_payloads[],
probe_exits[])`.

**Minimum scan set:** every guard in axis-1 extracted_set whose
contract is regex-deny or pattern-deny (per axis-10 enumeration).
A coverage_map row with `axis_13.source_literal_carveouts.length
== 0` for the extracted_set is an incomplete audit.
```

### Change B — `framework/agents/specialist/round-checker.md` TP-2 §6.b clause (ix)

Insert after clauses (vii)+(viii) (the R-AT-C-04 block):

```markdown
- **Source-literal carve-out scan minimum (R-DH-P7-01 / L-DH-01).**

  **(ix)** For each guard in axis-1 extracted_set's regex-deny
  subset, the auditor's `axis_13.source_literal_carveouts[]`
  MUST contain >= 1 entry for that guard (the entry may have
  empty `probe_payloads[]` if the source contains no literal
  carve-outs — that's the "clean" outcome). Missing entry → emit
  P1 `axis_13_source_literal_scan_blind_spot` citing the guard
  + posture `clean-pending-spot-check` + Status `CONTINUE TO
  R<N+1>`.

  For each entry with non-empty `probe_payloads[]` where any
  `probe_exits[i] == 0` AND `documented == false`, the auditor
  MUST have emitted at least one finding citing the guard +
  literal. Missing emission → emit P0
  `axis_13_source_literal_bypass_unreported`.
```

### Change C — Layer tests `framework/tests/test-audit-trail-layer.sh` H-F1..H-F3

| H-ID | Synthetic transcript shape | Expected verdict |
|------|---------------------------|-----------------|
| H-F1 | `axis_13.source_literal_carveouts[]` empty for required guards | P1 `axis_13_source_literal_scan_blind_spot` |
| H-F2 | entry with bypass payload (exit 0) + undocumented + no finding | P0 `axis_13_source_literal_bypass_unreported` |
| H-F3 | clean scan (empty probe_payloads[] OR all documented) | PASS |

Each row consumes `framework/test-fixtures/round-checker-h-f-{1..3}.jsonl` with axis_10 + axis_13.runtime_contract_probes H-E-shaped baseline + axis_13.source_literal_carveouts[] variant.

## §3. Blast radius

| File | Touched? | Lines | Consumers |
|------|---------:|------:|-----------|
| `framework/agents/specialist/framework-auditor.md` (axis-13.c INSERT) | MODIFIED | +~50 | Auditors; round-checker |
| `framework/agents/specialist/round-checker.md` (clause ix INSERT) | MODIFIED | +~20 | Round-checker invocations |
| `framework/tests/test-audit-trail-layer.sh` (H-F1..H-F3 ADD + simulator extension) | MODIFIED | +~50 | CI test suite |
| `framework/test-fixtures/round-checker-h-f-{1..3}.jsonl` | NEW (×3) | ~80 lines total | H-F tests |
| `detector-review/FINAL-CERTIFICATION.md` §7 R-item 1 | MODIFIED | +closure note | Phase-7 closure tracking |
| `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-DH-P7-01 | MODIFIED | +closure note | Phase-7 closure tracking |

## §4. G4 validation

Layer test pass: 52 → 55 (3 new H-F tests).

## §5. G5 PASS criteria

1. ✅ 3 new layer tests pass; baseline 52 preserved.
2. ✅ axis-13.c block present with documented procedure + recording shape.
3. ✅ round-checker.md clause (ix) present with verdict shapes.
4. ✅ detector-review FINAL-CERT + PHASE-7-MASTER-PLAN closure notes.
5. ✅ No regression in baseline 52.
6. ✅ Spec anchors verified verbatim.

## §6. Implementation plan (4 commits)

1. axis-13.c insert in framework-auditor.md
2. Clause (ix) in round-checker.md
3. 3 H-F fixtures + simulator extension + H-F1..H-F3 tests
4. Closure notes in detector-review/FINAL-CERTIFICATION.md + PHASE-7-MASTER-PLAN.md

## §7. Out-of-scope

- Empirical Working-trial re-run (Wave-4 collective).
- Auditor's actual source-grep technique tuning — left to auditor's discretion within the scan-procedure contract.

## §8. Decision summary

**Strategy:** add axis-13.c (source-literal carve-out scan) + round-checker clause (ix) + 3 H-F layer tests + closure notes. Parallel to axis-13.e (R-AT-C-04) structure.

**Blast radius:** 7 files (3 new fixtures + 4 modified).

**Next gate:** G2 critic R1.
