# R-AT-C-02 — Critic R2 Verdict

**Verdict:** PASS
**Date:** 2026-05-26
**Reviewer:** critic (clean-room R2)
**Design under review:** `audit-trail-review/PHASE-7-RITEM-R-AT-C-02-DESIGN-R2.md`
**R1 verdict referenced:** `audit-trail-review/PHASE-7-RITEM-R-AT-C-02-CRITIC-R1.md` (BLOCKING, 5 BFs)

> **Empirical note:** unlike R1, this verdict file did NOT have to defuse literal injection patterns — the R2 design itself drops the literal-payload corpus file and references patterns by description only (BF-4 root-cause closure). The verdict file therefore writes cleanly through `apex-prompt-guard.cjs` on first attempt.

---

## Per-BF closure verification

### BF-1 closure
**Verdict:** CLOSED

**Evidence:**

R2 §2.C clause (vi) ("Guard-name normalization contract") specifies normalization unambiguously: *"take the auditor's `axis_10.concrete_bypass_attempts[i].guard` field; apply `tolower()`; trim leading/trailing whitespace; preserve `.sh` / `.cjs` / `.ps1` extension"* + *"Strict equality only. NO substring matching; NO regex matching; NO fuzzy matching."* This is a deterministic contract — any two implementations following clause (vi) produce identical verdicts.

R2 §2.C clause (iii) specifies match-equality with a documented JSON-decode normalization step: *"`payload` string-equals an element of the fixture's `boundary_variants[]` array (exact equality after both sides are normalized via JSON-decode if quote-escaped)"*. The JSON quote-escape edge case from R1's concern is explicitly handled.

The `payload_class` ID-keyed branch in (iii) is coherent and bounded: it admits a string-equality match between the auditor's recorded `payload_class` field and an element of `boundary_variant_ids[]`. False-positive risk concern: an auditor could in principle record an arbitrary `payload_class` string without actually firing the literal probe — BUT the fixture entries that allow ID-keyed match are only those where literals can't go on disk (prompt-guard). For those entries, the auditor still constructs the literal at runtime under marker carve-out and a downstream `audit_probe_allowed` event in `.apex/event-log.jsonl` (security.cjs:332) provides the forensic trail. The ID-keyed branch is defensible as a documentary contract for class membership, with the live-probe enforcement living in axis-10.c's marker-protected Bash invocation. Not blocking.

R1 BF-1 issue ("contains undefined") is fully closed.

### BF-2 closure
**Verdict:** CLOSED

**Evidence:**

R2 §2.C clause (ii) ("Per-guard coverage floor") enforces: *"For each entry in the UNION of `fixture.regex_word_boundary[]`, `fixture.case_folding[]`, `fixture.silent_failure[]`, `fixture.counter_swallow[]`, the auditor's `axis_10.concrete_bypass_attempts[]` MUST contain >= 1 entry whose normalized guard name string-equals the fixture entry's `guard_canonical_name`"*.

Walking the path-guard-only trial scenario from BF-2:

1. Trial has axis_10 entries for `path-guard.sh` only (with full boundary variants).
2. Round-checker iterates fixture union. Fixture's `regex_word_boundary[]` contains `path-guard.sh` AND `prompt-guard.sh`. `case_folding[]` contains `prompt-guard.sh`. `silent_failure[]` contains `_state-update.sh` AND `session-log.sh`. `counter_swallow[]` contains `test-runner-counter`.
3. Coverage check for `prompt-guard.sh`: missing in axis_10. Clause (ii) emits P1 `axis_10_guard_coverage_gap` citing `prompt-guard.sh` + posture `clean-pending-spot-check` + Status `CONTINUE TO R<N+1>`.
4. Trial does NOT close. H-B2 stays open until prompt-guard probes are added.

The `BLIND SPOT` exception in (ii) requires an EXPLICIT marker — the entire `axis_10` field must be marked `BLIND SPOT` with rationale (matches the existing CR-08 rung). It is NOT a per-guard waiver; an auditor cannot exempt only prompt-guard while leaving path-guard probed. This narrowness keeps the exception from being a too-easy escape hatch.

Layer test H-D7 (added in §2.D) wires this exact scenario as a synthetic transcript. R1 BF-2 fully closed.

### BF-3 closure
**Verdict:** CLOSED

**Evidence:**

R2 §2.D matrix adds row H-D6: *"fixture file `mutation-class-probes.json` DELETED before round-checker runs → P1 `mutation_class_fixture_missing` + Status `CONTINUE TO R<N+1>`."*

H-D6 distinguishes from H-D5 cleanly:
- **H-D5** (axis_10 empty entries with fixture present) → fires existing `axis_10_blind_spot` rule.
- **H-D6** (fixture absent on disk regardless of axis_10 contents) → fires the NEW clause (i) `mutation_class_fixture_missing`.

These are mutually exclusive code paths — the implementation cannot satisfy one by accidentally satisfying the other.

Load-bearing assertion: if the implementer forgets to wire clause (i)'s fixture-readability gate, H-D6 will fail (because the implementation will fall through to subsequent clauses (ii)-(v) which all `jq` against a missing file → likely either crash or emit a different verdict). H-D6 therefore protects exactly the silent-regression risk R1 identified.

R1 BF-3 fully closed.

### BF-4 closure
**Verdict:** CLOSED

**Evidence (three sub-points):**

**(a) Marker carve-out scope verification.** Read `framework/hooks/security.cjs:278-339`. The carve-out:
- Requires marker prefix `__APEX_AUDIT_PROBE__:` on `freeText` (security.cjs:281).
- Requires three-factor match: `e.status === 'in_flight'` AND `e.agent_id === agentId` AND `e.agent_name === 'framework-auditor'` AND `e.audit_probe_nonce === nonce` (security.cjs:306-309).
- On success, emits `audit_probe_allowed` event and returns true (caller bypasses pattern matching).

The `freeText` is extracted from `content/new_string/prompt/command/description` (per the function comment at security.cjs:269-270). Crucially, this means the carve-out applies to ALL PreToolUse hook invocations that route through security.cjs's marker check — including Bash invocations (heredoc command), Write/Edit (content/new_string), and Agent (prompt). The in_flight framework-auditor at runtime can therefore construct literal injection literals in a Bash heredoc, pass them through stdin to the guard-under-test, and the host's prompt-guard.cjs will allow it on marker presence. R2's "literals constructed in-memory under marker carve-out" claim is empirically supported.

**(b) Fixture content does NOT trip prompt-guard.** Reviewed R2 §2.A fixture JSON literally (lines 38-113 of DESIGN-R2). The JSON contains:
- `guard_canonical_name`, `contract_imp`, `canonical_payload`, `boundary_variants` (with safe path strings like `../../etc/passwd`, `..//../etc/passwd`).
- `canonical_payload_id`, `boundary_variant_ids` (opaque ID strings like `PG-INSTR-OVERRIDE-001`, `PG-CASE-LOWER`).
- `payload_construction_protocol` (English prose describing the runtime protocol).
- `case_variant_ids`, `probe_description`, `expected_stderr_contains_token`.

Cross-checked these strings against `framework/test-fixtures/security-patterns.json prompt_injection_patterns[]` (5 patterns): instruction-override regex, role-hijacking regex (`you are now\s+.+`), prompt-framing regex (`^[\s\t]*system:`), code-fence-with-system-marker, priority-injection (`^[\s\t]*(IMPORTANT|CRITICAL):`). None of the fixture's literal content matches any of these patterns. The ID strings are deliberately opaque to avoid pattern collision. R2 fixture content is safe to write via Write tool through prompt-guard. (The path-guard `../../` literals are NOT in the prompt-guard pattern set — those are content patterns, not path-traversal patterns.)

**(c) Construction protocol in axis-10.c / axis-10.a.** Read framework-auditor.md:222-230 (axis-10.a apex-prompt-guard.cjs envelope) — line 227-230 explicitly cites the existing protocol: *"envelope with `tool_input.content` containing the canonical-override-marker probe (paraphrased — do NOT use the literal canonical phrase per the known workaround in `detector-review/RESUME-PROMPT.md`)"*. RESUME-PROMPT.md exists on disk (verified via filesystem). Read framework-auditor.md:264-278 (axis-10.c marker construction): the three-factor marker grammar `__APEX_AUDIT_PROBE__:<your-nonce>:<your-agent-id> env APEX_BYPASS_TEST=1 bash framework/hooks/<guard> "<payload>"` is documented verbatim and is the exact invocation shape R2's `payload_construction_protocol` field references. The protocol R2 invokes does exist in the file at the cited line ranges.

R1 BF-4 fully closed. The corpus-file write step is DROPPED entirely; the only writes Wave-1 performs are JSON metadata (safe through prompt-guard) and English prose (safe). Wave-1 will not hit the PreToolUse block that empirically blocked R1's verdict drafts twice.

### BF-5 closure
**Verdict:** CLOSED

**Evidence (three sub-points):**

**(a) Verbatim `old_string` match.** Read framework-auditor.md lines 297-302 verbatim. The file contents are:
```
    c. Capture exit code. Expected: non-zero (guard fires).
       Observed: record literally in the `concrete_bypass_attempts`
       entry.
    d. Bypass successful (exit 0 when guard's contract says block)
       → emit P0 finding citing the guard file + the captured
       bypass payload + the captured exit code.
```

R2 §2's Change B-pre `old_string` block is character-by-character identical (same indentation, same backticks around `concrete_bypass_attempts`, same Unicode arrow `→`, same line breaks). The Edit will land deterministically.

**(b) `new_string` is a clean re-letter.** R2's `new_string` differs from `old_string` by exactly two character substitutions (`c.` → `e.`, `d.` → `f.`). Semantic content unchanged: same exit-code capture instruction, same P0-emission rule, same payload + exit-code citation requirement. No P0-emission contract loss.

**(c) Cross-reference safety.** Grep'd `framework/` for literal `axis-10.c` / `axis-10.d` / `axis-10.e` / `axis-10.f` — only hits are in framework-auditor.md itself (the very block being edited). `round-checker.md` has ZERO hits for any axis-10.{letter} literal reference (verified: `grep -c "axis-10.c\|axis-10.d\|axis-10.e\|axis-10.f" round-checker.md` returned 0). Re-lettering c./d. → e./f. cannot break any framework cross-reference. Audit-trail-review markdown files contain 10 historical references to axis-10.X / axis-13.X but those are review-archive prose, not enforcement.

R1 BF-5 fully closed. Wave-1 implementer has a verbatim, deterministic Edit-tool contract that cannot collide with the orphan duplicate or accidentally over-replace.

---

## NBS verification (advisory)

- **NBS-1 (drop aspirational "optional but recommended" schema):** APPLIED. R2 §8 condition list no longer contains the "validates against any added JSON Schema (optional but recommended)" language. Replaced by condition 8 ("`mutation-class-probes.json` does NOT contain literal instruction-override / role-marker injection strings") which is mechanically verifiable. Closed.
- **NBS-2 (clarify G5 = design vs empirical):** APPLIED. R2 §8 opens with *"G5 = design+impl contract (not empirical AC-5b closure). AC-5b empirical closure is a Wave-4 collective gate (C5 corpus re-run); G5 closes the design contract only."* Closed.
- **NBS-3 (add AUDIT-TRAIL-STANDARD.md:309 to blast radius):** APPLIED. R2 §3 blast-radius matrix includes a new row for `framework/docs/AUDIT-TRAIL-STANDARD.md:309` with one-line rename (Change E in §2). Closed.
- **NBS-4 (out-of-scope language about not modifying standard):** APPLIED-BY-SUPERSESSION. R2 §0 explicitly notes NBS-4 is superseded by NBS-3 (the standard IS now touched via Change E). §9 doesn't conflict with NBS-3 — it lists Change E as in-scope (one-line rename). Coherent.

All 4 NBS items applied. No carryover advisories.

---

## NEW blocking findings (if any)

**None.** R2 did not introduce new structural risks. Two minor observations (NOT blocking):

1. R2 §2.D matrix lists 7 tests (H-D1..H-D7) but §6 implementation plan Commit 5 says *"`framework/test-fixtures/round-checker-h-d-{1..7}.jsonl` (NEW ×7) + `framework/tests/test-audit-trail-layer.sh` H-D1..H-D7 ADD"* — and §8 condition 1 says *"All 7 new layer tests pass (40/40 → 47/47)"*. Numbers consistent across §2.D, §3, §6, §8. (R1's §6 said 5; R2's §6 correctly updated.) No discrepancy.

2. R2 §3 blast-radius table totals *"10 files"* but actually enumerates 7 logical rows (one of which is "×7" for H-D fixtures and one of which is for the orphan letter repair living in the same .md file as Change B). The arithmetic resolves to: 1 mutation-class-probes.json + 1 framework-auditor.md (two distinct edits in same file) + 1 round-checker.md + 1 test-audit-trail-layer.sh + 7 round-checker-h-d-{1..7}.jsonl + 1 AUDIT-TRAIL-STANDARD.md = 12 paths touched OR 6 distinct files touched (counting same file once). The "10 files" claim in §3 conflates these. Not blocking — the implementation plan §6 is clear on what gets touched per commit. Documentary count-off only.

---

## Final verdict

**PASS.** All 5 R1 BFs are closed with verifiable design-side contracts:

- **BF-1** → §2.C clauses (iii) and (vi) provide deterministic match-equality + normalization contract.
- **BF-2** → §2.C clause (ii) enforces per-guard coverage floor via fixture-union iteration; BLIND SPOT exception is narrow (entire-axis only, not per-guard).
- **BF-3** → §2.D adds H-D6 (fixture-missing branch test) distinct from H-D5 (axis-empty branch); load-bearing.
- **BF-4** → Corpus file DROPPED; fixture stores ID-keyed metadata + safe path literals only; live empirical confirmation that R2 fixture content does NOT trip prompt-guard (verdict file itself writes cleanly); construction protocol grounded in existing axis-10.a/c blocks under marker carve-out.
- **BF-5** → §2 Change B-pre re-letters orphan c./d. → e./f. with verbatim `old_string` / `new_string` boundaries; framework-side cross-reference safety verified (zero literal `axis-10.{letter}` references in round-checker.md or anywhere outside the auditor file being edited).

All 4 NBS advisories applied (NBS-1 dropped aspirational language; NBS-2 staged G5 from empirical; NBS-3 added Change E for standard rename; NBS-4 superseded by NBS-3).

The design is ready for **G3 implementation**. Wave-1 implementer's ordering note in §6 (Commit 2 B-pre MUST land before Commit 3 B) is empirically necessary — confirmed by re-reading the auditor file's current line numbers — and is documented in R2.

**Per owner directive 2026-05-25:** G2 critic PASS unlocks G3 implementation. No further design iteration required for this R-item.
