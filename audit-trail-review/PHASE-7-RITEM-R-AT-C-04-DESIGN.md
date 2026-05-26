# R-AT-C-04 — Design (G1) · axis-13.e runtime-invocation-contract probe

**Closes:** AC-6b (NC count in [10, 35] — pristine framework currently returns 0).
**Spec anchor:** `apex-spec.md` §"Defense-in-Depth Security Layer" + IMP-002/005/008/013/014/015/016/017/018 (each names guards by filename that the framework-auditor MUST probe). The probe's empirical evidence: `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md` F-001 P0.
**R-item source:** `PHASE-7-MASTER-PLAN.md` §3 + §5 R-AT-C-04 (option b — methodology extension based on Wave 0 N=11 outcome).
**Date:** 2026-05-26.

---

## §1. Root cause (G0 evidence — confirmed empirically)

Per `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md` methodology lesson #1:

> "I crafted `echo '{"tool_input":...}' | bash <hook>.sh` to match the actual `settings.json` invocation, every guard fell over. The `framework-auditor.md` Axis 13 protocol explicitly demands this kind of behavioural probe; prior rounds appear to have skipped it. A shallow audit that read the hook source and trusted the test suite would have ratified the bypass as 'documented and tested.'"

Empirical: 11 findings surfaced (1 P0, 4 P1, 4 P2, 2 P3) where prior auditors returned 0. The P0 alone (F-001) shows 8 spec-named guards silently bypass under the actual Claude Code stdin-envelope contract — they parse only `${1:-}` from positional argv, but `settings.json` invokes them with no positional arguments (Claude Code pipes `tool_input` JSON on stdin).

The pre-existing axis-13.a "Guard-bypass sub-pass" mentions "crafted payload" but does NOT mandate probing BOTH invocation contracts (argv vs stdin-envelope). Auditors who probed via argv only saw the contract-compliant behavior; the runtime bypass was invisible.

Per master plan §3 N≥1 routing: apply the probe's methodology to framework-auditor.md as a new sub-axis. Re-run T7 NC to verify the upgraded auditor surfaces ≥10 findings (or accept N=11 from the Wave 0 probe as the empirical AC-6b PASS — see §8 for staging).

## §2. Design (4 changes)

### Change A — `framework/agents/specialist/framework-auditor.md` new axis-13.e

**Location:** AFTER axis-13.b ("Silent-failure sub-pass — Fail-loud falsification"), ADD axis-13.e (the letter sequence under axis-13 currently has 13.a and 13.b; 13.c is reserved for Wave-2 R-DH-P7-01 source-literal carve-out; 13.d is the mutation-class probe under axis-10; 13.e is this R-item).

New sub-pass text (~50 lines):

```markdown
**13.e · Runtime-invocation-contract probe.** [Phase-7 R-AT-C-04
— closes AC-6b methodology gap empirically demonstrated by
`audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md` F-001 P0.]

Every spec-named guard hook in the extracted_set (axis-1) MUST
be probed via TWO invocation contracts and the exit codes
compared:

1. **Legacy positional-argv contract** — the test suite's form:
   `bash framework/hooks/<guard>.sh "<payload>" ; echo $?`
2. **Claude Code stdin-envelope contract** — the actual
   runtime form per `framework/settings.json` PreToolUse and
   PostToolUse matchers (`bash ~/.claude/hooks/<guard>.sh`
   with no positional args; `tool_input` JSON piped on stdin):
   `echo '{"tool_input":{"command":"<payload>"}}' | bash framework/hooks/<guard>.sh ; echo $?`
   (For PostToolUse Write|Edit hooks, use `{"tool_input":{"file_path":"..."}}`
   shape; for Bash matcher hooks, use `{"tool_input":{"command":"..."}}`.)

**Discrepancy contract:** if the two invocations yield DIFFERENT
exit codes, this is a guard-contract-drift finding regardless of
which form returns the contract-required exit code. The auditor
MUST emit P0 with:

- **Title:** `<guard>.sh contract drifts between argv and stdin-envelope invocations`
- **Cite:** the spec IMP anchor that names the guard + the
  `framework/settings.json` line that wires it
- **Evidence:** the two captured exit codes verbatim + the
  payload used
- **Defect class:** the guard parses only argv (e.g., `COMMAND="${1:-}"`)
  but its production wiring passes nothing positionally; the
  bypass class is "runtime contract mismatch — guard inactive
  on actual installation path"

**Recording shape:** the captured `(guard, payload, argv_exit,
stdin_exit, tool_call_event_ts)` tuple goes into
`coverage_map.axis_13.runtime_contract_probes[]`. Round-checker
TP-2 §6.b (per R-AT-C-04) iterates this array.

**Minimum probe set:** every guard in axis-1 extracted_set that
is wired in `settings.json` PreToolUse|PostToolUse with no
positional args. The auditor identifies the minimum set by
parsing settings.json matchers and cross-referencing against
extracted_set. A coverage_map row with `axis_13_runtime_probes_count
< 1` for the extracted_set's settings-wired subset is an
incomplete audit (BLIND SPOT at most; not "clean").

**Construction protocol for prompt-guard probes:** prompt-guard.sh
and apex-prompt-guard.cjs cannot be probed with literal
injection-shaped payloads via the Write tool (the prompt-guard
itself blocks the write). The auditor constructs probe payloads
in-memory under the `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>`
marker carve-out (see axis-10.c) and pipes them via Bash
heredoc, never via a literal write to disk.

**Cross-reference to axis-10.d (R-AT-C-02):** axis-10.d catches
mutation-class weakening (regex word-boundary, case-folding,
silent-failure, counter-swallow); axis-13.e catches
invocation-contract drift (argv vs stdin-envelope). The two
probe families are complementary and BOTH must be present in a
PASS-eligible round (per round-checker TP-2 §6.b).
```

### Change B — `framework/agents/specialist/round-checker.md` TP-2 §6.b extension

ADD a new bullet AFTER the R-AT-C-02 mutation-class clauses (i)-(vi):

```markdown
- **Runtime-invocation-contract probe minimum (R-AT-C-04 / AC-6b).**

  **(vii) Per-guard runtime-contract probe count.** For each
  guard in axis-1 extracted_set that is wired in
  `framework/settings.json` PreToolUse|PostToolUse with no
  positional argv, the auditor's
  `axis_13.runtime_contract_probes[]` MUST contain >= 1 entry
  for that guard. Missing entry → emit P1
  `axis_13_runtime_contract_blind_spot` citing the guard +
  posture `clean-pending-spot-check` + Status `CONTINUE TO
  R<N+1>`.

  **(viii) Discrepancy-classification gate.** For each entry
  in `axis_13.runtime_contract_probes[]` where `argv_exit !=
  stdin_exit`, the auditor MUST have emitted at least one
  finding (any severity) whose `cite[]` includes the guard
  filename. Missing finding for a discrepant probe → emit P0
  `axis_13_runtime_contract_drift_unreported` citing the
  guard + the captured exit codes + Status `CONTINUE TO
  R<N+1>`. (Discrepancies are objective; the auditor cannot
  silently observe and not emit.)

  These gates close the AC-6b methodology floor: a trial that
  did not probe runtime-invocation contracts at all (axis-13.e
  empty) is structurally incomplete; a trial that probed and
  observed discrepancies but didn't emit is dishonest.
```

### Change C — Layer tests `framework/tests/test-audit-trail-layer.sh` H-E1..H-E4

Add 4 new layer-test rows + 4 fixture transcripts:

| H-ID | Synthetic transcript shape | Expected verdict |
|------|---------------------------|-----------------|
| H-E1 | axis_13.runtime_contract_probes[] empty for a settings-wired guard | P1 `axis_13_runtime_contract_blind_spot` |
| H-E2 | axis_13.runtime_contract_probes[] has entry with `argv_exit != stdin_exit` AND no finding cites the guard | P0 `axis_13_runtime_contract_drift_unreported` |
| H-E3 | axis_13.runtime_contract_probes[] has entry with `argv_exit == stdin_exit` (no discrepancy) AND no finding for that guard | PASS (clauses vii + viii satisfied) |
| H-E4 | axis_13.runtime_contract_probes[] has discrepancy + finding present citing the guard | PASS (discrepancy reported per (viii)) |

Each row consumes `framework/test-fixtures/round-checker-h-e-{1..4}.jsonl` (new fixture set).

Extend the simulator `round_checker_sim()` in test-audit-trail-layer.sh to evaluate clauses (vii) + (viii).

### Change D — `framework/docs/AUDIT-TRAIL-STANDARD.md` AC-6b line

Replace the existing AC-6b status line (just modified for R-AT-C-02 closure) with the R-AT-C-04 closure note:

```
old: AC-6b NC count: pristine genuinely clean — R-AT-C-04 (§14 amendment or probe-set extension).
new: AC-6b NC count: closed via R-AT-C-04 — axis-13.e runtime-invocation-contract probe; Wave-0 independent probe empirically surfaced 11 findings (1 P0, 4 P1, 4 P2, 2 P3) against the same pristine framework; methodology absorbed into framework-auditor.md axis-13.e + round-checker.md TP-2 §6.b clauses (vii)-(viii).
```

## §3. Blast radius

| File | Touched? | Lines | Consumers |
|------|---------:|------:|-----------|
| `framework/agents/specialist/framework-auditor.md` axis-13.e (NEW) | MODIFIED (insert) | +~55 lines after axis-13.b | All future auditors; round-checker enforcement |
| `framework/agents/specialist/round-checker.md` TP-2 §6.b clauses (vii)-(viii) | MODIFIED (insert) | +~25 lines after R-AT-C-02 block | Future round-checker invocations |
| `framework/tests/test-audit-trail-layer.sh` H-E1..H-E4 + simulator extension | MODIFIED | +~60 lines (4 H-E rows + ~30 simulator lines for clauses vii+viii) | CI test suite |
| `framework/test-fixtures/round-checker-h-e-{1..4}.jsonl` | NEW (×4) | ~80 lines total | H-E test consumption |
| `framework/docs/AUDIT-TRAIL-STANDARD.md` AC-6b line | MODIFIED | 1-line replace | Documentary readers |
| `audit-trail-review/FINAL-CERTIFICATION-C.md` §3 L-AT-C-04 | MODIFIED | +closure note | Phase-7 closure tracking |
| `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-AT-C-04 | MODIFIED | +closure note | Phase-7 closure tracking |

**Per-consumer assessment:**

1. **Auditors in active Phase-7 trials** — strengthened axis-13 with 13.e mandates runtime-envelope probes. Existing 13.a (canonical bypass) + 13.b (silent-failure) preserved unchanged.
2. **Round-checker callers** — new clauses (vii)+(viii) only fire when `axis_13.runtime_contract_probes[]` is queryable from coverage_map. Existing clauses (i)-(vi) unaffected.
3. **CI test suite** — additive; existing 48/48 baseline preserved (40 baseline + 8 R-AT-C-02 H-D + 4 new R-AT-C-04 H-E = 52/52 target).
4. **AC-6b PASS path** — once landed, future auditors running NC trials will probe runtime envelopes and surface the methodology floor. T7 NC re-run (Wave 4) should return >=10 findings, closing AC-6b empirically. The Wave 0 probe already provided 11 findings — that count CAN ALSO be cited as the empirical AC-6b PASS evidence (see §8 staging).

## §4. Validation strategy (G4)

Layer-test pass criteria:

```bash
bash framework/tests/test-audit-trail-layer.sh
# Expected: passed: 52, failed: 0
```

4 new H-E tests must pass; baseline 48 (40 + 8 R-AT-C-02 H-D) must remain green.

**Live evidence:** Wave-0 probe is the live evidence — 11 findings ≥ 10 floor.

## §5. G5 PASS criteria

Critic R2 PASS requires:
1. ✅ All 4 new layer tests pass (48 → 52).
2. ✅ framework-auditor.md axis-13.e block present, anchored to AC-6B-INDEPENDENT-PROBE-FINDINGS.md F-001 P0 reproduction line.
3. ✅ round-checker.md TP-2 §6.b clauses (vii)+(viii) present with documented verdict shapes.
4. ✅ AUDIT-TRAIL-STANDARD.md AC-6b line updated.
5. ✅ FINAL-CERTIFICATION-C.md + PHASE-7-MASTER-PLAN.md closure notes landed.
6. ✅ No regression in baseline 48/48.
7. ✅ Spec anchor cited verbatim.

## §6. Implementation plan (G3 — 5 commits)

1. `framework/agents/specialist/framework-auditor.md` axis-13.e INSERT
2. `framework/agents/specialist/round-checker.md` TP-2 §6.b clauses (vii)+(viii) INSERT
3. `framework/test-fixtures/round-checker-h-e-{1..4}.jsonl` (NEW ×4)
4. `framework/tests/test-audit-trail-layer.sh` simulator extension + H-E1..H-E4 ADD
5. `framework/docs/AUDIT-TRAIL-STANDARD.md` AC-6b line + `FINAL-CERTIFICATION-C.md` + `PHASE-7-MASTER-PLAN.md` closure notes

After each commit: sync to `~/.claude/`.

## §7. Out-of-scope

- §14 amendment to AC-6b lower bound — superseded by methodology upgrade.
- Fixing the 8-guard stdin-envelope bypass in source — that's a SEPARATE owner-triage track item (the F-001 P0 defect itself remains in the framework; R-AT-C-04 closes the AC-6b METHODOLOGY gap, not the P0 it found). The Phase-7 master plan §6 acknowledges this scope boundary.
- T7 NC re-run — Wave 4 collective gate.

## §8. AC-6b empirical closure staging

**Question:** is AC-6b PASS gated on the Wave-4 T7 re-run, or on the Wave-0 probe's 11-finding count?

**Answer:** the methodology upgrade is the binding contract. The Wave-0 probe was a manually-run instance that DID NOT use the upgraded auditor.md prose (the probe was a fresh-context agent given the verbatim probe prompt — not a framework-auditor following the new axis-13.e). The Wave-4 T7 NC re-run will use the upgraded auditor.md and should empirically surface >= 10 findings on its own.

Pragmatic staging:
- **G5 PASS (R-AT-C-04 closure):** methodology landed + layer tests pass.
- **AC-6b empirical PASS (separate gate):** Wave-4 T7 NC trial returns >=10 findings AND in_band[10,35].
- **§14 amendment fallback:** if Wave-4 T7 still returns <10 (e.g., the framework's 8-guard P0 + other items get FIXED before T7 runs and the count drops), the owner can authorize a §14 amendment OR Phase-7 documents the gap explicitly.

The Wave-0 probe stands as evidence the METHODOLOGY works. The Wave-4 T7 re-run will confirm or contradict.

## §9. Decision summary

**Strategy:** add axis-13.e (runtime-invocation-contract probe) to framework-auditor.md; extend round-checker TP-2 §6.b with clauses (vii)+(viii); add 4 H-E layer tests; update AUDIT-TRAIL-STANDARD.md + Phase-7 docs.

**Blast radius:** 8 files (5 modified + 4 new fixtures). Additive — no renames, no shape changes to existing arrays.

**Next gate:** G2 critic R1.
