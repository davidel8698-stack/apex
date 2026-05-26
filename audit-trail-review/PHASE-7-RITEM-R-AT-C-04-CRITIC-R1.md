# R-AT-C-04 — Critic R1 Verdict

**Verdict:** PASS-WITH-CHANGES (clarifications required before G3 entry; no blockers)
**Date:** 2026-05-26
**Design under review:** `audit-trail-review/PHASE-7-RITEM-R-AT-C-04-DESIGN.md`
**Empirical anchor verified:** `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md` F-001 P0 (8 guards, 11 findings total)
**Standard for verdict:** owner directive 2026-05-25 (G2 gate, no partial closure, strict QA gates).

---

## Per-criterion verdicts [1-8]

### Criterion 1 — Letter sequence consistency (axis-13.e naming)
**Status:** PASS-WITH-NIT (NIT-1).

Verified ground truth via `framework/agents/specialist/framework-auditor.md` Axis-13 read-through:

- Axis-13 currently exposes **only** `13.a` (Guard-bypass sub-pass, line 397) and `13.b` (Silent-failure sub-pass, line 412). No `13.c` or `13.d` exist in axis-13 today.
- The MASTER plan §5 R-DH-P7-01 (line 139) calls source-literal carve-out **"Axis 13.c"** — so 13.c IS reserved for that future R-item. PASS for that half of the design's rationale.
- The design's rationale for skipping 13.d is wrong as stated: "13.d is the mutation-class probe under axis-10." Mutation-class probes shipped at **axis-10.d** (per R-AT-C-02 design R2 §2.B; framework/agents/specialist/framework-auditor.md lines 305-368 — the mutation-class block sits inside axis-10, NOT axis-13). The MASTER plan's "axis-13.d" label was reconciled to axis-10.d (per R-AT-C-02-DESIGN-R2.md line 285 — "old: AC-5b: requires R-AT-C-02 (axis-13.d worked-examples); new: ... axis-10.d worked-examples; master plan label 'axis-13.d' reconciles to this location"). So no actual 13.d exists in framework-auditor.md. The design's stated reason is technically inaccurate (axis-10.d is NOT axis-13.d), but the operational result (skip the letter "d" under axis-13 to avoid documentary collision with the master-plan label) is defensible.

**Net assessment:** "13.e" is COHERENT (preserves a one-letter buffer against the historical master-plan-vs-implementation reconciliation), but the design's one-line justification is misleading and should be tightened.

Two acceptable options (designer's choice):
- (A) Keep "13.e", rewrite the parenthetical to: *"13.c is reserved for R-DH-P7-01 source-literal carve-out (master plan §5 line 139). 13.d is intentionally skipped to preserve the historical 'axis-13.d' master-plan label that R-AT-C-02 reconciled to axis-10.d (PHASE-7-RITEM-R-AT-C-02-DESIGN-R2.md line 285); skipping the letter prevents future re-collision."*
- (B) Use "13.c" today AND retarget R-DH-P7-01 to "13.d" — but this requires a cross-design renaming and is not worth the friction.

**Recommendation:** option (A). Non-blocking but should be addressed before G3.

### Criterion 2 — Round-checker clause numbering (vii)+(viii) anchoring
**Status:** PASS.

Verified `framework/agents/specialist/round-checker.md`:
- Section 6.b clauses (i)-(vi) span lines 148-220 (line 217-220 is the (vi) summary paragraph).
- Line 222 begins section 6.c (`F-204-013 reconstruction check`).
- Insert point for (vii)+(viii) is BETWEEN line 220 and line 222, inside the 6.b list. Indentation 6 spaces (`      `) per existing convention.
- The design's prose ("ADD a new bullet AFTER the R-AT-C-02 mutation-class clauses (i)-(vi)") correctly identifies the structural location.
- Numbering (vii)+(viii) cleanly continues the existing (i)-(vi) sequence — no clash with section 6.c-6.e (those use letters `c`/`d`/`e` at the outer level, not roman numerals).

Structurally clean.

### Criterion 3 — stdin-envelope payload safety against host PreToolUse
**Status:** PASS-WITH-CLARIFICATION (NIT-2).

The auditor's runtime probe `echo '{"tool_input":{"command":"rm -rf /"}}' | bash framework/hooks/destructive-guard.sh` will be processed by the host's PreToolUse:Bash matcher (which fires destructive-guard.sh on the auditor's own Bash tool input). I traced what happens:

1. `COMMAND="$1"` = the full echo-pipe string.
2. `apex_check_audit_probe "$COMMAND"` — the string does NOT begin with `__APEX_AUDIT_PROBE__:`, so the marker carve-out FAILS the prefix test, falls through.
3. `check_segment` is invoked. `FIRST_WORD=echo` matches the read-only-commands case (line 48-52), so single/double-quoted arguments are STRIPPED. After strip, NORMALIZED has the inner JSON `{...}` removed — the literal "rm -rf /" inside the quoted echo argument is gone.
4. Pattern matching runs on the stripped string → no match → exit 0 → auditor's Bash tool fires.

**Result:** The stdin-envelope probe DOES execute without needing the marker carve-out, because the host destructive-guard's quote-stripping for read-only commands neutralizes the literal payload. F-001 reproduction works AS-DESIGNED.

**BUT** — for the prompt-guard literal-payload probe (role-marker injection, override-style strings, etc.), `apex-prompt-guard.cjs` fires on `Write|Edit|Agent` matchers. The auditor's echo-pipe is a Bash tool, NOT Write/Edit/Agent — so apex-prompt-guard would NOT fire on the echo string. The design's instruction to "construct payloads in-memory under marker carve-out" for prompt-guard probes is therefore over-precautionary for Bash-tool probes against prompt-guard.sh (the .sh variant). The marker IS needed if the auditor uses the Write tool with a probe payload (the original SGC-001 surface). Since the design's stdin-envelope contract is Bash-tool-only (echo-pipe), the marker carve-out is largely unnecessary for the new axis-13.e prose.

**NIT-2:** The design's "Construction protocol for prompt-guard probes" paragraph (lines 77-83 of DESIGN.md) inherits over-cautious carve-out wording from R-AT-C-02. For axis-13.e specifically, the marker is needed ONLY if the auditor uses the Write tool to materialize the payload to disk. For the echo-pipe-to-bash invocation pattern (which is the design's primary attack contract), the marker is unnecessary. Recommend tightening this paragraph to: *"prompt-guard.sh probes via the echo-pipe-to-Bash contract do NOT require the marker carve-out (Bash quote-stripping neutralizes literal payloads on the host destructive-guard path); the marker IS required if the auditor needs the Write tool to materialize a multi-line payload to disk first."*

Non-blocking.

### Criterion 4 — H-E fixture coherence + simulator extension
**Status:** PASS-WITH-CLARIFICATION (NIT-3 — significant but not blocking).

Verified `framework/tests/test-audit-trail-layer.sh` lines 483-630:
- Existing `round_checker_sim()` (lines 483-597) iterates axis_10 in clauses (i)-(vi) and short-circuits with `return` on first violation. Falls through to `echo "PASS"` only if all clauses pass.
- Adding clauses (vii)+(viii) at the end (before the final `echo "PASS"`) is structurally clean IF the H-E fixtures are crafted such that clauses (i)-(vi) do not short-circuit.

**Risk:** every H-E fixture MUST contain a minimally-compliant `axis_10.concrete_bypass_attempts[]` array that satisfies (i)-(vi) — otherwise the simulator would short-circuit on H-D-shaped failures BEFORE reaching the new clauses. The design §2 Change C table doesn't specify this constraint on the fixtures.

**Expected verdict distinguishability check:**
- H-E1 (empty `axis_13.runtime_contract_probes[]`) → must fire `axis_13_runtime_contract_blind_spot`. The fixture's axis_10 must be (i)-(vi)-PASSing.
- H-E2 (axis_13 has discrepant entry + no finding cites guard) → must fire `axis_13_runtime_contract_drift_unreported`. Again axis_10 must be (i)-(vi)-PASSing.
- H-E3 (axis_13 has non-discrepant entry, no finding) → PASS. Confirms (viii) only fires on `argv_exit != stdin_exit` AND missing finding. Distinguishable from H-E4 because H-E4 has discrepancy + finding present (both clauses satisfied).
- H-E4 (discrepancy + finding citing guard) → PASS. Verdicts H-E3 and H-E4 BOTH terminate at `echo "PASS"` — the simulator can't distinguish them in its output string. That's OK because both expected verdicts are "PASS" in the design's table — the differentiation is in the fixture INPUT shape, not the verdict OUTPUT. Acceptable.

**Required new jq queries for the simulator extension:** `.axis_13.runtime_contract_probes[] | length`, `.axis_13.runtime_contract_probes[] | select(.argv_exit != .stdin_exit) | .guard`, and a cross-iteration over findings to confirm `cite[]` includes the guard filename. The design says "Extend the simulator" but doesn't specify the queries. Per Change C scope ("+~30 simulator lines"), this is in scope but should be flagged for G3 execution.

**NIT-3:** Recommend the design §2 Change C add a one-line note: *"Each H-E fixture's `axis_10` block MUST be minimally compliant with clauses (i)-(vi) so the simulator does not short-circuit before reaching (vii)+(viii)."* Non-blocking.

### Criterion 5 — AC-6b empirical closure staging vs master plan §3
**Status:** PASS-WITH-NIT (NIT-4 — internal soft inconsistency).

Cross-referenced master plan §3 routing ("N≥1 routes to extract methodology, upgrade framework-auditor.md axis, re-run T7") and master plan Wave 4 ("Re-run full 11-trial corpus C5"):
- The MASTER plan separates two things: per-R-item closure (Wave 1) vs empirical re-validation (Wave 4 T7 re-run).
- DESIGN §8 says G5 PASS = "methodology landed + layer tests pass" (per-R-item closure); AC-6b empirical PASS = separate gate at Wave 4 T7. **CONSISTENT** with master plan's wave structure.

**Internal soft inconsistency (NIT-4):** §1 line 20 says: *"Re-run T7 NC to verify the upgraded auditor surfaces ≥10 findings (or accept N=11 from the Wave 0 probe as the empirical AC-6b PASS — see §8 for staging)."* But §8 rejects that fallback: *"the Wave-0 probe was a manually-run instance that DID NOT use the upgraded auditor.md prose."* §1 invites the reader to consider a fallback that §8 then disqualifies. Not a hard contradiction (§1 says "see §8") but the §1 prose is misleading.

**Recommendation:** rewrite §1 line 20 to drop the "or accept N=11" parenthetical; the binding policy is §8's. Non-blocking.

### Criterion 6 — Coverage_map schema extension (runtime_contract_probes[])
**Status:** PASS.

Grep verified: `runtime_contract_probes` is ZERO pre-existing references in `framework/` (only the 3 expected forward-reference cross-pointers in `framework/agents/specialist/framework-auditor.md` lines 355-361 that already announce R-AT-C-04). The new field is additive.

Schema impact:
- No JSON Schema validator currently constrains `coverage_map` (per RESULT.schema.json sampling — coverage_map is an opaque object).
- The mutation-class precedent (`axis_10.concrete_bypass_attempts[]`) is already an unconstrained array of arbitrary-shape objects in coverage_map; adding `axis_13.runtime_contract_probes[]` follows the same shape (no schema break).
- Downstream consumers: only round-checker reads coverage_map; the new clauses (vii)+(viii) are the only consumer of the new field.

Additive, zero blast radius on schema validators.

### Criterion 7 — F-001 reproduction integrity (8-guard reproduction)
**Status:** PASS.

Walked through the design's axis-13.e procedure for each of F-001's 8 guards:

| Guard | Wired in settings.json | Reads only `${1:-}` | Probable axis-13.e outcome |
|---|---|---|---|
| destructive-guard.sh | Yes (PreToolUse:Bash line 11) | Yes (line 25) | argv_exit=2, stdin_exit=0 → DISCREPANCY → P0 emitted |
| prompt-guard.sh (Bash fallback) | Yes (PreToolUse:Write\|Edit\|Agent line 23 fallback) | Yes (line 32) | argv_exit=2, stdin_exit=0 → DISCREPANCY → P0 |
| path-guard.sh | Yes (PreToolUse:Write\|Edit line 29) | Yes (line 16) | argv_exit=2, stdin_exit=0 → DISCREPANCY → P0 |
| quarantine-guard.sh | Yes (PreToolUse:Read\|Bash line 41) | Yes (line 28) | argv_exit=2, stdin_exit=0 → DISCREPANCY → P0 |
| sequence-guard.sh | Yes (PreToolUse:Bash line 53) | Yes (line 38-41) | DISCREPANCY → P0 |
| exfil-guard.sh | Yes (PreToolUse:Bash line 71) | Yes (line 37) | DISCREPANCY → P0 |
| subagent-guard.sh | Yes (PreToolUse:Bash line 65) | Yes (line 31-35) | DISCREPANCY → P0 |
| grader-search-guard.sh | Yes (PreToolUse:Bash line 59) | Yes (line 33-36) | DISCREPANCY → P0 |

All 8 satisfy the design's "minimum probe set" rule (axis-1 extracted_set ∩ settings.json PreToolUse|PostToolUse with no positional argv). A diligent auditor following 13.e would:
1. Parse settings.json matchers (identify the 8 guards).
2. For each, run BOTH invocation contracts.
3. Observe `argv_exit != stdin_exit` → clause (viii)'s discrepancy class fires.
4. Emit P0 per discrepancy with the (guard, payload, argv_exit, stdin_exit) tuple.

**Expected output:** ~8 P0 findings (or 1 rolled-up P0 with 8 evidence rows + 7 P1 per-guard satellites; either shape is contract-compliant per axis-13.e prose). Comfortably above the AC-6b in_band[10,35] floor when combined with F-001's other 3 P1/P2/P3 findings (which axis-13.e doesn't surface but exist in pristine framework regardless). Methodology reproduction integrity: VERIFIED.

### Criterion 8 — Adversarial probe (failure mode not caught by design)
**Status:** Three observations, none rising to blocking.

**Observation A (NIT-3 already covered):** H-E fixtures must satisfy (i)-(vi) before reaching (vii)+(viii); design §2 Change C doesn't make this explicit. Already noted in criterion 4.

**Observation B (NEW, NIT-5 — non-blocking):** The design's clause (viii) "Discrepancy-classification gate" requires the auditor to emit a finding citing the guard FILENAME whenever `argv_exit != stdin_exit`. But what if the auditor emits ONE rolled-up finding citing multiple guards (the rational shape — F-001 itself is one rolled-up P0)? The clause says "MUST have emitted at least one finding (any severity) whose `cite[]` includes the guard filename." This is satisfied by a rolled-up finding IF its `cite[]` array contains the guard filename. So the rolled-up shape is COMPATIBLE with clause (viii) by construction. But the design should make this explicit because auditors reading the prose may worry that they need one-finding-per-guard. **Recommendation:** add a sentence to clause (viii): *"A rolled-up finding citing N guards satisfies the gate for each cited guard."* Non-blocking.

**Observation C (NEW, NIT-6 — non-blocking, methodological):** F-001's probe surfaced 11 findings, but only 8 of them come from axis-13.e's procedure. The other 3 (F-002, F-003, ... — the schema-drift, hook-classification-count, fix-plan-emit drift) come from OTHER methodology techniques (jq-diff, run-all.sh observation). The design closes AC-6b methodologically by adding axis-13.e for the 8-guard class but does NOT extract the other 3 techniques (test-suite-end-to-end-runs, schema-vs-impl jq-diff, spec-vs-fs sweep). The methodology lesson #2 (jq diff) and #3 (run test suite end-to-end) from the probe findings are NOT absorbed into the design. **Risk:** Wave-4 T7 NC re-run depends on the upgraded auditor surfacing >= 10. If the auditor follows axis-13.e diligently it gets ~8 P0; combined with other axes' baseline findings (which may or may not include the schema-drift / test-failure / spec-fs-drift classes) it MAY reach 10 — but the design's MARGIN IS THIN. **Recommendation:** consider absorbing methodology lessons #2 and #3 into a separate sub-axis (or a single "behavioural probe corollary" paragraph in 13.e) as a defensive measure. Not blocking R-AT-C-04 G5 PASS, but flagging as a potential Wave-4 contingency.

**Observation D (NEW, NIT-7 — non-blocking, scope):** The design's §7 out-of-scope acknowledges "Fixing the 8-guard stdin-envelope bypass in source — that's a SEPARATE owner-triage track item." Good honesty. But P0 framework defects sitting open while the R-item that detects them lands is a SHIPPING REALITY worth surfacing to the owner explicitly. Phase-7 master plan §6 acknowledges this scope boundary per the design's own citation — but the owner should be reminded once more that landing R-AT-C-04 means "AC-6b methodology PASS + 8-guard P0 STILL OPEN in pristine framework." Recommend adding to §7 a one-line owner-visible reminder: *"Owner note: closing R-AT-C-04 does NOT fix the 8-guard runtime-envelope bypass; the P0 defect remains live in pristine framework until a separate owner-triage R-item lands."* Non-blocking.

---

## Blocking findings (numbered)

**None.** All 8 criteria PASS or PASS-WITH-NIT.

---

## Non-blocking suggestions (numbered NITs)

| # | NIT | Severity | Location | Suggested change |
|---|---|---|---|---|
| NIT-1 | Design's stated reason for "13.e" naming is technically inaccurate (axis-10.d is NOT axis-13.d). Operational result defensible but justification should be tightened. | Cosmetic | DESIGN.md §2 Change A line 26 parenthetical | Rewrite per criterion 1 option (A) text. |
| NIT-2 | Marker carve-out instruction inherited from R-AT-C-02 is over-cautious for axis-13.e's echo-pipe-to-Bash contract. | Cosmetic | DESIGN.md §2 Change A lines 77-83 | Clarify: marker only needed if Write tool materializes payload to disk; echo-pipe-to-Bash does not need it. |
| NIT-3 | H-E fixtures must satisfy clauses (i)-(vi) so simulator does not short-circuit. | Minor | DESIGN.md §2 Change C | Add one-line note to the table or change description. |
| NIT-4 | §1 line 20 fallback "or accept N=11 from Wave-0 probe" is disqualified by §8. | Minor | DESIGN.md §1 line 20 | Drop the "or accept N=11" parenthetical; rely on §8's binding policy. |
| NIT-5 | Clause (viii) should explicitly allow rolled-up findings. | Cosmetic | DESIGN.md §2 Change B clause (viii) | Add: "A rolled-up finding citing N guards satisfies the gate for each cited guard." |
| NIT-6 | Methodology lessons #2/#3 (jq diff, end-to-end test run) NOT absorbed; Wave-4 margin thin. | Methodological | DESIGN.md §2 (advisory) | Consider a "behavioural probe corollary" paragraph absorbing lessons #2 and #3, OR document as Wave-4 contingency. |
| NIT-7 | Owner-visible reminder that closing R-AT-C-04 leaves 8-guard P0 OPEN. | Cosmetic | DESIGN.md §7 | Add one-line owner reminder. |

---

## Final verdict

**PASS-WITH-CHANGES.**

The design correctly identifies the empirical methodology gap (F-001 P0), translates it into a procedural axis (13.e) that any future auditor can mechanically follow, and wires the round-checker enforcement gates (clauses vii+viii) that prevent silent-skip futures. The blast-radius analysis is honest, the staging (§8) correctly separates methodology-landed from empirical-PASS, and the F-001 reproduction integrity (criterion 7) gives me high confidence the upgraded auditor will surface >= 8 P0 findings on a Wave-4 T7 NC re-run. The 7 NITs are all editorial/clarifying — none change the design's load-bearing shape. G3 entry is approved conditional on the designer absorbing NITs 1-5 (NITs 6-7 are advisory only).

The methodology-vs-defect honesty boundary (§7) is a model of how Phase 7 R-items should be framed: the R-item closes the AUDIT GAP, not the defect the audit gap was hiding. Owner triage of the 8-guard P0 itself is a separate, owner-authorized track.

**Recommendation to orchestrator:** advance to G3 implementation after designer commits NIT-1 through NIT-5 fixes. Confidence: 8/8 criteria verified; 0 blocking; 7 non-blocking NITs.
