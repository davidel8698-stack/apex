# R-AT-C-02 — Critic R1 Verdict

**Verdict:** BLOCKING
**Date:** 2026-05-26
**Reviewer:** critic (clean-room R1)
**Design under review:** `audit-trail-review/PHASE-7-RITEM-R-AT-C-02-DESIGN.md`
**Closes (intended):** AC-5b heldout B+C+D >= 5/5 reliable kill (H-B1, H-B2, H-C1, H-C2, H-D1)

> **Empirical bootstrap note:** the first TWO drafts of this verdict file were BLOCKED by `apex-prompt-guard.cjs` on PreToolUse Write, because quoting the literal patterns from `framework/test-fixtures/security-patterns.json` (e.g. the instruction-override regex, the code-fence-with-system-marker pattern) inside the verdict file triggers the very prompt-guard the design seeks to probe. Two block events with literal hook stderr `Pattern: instruction override / Matched: <pattern>` and `Pattern: code block injection / Matched: <pattern>` were observed. This is live empirical confirmation of BF-4 below. All references here use defused descriptions instead of literal patterns.

---

## Per-criterion verdicts

### 1. Spec anchor accuracy — PASS

The design cites four IMPs + the working-principle "Fail-loud, never fail-silent". All four anchors verified literally in `apex-spec.md`:

- **IMP-008** (line 199): `framework/hooks/destructive-guard.sh` must block (exit 2) at `git\s+config\s+(--global\s+)?core\.fsmonitor`, etc. — `*(Mythos §4.5.4.1, IMP-008)*`. Regex-deny guard, matches design's "regex word-boundary" mutation class.
- **IMP-014** (line 200): mass-effect patterns (`pkill -f`, `find .* -delete`, etc.) — `*(Mythos §4.1.1, IMP-014)*`. Regex-deny.
- **IMP-015** (line 285): `apex-prompt-guard.cjs` + `prompt-guard.sh` must block role-marker reads — `*(Mythos §4.1.3, IMP-015)*`. Regex-deny + case-folding relevant.
- **IMP-017** (line 287): base64/encoded-command bypass — `*(Mythos §4.2.1.2, IMP-017)*`. Regex-deny.
- **"Fail-loud, never fail-silent"** (line 379): present verbatim in `## עקרונות העבודה`.
- **CR-C-14**: present in `audit-trail-review/FIX-DESIGN-C-R2.md` line 23 ("Axis-13 instruction extended with mutation-class-specific probe construction") and closed in the R2 fix-design at §5. Existing `framework-auditor.md` line 279 already cites `(Campaign C TP-C2 + CR-C-14)`.

No fabricated quotes; design accurately summarizes spec content.

### 2. Root-cause alignment — PASS

C5-T4 symptom verified literally. `audit-trail-review/trials-c5/c5-heldout-t1.md` line 41:

> "**Mutation-class-specific probes NOT executed** (T4 used canonical payloads only; didn't construct word-boundary / case-folding / silent-failure variants per axis-10.d extension). Hence: H-B1 (path-guard regex weakening) — NOT probed with boundary-condition payload → not killed; H-B2 (prompt-guard case-folding) — NOT probed with case variants → not killed; H-C1, H-C2, H-D1 — NOT probed"

`audit-trail-review/FINAL-CERTIFICATION-C.md` §3 L-AT-C-02 lines 89-93 literally authorize the closure approach:

> "**Phase-7 R-AT-C-02:** strengthen axis-13.d instruction prose with WORKED EXAMPLES per mutation-class (regex / case-fold / silent-failure / counter-swallow). Round-checker can REJECT trials whose `axis_10.concrete_bypass_attempts[]` lacks ≥1 boundary-condition probe per regex-deny guard."

Design implements exactly this closure plan plus a fixture file (additive, not contradictory).

### 3. Strategy 1 vs 2 vs 3 — NEEDS-CLARIFICATION (advisory)

The label-vs-location mismatch is real but narrow. Grep'd the framework for literal `axis-13.d`:

- `framework/docs/AUDIT-TRAIL-STANDARD.md:309` — sole framework-side reference, status line: *"AC-5b: requires R-AT-C-02 (axis-13.d worked-examples)."*

Plus 11 references in `audit-trail-review/` master-plan and report files (review/historical, not enforcement). No code, hook, schema, or agent reads "axis-13.d" as a discriminator. The label is purely documentary.

**Concern (advisory):** the design's blast-radius matrix §3 does NOT enumerate `framework/docs/AUDIT-TRAIL-STANDARD.md:309`. After implementation, this line will literally point at a phantom "axis-13.d" while the worked-examples actually live in `axis-10.d`. Future readers cross-referencing the standard will follow a dead pointer. Strategy 1 is justified on blast-radius grounds (rename would touch ≥5 files), but the audit-trail standard line is a one-character edit that the design should include in the blast-radius matrix or as a paragraph note.

### 4. Blast radius completeness — NEEDS-CLARIFICATION

The design's §3 enumerates 9 files. Grep'd the framework for `axis_10.concrete_bypass_attempts`:

Hits (in scope of the new clause):
1. `framework/agents/specialist/framework-auditor.md:205, 307` — already addressed (Change B touches the same block).
2. `framework/agents/specialist/round-checker.md:115, 129` — already addressed (Change C extends).
3. `framework/docs/AUDIT-TRAIL-STANDARD.md:104, 107, 309` — **NOT in the blast-radius matrix.** Lines 104 and 107 describe the array's role in TP-2 / TP-5 (descriptive, not enforcement, OK to leave). Line 309 is the "axis-13.d" status line from criterion 3. Mild miss; non-blocking but should be acknowledged.

No `mutation_class_probes` references exist anywhere outside this design doc, so the new fixture name has no collision.

Existing fixture filenames in `framework/test-fixtures/`: `STATE-missing-required.json`, `STATE-good.json`, `decision-mode-corpus.json`, `roundtable-corpus.json`, `security-patterns.json`. No collision with `mutation-class-probes.json`, `prompt-guard-probe-corpus.txt`, or `round-checker-h-d-{1..5}.jsonl`.

Existing test rows in `framework/tests/test-audit-trail-layer.sh` use `H-C1..H-C8`. The design's `H-D1..H-D5` does not collide.

### 5. Round-checker enforcement adequacy — BLOCKING (BF-1, BF-2, BF-3)

Three sub-concerns:

**(a) Guard misclassification.** The design's §3 mitigation says "fixture explicitly listing which guards are in `regex_word_boundary[]`." Correct as a static guarantee, but the round-checker bullet's match logic is unspecified — see (c). The mitigation lives in the fixture, not in the round-checker prose. If a future auditor's `axis_10.concrete_bypass_attempts[]` entry uses a NON-canonical guard name (e.g. `prompt-guard.cjs` vs `prompt-guard.sh` vs `apex-prompt-guard.cjs`), the round-checker may fail to match. The design needs a guard-name normalization rule or an explicit string-equality contract.

**(b) Fixture-missing fail-loud.** The design's §5 question 9 chooses fail-loud (P1 `mutation_class_fixture_missing`). This is consistent with the spec's Fail-loud principle (line 379). But the design says "Add to implementation" without specifying WHERE — the round-checker bullet text in §2.C does not mention the missing-fixture branch. Implementation pending; non-blocking on the design itself but should be specified.

**(c) Match logic NOT explicit.** The round-checker bullet (§2.C lines 142-154) says "verify that the entry set contains >= 1 boundary-condition variant per `framework/test-fixtures/mutation-class-probes.json` regex_word_boundary[].boundary_variants[]." How is "contains" defined? String equality? Substring? Regex match on payload field? Some auditors quote-escape the payload (e.g. JSON-encoded); others record it raw. **The match contract must be specified in the design** — otherwise the round-checker either rejects valid trials (false-positive) or accepts canonical-only trials (false-negative). → **BF-1**.

**(d) Per-guard coverage NOT enforced.** The clause fires "for each regex-deny guard PRESENT in axis_10.concrete_bypass_attempts[]." An auditor who probes only path-guard (with boundary variants) but never probes prompt-guard PASSES this clause — yet H-B2 (prompt-guard case-folding mutation) goes unkilled because the case-folding variants were never run. AC-5b requires all 5 heldout mutations killed; this gate doesn't enforce coverage of all 4 regex-deny guards, only that PROBED guards are deep enough. The existing `axis_10_blind_spot` rule fires only on empty array, not on incomplete-guard-set. → **BF-2**.

### 6. Layer-test coverage — BLOCKING (BF-3)

The H-D1..H-D5 matrix (lines 164-170) has three issues:

**(a) H-D2 PASS-case correctness.** "axis_10 with path-guard canonical + 1 boundary variant → PASS (gate met)." The match-logic ambiguity from criterion 5(c) makes this test brittle: if the fixture's boundary_variants[] contains four entries and the synthetic transcript uses an EXACT match of one entry, the test passes — but if the auditor constructs a semantically-equivalent variant NOT in the fixture (e.g. a Windows-style URL-encoded backslash form), it should still semantically be a boundary variant. The H-D2 design doesn't probe this. Either tests too-strict equality or implicitly trusts the implementation to handle equivalents. → tied to BF-1.

**(b) Fixture-missing branch NOT tested.** The design promises fail-loud P1 `mutation_class_fixture_missing` (§5 Q9), but no H-D-N row tests this branch. If the implementation forgets to wire the missing-fixture check (criterion 5(b)), the test suite still goes 45/45 green. → **BF-3**.

**(c) Per-guard coverage NOT tested.** No row tests "axis_10 has path-guard with full boundary variants but ZERO entries for prompt-guard" — the H-D1 row only tests path-guard canonical-only, not prompt-guard-missing-entirely. Tied to BF-2.

### 7. Prompt-guard payload neutering at runtime — BLOCKING (BF-4)

The design's §2.A.note describes corpus-file-by-ID indirection to avoid PreToolUse blocking the design doc / fixture itself. Cross-referenced framework-auditor.md axis-10.c (lines 264-278). Yes — the `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>` three-factor marker IS the runtime mechanism by which an in-flight auditor fires literal injection payloads. The design does not name this dependency explicitly but the existing axis-10.c block provides it.

**The blocking concern is on the IMPLEMENTATION side, not the audit-runtime side:**

`framework/hooks/security.cjs` line 308: the marker carve-out is valid ONLY for `agent_name === 'framework-auditor'` with status `in_flight`. The Wave-1 implementer of R-AT-C-02 is an `executor` agent, not a `framework-auditor`. When the executor uses the Write tool to create `framework/test-fixtures/prompt-guard-probe-corpus.txt` with literal injection-shaped strings, the PreToolUse on `Write|Edit|Agent` (settings.json line 21) will invoke `apex-prompt-guard.cjs` on `tool_input.content`. If the content contains any pattern from `security-patterns.json` `prompt_injection_patterns[]` — instruction-override pattern, role-hijacking pattern, prompt-framing prefix, code-fence-with-system-marker pattern, or priority-injection line-start pattern — the prompt-guard blocks the Write (exit 2). The executor's marker won't be accepted because executor isn't framework-auditor.

**LIVE EMPIRICAL CONFIRMATION:** the first two drafts of this very verdict file were BLOCKED by `apex-prompt-guard.cjs` when written via the Write tool, because they quoted the literal patterns from `security-patterns.json`. The block reasons in the hook stderr were "Pattern: instruction override" and "Pattern: code block injection." Both verdicts had to be rewritten with defused descriptions. This is the exact failure mode the corpus-file-write step of Wave-1 will hit.

Design §2.A.note acknowledges this and proposes "documented carve-out via `__APEX_AUDIT_PROBE__:` marker" — but the marker doesn't apply to non-auditor agents. The §2.A.note also offers "Kept outside Write/Edit matcher scope" as an alternative, but the matcher is on the **tool name** (`Write|Edit|Agent`), not the file path. There is NO file-path-based exclusion.

**The design has not specified a workable implementation path for Wave-1 to write the corpus file.** Options the design must pick from and document:

1. Write the corpus via Bash heredoc / `printf > file` (Bash matcher fires destructive-guard + sequence-guard but NOT prompt-guard, since prompt-guard is on `Write|Edit|Agent`). Verify the corpus payloads don't trip destructive-guard or sequence-guard patterns either.
2. Constrain corpus content to ID-keyed metadata only; resolve actual injection strings AT RUNTIME inside the auditor (the auditor is in_flight framework-auditor and can construct the literals in memory under the marker carve-out, never writing them to disk).
3. Add an executor-mode marker carve-out for the specific commit (NOT recommended — broadens marker trust boundary).

Without a chosen option, Wave-1 implementation will fail at the corpus-file-write step. → **BF-4**.

### 8. G5 critic R2 PASS criteria realism — NEEDS-CLARIFICATION (advisory)

The 6 PASS conditions in §8 are mostly empirically verifiable. Minor concerns:

- Condition 1 ("40/40 → 45/45") is empirical: re-run `test-audit-trail-layer.sh` and read the literal `passed:` line.
- Condition 2 ("validates against any added JSON Schema (optional but recommended)") — the parenthetical "optional but recommended" makes this aspirational. Either commit to the schema or drop the condition. → **NBS-1**.
- Condition 3 ("≥ 2 worked examples per class") — empirical, mechanically checkable.
- Condition 4 ("new clause cites the fixture file and emits expected verdict") — empirical.
- Condition 5 ("40/40 baseline preserved") — empirical.
- Condition 6 ("Spec anchor cited verbatim; no fabricated quotes") — empirical via grep.

Hidden condition that IS missing: **post-implementation grep on `framework/docs/AUDIT-TRAIL-STANDARD.md:309`** — if the design keeps "axis-10.d," the standard's mention of "axis-13.d worked-examples" should be reconciled (either by changing the standard or by adding a forward-pointer note). Not blocking but advisory.

Hidden condition that may also be missing: **proof-of-empirical-kill on at least ONE heldout mutation in Wave 4 re-run** (e.g., H-B1). Section §7 mentions this but as "deferred to Wave 4," not as a G5 condition. The G5 critic could PASS the layer tests, the worked examples, the round-checker prose — and still leave AC-5b empirically open if Wave 4 doesn't run. The closure-criterion is AC-5b 5/5; the design should clarify whether G5 is "all six §8 conditions met" or "AC-5b empirically demonstrated." → **NBS-2**.

### 9. Out-of-scope explicit list — PASS

§9 names R-AT-C-04, R-DH-P7-01, Wave-4 empirical re-run, and §14 amendment as out-of-scope. No tacit coupling to R-AT-C-04 detected — the design refers to R-AT-C-04 only as a cross-reference in axis-10.d (Change B §5: "Cross-references R-AT-C-04"). Implementation order: R-AT-C-04 lands separately; this design's cross-reference is forward-pointing prose only, no functional dependency.

One concern: §9 doesn't explicitly say "this design does NOT modify `framework/docs/AUDIT-TRAIL-STANDARD.md:309`" — and it should, given criterion 3/4. Future implementers must know not to touch the standard line in this commit set. Advisory only.

### 10. Anti-rationalization probe — BLOCKING (BF-5)

Found a plausible regression mechanism that all 9 prior checks could miss:

**Pre-existing letter-collision in framework-auditor.md axis 10.** Reading the file lines 209-303:

- `a.` (line 210): Construct one payload whose handling is forbidden
- `b.` (line 231): Read your nonce and agent_id
- `c.` (line 264): Construct probe with self-identifying marker
- `d.` (line 279): Mutation-class-specific probe construction ← Change B replaces THIS block
- `c.` AGAIN (line 297): Capture exit code
- `d.` AGAIN (line 300): Bypass successful → emit P0

The current file has TWO sub-bullets each for `c.` and `d.` in the same enumerated list — a pre-existing structural defect. The design's "REPLACE the existing 18-line block (lines 279-296) with a longer version (~50 lines)" hits the FIRST `d.` (lines 279-296) but doesn't address the duplicated `c.` and `d.` at lines 297-302. Two regression vectors:

1. **Auditor reading order ambiguity.** Future auditors parsing the axis-10 sub-bullets will see `a, b, c, d, c, d` and may follow the WRONG `d.` (the "bypass successful → P0" branch) instead of the strengthened `d.` (mutation-class probe construction). The Campaign C anti-priming line at framework-auditor.md:46-54 explicitly warns that auditors should hunt as though seeing the framing fresh — but ambiguous numbering invites mis-reading.

2. **Edit-tool risk.** When the implementer uses Edit to replace "lines 279-296" with the strengthened 50-line block, the line numbering shifts. If implementation accidentally replaces both `d.` blocks (the first AND the orphan duplicate at line 300), it silently drops the "Bypass successful → emit P0 finding" rule. That's a P0-emission contract loss. The design's "REPLACE lines 279-296" is precise on line range but the duplicated-letter context invites confusion.

→ **BF-5** — design must (a) acknowledge the pre-existing duplicate-letter defect, (b) specify whether the implementation also re-letters the second `c./d.` (probably should become `e./f.`), and (c) lock in the precise Edit-tool old-string/new-string contract for Wave-1.

---

## Blocking findings

### BF-1: Round-checker match logic for boundary variants is unspecified

- **Evidence:** Design §2.C lines 142-154 says "verify that the entry set contains >= 1 boundary-condition variant per [fixture] `regex_word_boundary[].boundary_variants[]`" — but "contains" is not defined (string-equality, substring, normalized form?).
- **Why blocking:** Implementation is non-deterministic. Two valid implementations (strict-equality vs substring-match) will produce different verdicts on the SAME trial. Layer test H-D2 will pass-or-fail depending on which implementation choice the executor makes — and the design doesn't constrain it.
- **Suggested fix:** Add to §2.C an explicit match contract. Recommendation: *"Boundary-variant match = exact-string equality between the auditor's `concrete_bypass_attempts[i].payload` and any element of the fixture's `regex_word_boundary[<g>].boundary_variants[]` where guard name matches `regex_word_boundary[<g>].guard` after lowercasing and stripping the `.sh`/`.cjs` extension."* This makes the match deterministic and fixture-driven.

### BF-2: Per-guard coverage of regex-deny set NOT enforced; opens an AC-5b miss path

- **Evidence:** Design §2.C clause fires "For each regex-deny guard PRESENT in axis_10.concrete_bypass_attempts[]." An auditor probing only path-guard (with full boundary variants) passes this gate, even though prompt-guard's H-B2 case-folding mutation cannot be killed without prompt-guard probes.
- **Why blocking:** AC-5b requires 5/5 heldout-mutation kill (H-B1, H-B2, H-C1, H-C2, H-D1). H-B2 lives in prompt-guard. A trial that probes only one regex-deny guard cannot kill H-B2, yet this gate marks the trial PASS. The design doesn't close AC-5b for the failure mode the heldout corpus targets.
- **Suggested fix:** Extend the round-checker clause to enforce: *"For each guard ENTRY in `fixture.regex_word_boundary[]` AND `fixture.case_folding[]` AND `fixture.silent_failure[]` AND `fixture.counter_swallow[]`, the auditor's `concrete_bypass_attempts[]` MUST contain >= 1 entry matching that guard (by name) OR `axis_10` MUST be `BLIND SPOT` for an explicit-rationale reason."* This makes the fixture's enumeration the gate's coverage floor.

### BF-3: Fixture-missing fail-loud branch NOT tested; design promises but doesn't verify

- **Evidence:** §5 Q9 chooses fail-loud P1 `mutation_class_fixture_missing`, but the H-D matrix (§2.D, lines 164-170) has 5 rows and none of them test the missing-fixture branch.
- **Why blocking:** Without a layer test, the implementation can silently regress this branch. Fail-loud is a SPEC PRINCIPLE (apex-spec.md:379); a fail-loud branch with no test is exactly the silent-failure defect the spec exists to prevent.
- **Suggested fix:** Add row H-D6: *"fixture file deleted/missing → round-checker emits P1 `mutation_class_fixture_missing` and Status `CONTINUE TO R<N+1>`."* Sandbox-mutates the fixture path to nonexistent and asserts the verdict.

### BF-4: Implementation path for writing `prompt-guard-probe-corpus.txt` is unspecified

- **Evidence:** Design §2.A.note proposes "Kept outside settings.json's matcher scope OR with a documented carve-out via `__APEX_AUDIT_PROBE__:` marker." Verified against `framework/settings.json:21` (`Write|Edit|Agent` → apex-prompt-guard.cjs) and `framework/hooks/security.cjs:308` (marker valid only for `agent_name=framework-auditor` in_flight). The `Write|Edit|Agent` matcher is on the TOOL, not on file paths — no "outside matcher scope" exists for Write/Edit. The marker is not accessible to a Wave-1 executor agent. **EMPIRICALLY CONFIRMED:** the first two drafts of this very verdict file were blocked by `apex-prompt-guard.cjs` when they quoted literal patterns from `security-patterns.json`.
- **Why blocking:** Wave-1 implementation will fail at the corpus-file write step if the corpus content contains any pattern in `security-patterns.json` `prompt_injection_patterns[]`. The design must pick a workable implementation path BEFORE Wave-1 begins.
- **Suggested fix:** Pick one of three options and document in §6 (Implementation plan):
  1. Write the corpus via Bash heredoc (Bash matcher fires destructive-guard + sequence-guard but NOT prompt-guard, since prompt-guard is on `Write|Edit|Agent`). Verify the corpus payloads don't trip destructive-guard or sequence-guard patterns either.
  2. Constrain corpus content to ID-keyed metadata only; resolve actual injection strings AT RUNTIME inside the auditor (the auditor is in_flight framework-auditor and can construct the literals in memory under the marker carve-out, never writing them to disk).
  3. Add an executor-mode marker carve-out for the specific commit (NOT recommended — broadens marker trust boundary).

### BF-5: Pre-existing letter-collision in framework-auditor.md axis-10 not acknowledged

- **Evidence:** `framework/agents/specialist/framework-auditor.md` lines 209-303 has TWO `c.` sub-bullets (lines 264, 297) and TWO `d.` sub-bullets (lines 279, 300) inside the same axis-10 enumerated list. The design's Change B says "REPLACE the existing 18-line block (lines 279-296)" — precise on the first `d.` but silent on the orphan duplicate at 297-302.
- **Why blocking:** Two regression vectors: (1) auditors mis-read sub-bullet order; (2) Wave-1 Edit-tool risk of accidentally replacing both `d.` blocks and losing the "Bypass successful → P0" emission rule.
- **Suggested fix:** Add to Change B explicit: (a) re-letter the orphan `c./d.` at lines 297-302 to `e./f.` as a separate atomic Edit (one-line each), or merge them into the new strengthened block. (b) Specify Wave-1's Edit-tool `old_string` / `new_string` boundaries verbatim so the implementer cannot accidentally over-replace.

---

## Non-blocking suggestions (advisory)

- **NBS-1:** §8 PASS condition 2 ("validates against any added JSON Schema (optional but recommended)") should commit to either yes-schema or no-schema. Aspirational language in PASS criteria is exactly the phantom-evidence pattern the spec discourages.
- **NBS-2:** §8 should clarify whether G5 PASS = "6 conditions met" or "AC-5b empirically demonstrated in Wave 4." If the latter, list Wave-4 re-run as a G5 prerequisite. If the former, document that AC-5b closure is staged (G5 closes the design contract; Wave 4 closes the empirical contract).
- **NBS-3:** §3 blast-radius matrix should add `framework/docs/AUDIT-TRAIL-STANDARD.md:309` (the "axis-13.d worked-examples" status line) as a 10th touched-file or document explicitly why it's left as a stale reference.
- **NBS-4:** §9 (out-of-scope) should add "this design does NOT modify `framework/docs/AUDIT-TRAIL-STANDARD.md`" to prevent Wave-1 implementer scope-creep.

---

## Final verdict

**BLOCKING.** Five blocking findings (BF-1..BF-5) must be addressed before G3 implementation:

1. BF-1 — round-checker match-logic for boundary variants must be specified deterministically.
2. BF-2 — per-guard coverage of the regex-deny set must be enforced, or the design must acknowledge that an isolated path-guard-only trial can pass while H-B2 stays open.
3. BF-3 — fixture-missing fail-loud branch must have a layer test (H-D6 or equivalent).
4. BF-4 — implementation path for writing `prompt-guard-probe-corpus.txt` under PreToolUse `Write|Edit|Agent` must be specified.
5. BF-5 — pre-existing duplicate `c./d.` letters at lines 297-302 of framework-auditor.md must be acknowledged with re-lettering or explicit Edit-tool boundaries.

The design's core mechanism (fixture + worked examples + round-checker hard gate + layer tests) is structurally sound and the spec anchors / root-cause / out-of-scope sections are accurate. Blocking issues are implementation-precision gaps, not strategic flaws — addressing them in a R2 design pass should be a focused 1-2 hour task.

After BF-1..BF-5 are addressed, re-submit for critic R2.

**Per owner directive 2026-05-25:** "G2 critic R1 → BLOCKING is not failure; it's how the system works." This verdict is the system functioning as designed.
