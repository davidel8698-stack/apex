# R-AT-C-04 — Design R2 · NIT-1..NIT-5 absorption pass

**Supersedes:** `PHASE-7-RITEM-R-AT-C-04-DESIGN.md` (R1).
**Critic R1 verdict:** `PHASE-7-RITEM-R-AT-C-04-CRITIC-R1.md` — PASS-WITH-CHANGES (0 BFs, 7 NITs).
**Date:** 2026-05-26.

R1 content carries forward unchanged unless noted. R2 absorbs NIT-1..NIT-5 (critic-required) and defers NIT-6/NIT-7 (strategic recommendations — see §10).

---

## §0. Critic R1 NIT closure summary

| NIT | R1 issue | R2 resolution |
|-----|----------|---------------|
| **NIT-1** | Letter-sequence justification for "13.e" was misleading ("13.d is the mutation-class probe under axis-10" — axis-10.d is NOT axis-13.d) | §2 Change A justification rewritten with honest reconciliation history per critic option (A) |
| **NIT-2** | "Construction protocol for prompt-guard probes" inherited over-cautious marker carve-out language; Bash quote-stripping neutralizes literal payloads on echo-pipe-to-Bash contract | §2 Change A prompt-guard paragraph tightened: marker required ONLY for Write tool materialization, NOT for echo-pipe-to-Bash probes |
| **NIT-3** | H-E fixtures must include minimally-compliant axis_10 block to avoid simulator short-circuit on (i)-(vi) before reaching (vii)+(viii) | §2 Change C explicit fixture constraint added |
| **NIT-4** | §1 line 20 invited a "accept N=11 from Wave-0 probe" fallback that §8 disqualifies | §1 prose rewritten — drops the misleading parenthetical |
| **NIT-5** | NIT-5 = rolled-up finding shape ambiguity from criterion 8 — addressed by clause (viii) wording allowing "≥1 finding cites the guard" rather than requiring per-guard finding | §2 Change B clause (viii) wording explicitly accepts rolled-up findings if the cite[] is dense enough |

**NIT-6 (Wave-4 margin) + NIT-7 (8-guard P0 owner-triage reminder)** — strategic recommendations, deferred per §10.

---

## §1. Root cause (REVISED per NIT-4 — drop misleading fallback parenthetical)

Per `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md` methodology lesson #1: the existing axis-13.a "Guard-bypass sub-pass" mentions "crafted payload" but does NOT mandate probing BOTH invocation contracts (argv vs stdin-envelope). Auditors probing via argv only saw contract-compliant behavior; the runtime bypass under the real Claude Code settings.json wiring was invisible.

The Wave-0 probe's 11 findings (1 P0, 4 P1, 4 P2, 2 P3) are empirical evidence that the methodology gap exists. Per master plan §3 N≥1 routing: apply the probe's methodology to framework-auditor.md as a new sub-axis. The Wave-4 T7 NC re-run will verify the upgraded auditor surfaces the methodology floor empirically; the binding G5 PASS criterion for R-AT-C-04 itself is "methodology landed + layer tests pass" (per §8).

## §2. Design (REVISED — 4 changes)

### Change A (REVISED per NIT-1 + NIT-2) — axis-13.e

**Letter-sequence justification (REWORDED per NIT-1):**

> Axis-13 currently has sub-passes 13.a (Guard-bypass, line ~397) and 13.b (Silent-failure, line ~412). Sub-letter 13.c is reserved for Wave-2 R-DH-P7-01 source-literal carve-out (master plan §5 line 139). Sub-letter 13.d is intentionally skipped to preserve the historical master-plan-vs-implementation reconciliation made by R-AT-C-02 — the master plan referred to mutation-class probes as "axis-13.d" but R-AT-C-02 R2 §2.B reconciled this to axis-10.d (where the existing axis-10 procedural block already lives); skipping the letter "d" under axis-13 prevents future re-collision. This R-item therefore lands as axis-13.e.

**Sub-pass body (text otherwise per R1, with the prompt-guard paragraph REWORDED per NIT-2):**

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
TP-2 §6.b clauses (vii)+(viii) (per R-AT-C-04) iterate this array.

**Minimum probe set:** every guard in axis-1 extracted_set that
is wired in `settings.json` PreToolUse|PostToolUse with no
positional args. The auditor identifies the minimum set by
parsing settings.json matchers and cross-referencing against
extracted_set. A coverage_map row with `axis_13_runtime_probes_count
< 1` for the extracted_set's settings-wired subset is an
incomplete audit (BLIND SPOT at most; not "clean").

**Construction protocol for prompt-guard probes (REVISED per NIT-2):**
the echo-pipe-to-Bash invocation pattern is the primary probe
contract — Bash's quote-stripping on the host destructive-guard
read-only-commands branch (apex-prompt-guard.cjs only fires on
Write|Edit|Agent matchers) neutralizes the inner literal payload
on the auditor's own Bash tool_call. The `__APEX_AUDIT_PROBE__:`
marker carve-out (axis-10.c three-factor protocol) is REQUIRED
ONLY if the auditor uses the Write tool to materialize a
multi-line payload to disk first. For the standard axis-13.e
echo-pipe probe, the marker is unnecessary.

**Cross-reference to axis-10.d (R-AT-C-02):** axis-10.d catches
mutation-class weakening (regex word-boundary, case-folding,
silent-failure, counter-swallow); axis-13.e catches
invocation-contract drift (argv vs stdin-envelope). The two
probe families are complementary and BOTH must be present in a
PASS-eligible round (per round-checker TP-2 §6.b).
```

### Change B (REVISED per NIT-5) — Round-checker TP-2 §6.b clauses (vii)+(viii)

Insert location unchanged (line 220-222 of round-checker.md, between (vi) and clause 6.c).

**(vii) Per-guard runtime-contract probe count.** For each guard in axis-1 extracted_set that is wired in `framework/settings.json` PreToolUse|PostToolUse with no positional argv, the auditor's `axis_13.runtime_contract_probes[]` MUST contain >= 1 entry for that guard. Missing entry → emit P1 `axis_13_runtime_contract_blind_spot` citing the guard + posture `clean-pending-spot-check` + Status `CONTINUE TO R<N+1>`.

**(viii) Discrepancy-classification gate (REVISED per NIT-5).** For each entry in `axis_13.runtime_contract_probes[]` where `argv_exit != stdin_exit`, the auditor MUST have emitted at LEAST ONE finding (any severity) whose `cite[]` includes the guard filename. A SINGLE rolled-up P0 finding whose `cite[]` includes multiple discrepant guards satisfies this clause for every guard cited. Missing finding for ANY discrepant guard → emit P0 `axis_13_runtime_contract_drift_unreported` citing the missing guard + the captured exit codes + Status `CONTINUE TO R<N+1>`. (Discrepancies are objective; the auditor cannot silently observe and not emit.)

These gates close the AC-6b methodology floor: a trial that did not probe runtime-invocation contracts at all (axis-13.e empty) is structurally incomplete; a trial that probed and observed discrepancies but didn't emit is dishonest. Rolled-up findings are explicitly accepted (matches the F-001 P0 shape from the Wave-0 probe).

### Change C (REVISED per NIT-3) — Layer tests + fixture constraint

H-E1..H-E4 layer tests + 4 fixture transcripts at `framework/test-fixtures/round-checker-h-e-{1..4}.jsonl`.

**Explicit fixture constraint (NIT-3 closure):** every H-E-N fixture's `axis_10.concrete_bypass_attempts[]` array MUST be minimally compliant with round-checker clauses (i)-(vi) (i.e., shaped like H-D2's PASS-case structure: all 4 mutation-class guards present with their required probes). This ensures the simulator does not short-circuit on H-D-shaped failures before reaching the new clauses (vii)+(viii). Each fixture has axis_10 = H-D2-shaped PASS baseline + axis_13.runtime_contract_probes[] variant per test scenario.

**Simulator extension (jq queries explicitly defined for G3):**

```
runtime_count=$(jq_clean -r '.axis_13.runtime_contract_probes | length // 0' "$transcript")
# Clause (vii):
for g in [settings-wired guards]; do
  count=$(jq_clean -r --arg g "$g" '.axis_13.runtime_contract_probes[] | select(.guard==$g) | "ok"' "$transcript" | head -1)
  if [ "$count" != "ok" ]; then echo "axis_13_runtime_contract_blind_spot"; return; fi
done
# Clause (viii):
for entry in [.axis_13.runtime_contract_probes[] where argv_exit != stdin_exit]; do
  cited=$(jq_clean -r --arg g "$entry.guard" '.findings[].cite[] | select(. == $g) | "ok"' "$transcript" | head -1)
  if [ "$cited" != "ok" ]; then echo "axis_13_runtime_contract_drift_unreported"; return; fi
done
```

For H-E fixtures, the `findings[]` array is part of the transcript shape and tested for cite[] presence.

### Change D (unchanged) — `framework/docs/AUDIT-TRAIL-STANDARD.md` AC-6b line

Same as R1.

---

## §5. G5 PASS criteria (REVISED per NIT-5)

Critic R2 PASS requires:
1. ✅ All 4 new layer tests pass (48 → 52).
2. ✅ framework-auditor.md axis-13.e block present with letter-sequence justification per NIT-1 (the rewritten paragraph).
3. ✅ round-checker.md TP-2 §6.b clauses (vii)+(viii) present; clause (viii) text accepts rolled-up findings per NIT-5.
4. ✅ AUDIT-TRAIL-STANDARD.md AC-6b line updated.
5. ✅ FINAL-CERTIFICATION-C.md + PHASE-7-MASTER-PLAN.md closure notes landed.
6. ✅ No regression in baseline 48 (40 + 8 R-AT-C-02 H-D = 48; new total = 52).
7. ✅ Spec anchor cited verbatim.
8. ✅ H-E fixture axis_10 blocks are H-D2-PASS-shaped (NIT-3 closure).
9. ✅ Prompt-guard probe paragraph clarifies marker is needed ONLY for Write-tool materialization (NIT-2).

---

## §6, §7, §8 unchanged from R1

§6 implementation plan (5 commits) — same as R1.
§7 out-of-scope — same.
§8 AC-6b empirical closure staging — same (G5 = methodology landed, Wave-4 T7 separate gate).

---

## §10. Deferred recommendations (NIT-6 + NIT-7)

**NIT-6 — Wave-4 margin defensive expansion.** Critic suggested absorbing F-001's methodology lessons #2 (schema-vs-impl jq diff) + #3 (run-all.sh test-suite OBSERVED). Scope question: do those become axis-13.f / 13.g or fold into axis-13.e?

**Decision:** defer to a follow-up R-item (R-AT-P7-07 reserved if Wave-4 T7 returns < 10). The current axis-13.e expansion (runtime-invocation-contract) is empirically justified by the Wave-0 probe's F-001 P0 alone (8 guards → 8 discrepancies on a non-rollup auditor). Wave-4 T7 will reveal whether the margin is sufficient; if not, we open R-AT-P7-07 to absorb #2+#3. This staged approach preserves R-AT-C-04's tight scope.

**NIT-7 — 8-guard P0 owner-triage reminder.** Critic noted that the F-001 P0 itself (the 8-guard runtime bypass) remains UNFIXED in the framework. R-AT-C-04 closes the methodology gap; the framework defect F-001 represents stays in the owner-triage track (detector-review FINAL-CERTIFICATION §4 family) for a future repair R-item.

**Decision:** document this scope boundary in the commit messages and the PHASE-7-MASTER-PLAN.md closure note. The Wave-0 probe's 11 findings are surfaced for owner triage; R-AT-C-04 ensures the methodology to surface them is now contractually required for future auditors.

---

## §11. Decision summary (R2)

**Critic R1:** PASS-WITH-CHANGES (0 BFs, 7 NITs).
**R2:** absorbs NIT-1..NIT-5 (critic-required); defers NIT-6/NIT-7 with documented rationale.

**Strategy unchanged:** add axis-13.e (runtime-invocation-contract probe) + round-checker clauses (vii)+(viii) + 4 H-E layer tests + AC-6b status line update + Phase-7 closure notes.

**Blast radius:** unchanged from R1 (8 files).

**Next gate:** G2 critic R2 verification of R2.
