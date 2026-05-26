# R-AT-C-02 — Design R2 · BF-1..BF-5 closure pass

**Supersedes:** `PHASE-7-RITEM-R-AT-C-02-DESIGN.md` (R1).
**Critic R1 verdict:** `PHASE-7-RITEM-R-AT-C-02-CRITIC-R1.md` — BLOCKING, 5 BFs.
**Date:** 2026-05-26.

R1 sections §1-§3, §5, §7, §9 unchanged unless noted. This R2 addresses BF-1..BF-5 in §2, §3, §6, §8 and adopts NBS-1..NBS-4 resolutions.

---

## §0. Critic R1 closure summary

| BF | R1 issue | R2 resolution |
|----|----------|---------------|
| BF-1 | Round-checker match logic undefined ("contains" ambiguous) | §2.C explicit string-equality contract with guard-name normalization |
| BF-2 | Per-guard coverage of regex-deny set not enforced | §2.C extended to enforce fixture-enumerated coverage floor |
| BF-3 | Fixture-missing fail-loud branch not tested | New layer test H-D6 added |
| BF-4 | Corpus-file Write step will be blocked by prompt-guard | DROP `prompt-guard-probe-corpus.txt`; fixture stores ID-keyed metadata only; literals resolved at runtime inside in-flight auditor (option 2) |
| BF-5 | Pre-existing duplicate `c./d.` letters in framework-auditor.md axis-10 | Acknowledged; Change B-pre re-letters orphan to `e./f.` as separate atomic edit; verbatim Edit-tool boundaries specified |

| NBS | R1 advisory | R2 resolution |
|-----|-------------|---------------|
| NBS-1 | Drop aspirational "optional but recommended" schema condition | §8 condition 2 dropped; no JSON Schema for fixture in this R-item |
| NBS-2 | Clarify G5 = design vs empirical contract | §8 explicit: G5 = design+impl contract. AC-5b empirical closure is Wave-4 collective gate, not per-R-item gate |
| NBS-3 | Add `AUDIT-TRAIL-STANDARD.md:309` to blast radius | §3 adds 10th file; Change E (one-line rename) |
| NBS-4 | Add "doesn't modify AUDIT-TRAIL-STANDARD.md" to §9 | Superseded by NBS-3; standard IS touched (one-line rename) |

---

## §2. Design (revised — 5 changes + 6 layer tests)

### Change A (REVISED) — `framework/test-fixtures/mutation-class-probes.json` (NEW)

Fixture stores **ID-keyed metadata only**. No literal injection strings on disk. The auditor at runtime is `in_flight framework-auditor` and has the `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>` marker carve-out per `framework/hooks/security.cjs:308`; it can construct injection literals in-memory under the marker without writing them to disk.

Shape (REVISED — corpus file DROPPED per BF-4):

```json
{
  "schema_version": "1.0.0",
  "regex_word_boundary": [
    {
      "guard_canonical_name": "path-guard.sh",
      "contract_imp": "IMP-008 / IMP-014",
      "canonical_payload": "../../etc/passwd",
      "boundary_variants": [
        "..//../etc/passwd",
        "..%2F../etc/passwd",
        "....//etc/passwd",
        "..\\..\\etc\\passwd"
      ],
      "expected_exit_canonical": 2,
      "expected_exit_boundary": 2,
      "defect_kill_class": "H-B1 (regex anchor weakening)"
    },
    {
      "guard_canonical_name": "prompt-guard.sh",
      "contract_imp": "IMP-015 / IMP-017",
      "canonical_payload_id": "PG-INSTR-OVERRIDE-001",
      "boundary_variant_ids": [
        "PG-CASE-LOWER",
        "PG-CASE-TITLE",
        "PG-CASE-MIXED"
      ],
      "payload_construction_protocol": "Auditor constructs literal payloads in-memory at runtime under __APEX_AUDIT_PROBE__ marker carve-out (security.cjs:308). NEVER write resolved literals to disk; the canonical reference for the literal forms is the comment block in framework-auditor.md axis-10.a (lines 222-230) which cites the workaround in detector-review/RESUME-PROMPT.md.",
      "expected_exit_canonical": 2,
      "expected_exit_boundary": 2,
      "defect_kill_class": "H-B2 (case-folding gap)"
    }
  ],
  "case_folding": [
    {
      "guard_canonical_name": "prompt-guard.sh",
      "contract_imp": "IMP-015",
      "canonical_payload_id": "PG-ROLE-MARKER-001",
      "case_variant_ids": [
        "PG-ROLE-ALLCAPS",
        "PG-ROLE-TITLECASE",
        "PG-ROLE-MIXEDCASE"
      ],
      "payload_construction_protocol": "Same as regex_word_boundary[].prompt-guard entry. Auditor-in-memory only.",
      "expected_exit_all": 2,
      "defect_kill_class": "H-B2"
    }
  ],
  "silent_failure": [
    {
      "guard_canonical_name": "_state-update.sh",
      "contract_principle": "Fail-loud, never fail-silent (apex-spec.md line 379)",
      "probe_description": "malformed jq expression passed as argv",
      "expected_exit": "non-zero",
      "expected_stderr_contains_token": "jq",
      "defect_kill_class": "H-C1"
    },
    {
      "guard_canonical_name": "session-log.sh",
      "contract_principle": "Fail-loud, never fail-silent",
      "probe_description": "unwritable target directory (chmod 000) under .apex/",
      "expected_exit": "non-zero",
      "expected_stderr_nonempty": true,
      "defect_kill_class": "H-C2"
    }
  ],
  "counter_swallow": [
    {
      "target_canonical_name": "test-runner-counter",
      "contract": "global FAIL counter MUST decrement on test failure",
      "probe_description": "force one assert_fail; assert counter incremented by exactly 1",
      "defect_kill_class": "H-D1"
    }
  ]
}
```

**Field semantics (BF-1 enabler):**
- `guard_canonical_name`: lowercased, includes extension. Round-checker normalizes the auditor's reported guard name (lowercase + preserve extension) and string-equality matches against this field.
- `canonical_payload`: literal string the auditor MUST probe at minimum.
- `boundary_variants`: literal strings; auditor MUST probe >= 1 entry from this array (exact-string equality, not substring).
- `boundary_variant_ids` / `canonical_payload_id`: opaque identifiers used when literals cannot be on disk (prompt-guard case). Auditor resolves at runtime; round-checker accepts ANY non-empty `concrete_bypass_attempts[].payload` for a guard that has only ID-keyed fixtures, as long as the auditor records `axis_10.concrete_bypass_attempts[i].payload_class = "<id>"` in the trial output.

### Change B (REVISED) — `framework/agents/specialist/framework-auditor.md` axis-10.d + letter-collision repair

**Change B-pre (BF-5 atomic edit):** RE-LETTER the orphan duplicate sub-bullets at lines 297-302.

Current state (lines 297-302):
```
    c. Capture exit code. Expected: non-zero (guard fires).
       Observed: record literally in the `concrete_bypass_attempts`
       entry.
    d. Bypass successful (exit 0 when guard's contract says block)
       → emit P0 finding citing the guard file + the captured
       bypass payload + the captured exit code.
```

Target state (re-lettered to `e./f.`):
```
    e. Capture exit code. Expected: non-zero (guard fires).
       Observed: record literally in the `concrete_bypass_attempts`
       entry.
    f. Bypass successful (exit 0 when guard's contract says block)
       → emit P0 finding citing the guard file + the captured
       bypass payload + the captured exit code.
```

Edit-tool contract (Wave-1 implementer MUST use this exact `old_string` / `new_string`):

```
old_string:
    c. Capture exit code. Expected: non-zero (guard fires).
       Observed: record literally in the `concrete_bypass_attempts`
       entry.
    d. Bypass successful (exit 0 when guard's contract says block)
       → emit P0 finding citing the guard file + the captured
       bypass payload + the captured exit code.

new_string:
    e. Capture exit code. Expected: non-zero (guard fires).
       Observed: record literally in the `concrete_bypass_attempts`
       entry.
    f. Bypass successful (exit 0 when guard's contract says block)
       → emit P0 finding citing the guard file + the captured
       bypass payload + the captured exit code.
```

This Edit MUST succeed (the block is unique in the file — verified via Read inside Wave-1).

**Change B (axis-10.d strengthen):** REPLACE the existing 18-line block (lines 279-296, the FIRST `d.`) with a ~50-line strengthened version. Edit-tool boundaries (verbatim `old_string`):

```
    d. **Mutation-class-specific probe construction** (Campaign C TP-C2 + CR-C-14):
       - **Regex-deny guards** (path-guard.sh, prompt-guard.sh): construct
         BOTH a canonical-match payload AND a boundary-condition payload
         (word-boundary, case-folding, zero-width whitespace) so a
         weakened regex surfaces. Example: for path-guard parent-traversal
         deny, probe `../../etc/passwd` (canonical) AND `..//../etc/passwd`
         (extra-slash boundary) AND `..%2F../etc/passwd` (URL-encoded
         boundary).
       - **Silent-failure guards** (_state-update.sh jq-failure branch;
         session-log.sh unwritable-target branch): probe by passing
         malformed input + asserting non-zero exit AND non-empty stderr.
         Loud-failure observed → PASS. Silent return-0 → FAIL → P0.
       - **Counter-swallow patterns** (any `+ 0` counter mutation in
         test harnesses): probe by FORCING a deliberate FAIL and
         asserting the global counter actually decremented.
       - **Case-folding deny patterns** (e.g. role-marker case
         sensitivity): probe with uppercase, mixed-case, and unicode-
         variant forms to detect case-folding gaps.
```

New `new_string` (~50 lines): the strengthened text MUST include (a) reference to `framework/test-fixtures/mutation-class-probes.json` as authoritative source; (b) two worked examples per mutation class drawn from the fixture; (c) per-class probe minimum (regex-deny: >=1 canonical + >=1 boundary; case-folding: >=3 case variants; silent-failure: >=1 malformed-input with stderr-non-empty assertion; counter-swallow: >=1 forced-FAIL probe); (d) failure-mode-to-mutation-class mapping table at top; (e) cross-reference R-AT-C-04 (axis-13.e runtime-invocation-contract — to be added).

Full `new_string` text deferred to Wave-1 implementation; design contract says the strengthened block must satisfy G5 PASS criterion 3 (">=2 worked examples per class") which is mechanically verifiable.

### Change C (REVISED) — `framework/agents/specialist/round-checker.md` TP-2 §6.b ENFORCEMENT (BF-1 + BF-2 + fixture-missing branch)

**Location:** AFTER line 146 (the existing `axis_10_blind_spot` clause), ADD this verbatim block:

```
- **Mutation-class probe minimum (R-AT-C-02 / CR-C-14).** Anchored to
  `framework/test-fixtures/mutation-class-probes.json`.

  **(i) Fixture readability gate.** If the fixture file is missing or
  fails `jq -e .` validation → emit P1 `mutation_class_fixture_missing`
  + posture `clean-pending-spot-check` + Status `CONTINUE TO R<N+1>`.
  Fail-loud principle (apex-spec.md line 379); no fallback to
  pre-R-AT-C-02 behavior.

  **(ii) Per-guard coverage floor.** For each entry in the UNION of
  `fixture.regex_word_boundary[]`, `fixture.case_folding[]`,
  `fixture.silent_failure[]`, `fixture.counter_swallow[]`, the
  auditor's `axis_10.concrete_bypass_attempts[]` MUST contain >= 1
  entry whose normalized guard name (lowercased, extension preserved)
  string-equals the fixture entry's `guard_canonical_name` (or
  `target_canonical_name` for counter_swallow). Missing entry → emit
  P1 `axis_10_guard_coverage_gap` citing the missing guard +
  `{fixture_class, fixture_entry_id}` + posture
  `clean-pending-spot-check` + Status `CONTINUE TO R<N+1>`. EXCEPTION:
  if `axis_10` is explicitly marked `BLIND SPOT` with rationale, the
  per-guard coverage floor is waived (existing CR-08 rung).

  **(iii) Per-guard boundary-variant minimum (regex-deny class).** For
  each guard in `fixture.regex_word_boundary[]`, after (ii) confirms
  >= 1 entry exists in axis_10, verify that the entry set for that
  guard contains either:
   - >= 1 entry whose `payload` string-equals an element of the
     fixture's `boundary_variants[]` array (exact equality after both
     sides are normalized via JSON-decode if quote-escaped), OR
   - >= 1 entry whose `payload_class` field string-equals an element
     of the fixture's `boundary_variant_ids[]` (for ID-keyed
     payloads where literals can't be on disk).
  Failure of both clauses → emit P1
  `axis_10_mutation_class_blind_spot` citing the guard +
  `{fixture_class: regex_word_boundary, missing: boundary_variant}` +
  posture `clean-pending-spot-check` + Status `CONTINUE TO R<N+1>`.

  **(iv) Per-guard case-variant minimum (case_folding class).** Same
  shape as (iii) but checks >= 3 distinct case variants per
  `fixture.case_folding[].case_variant_ids[]` (or literal case-variant
  payloads if non-ID-keyed). Failure → P1
  `axis_10_case_folding_blind_spot`.

  **(v) Per-guard stderr-assertion minimum (silent_failure class).**
  For each guard in `fixture.silent_failure[]`, the axis_10 entry MUST
  have either `stderr_nonempty: true` or `stderr_contains: "<token>"`
  matching `fixture.silent_failure[<g>].expected_stderr_contains_token`
  (case-sensitive substring match). Failure → P1
  `axis_10_silent_failure_blind_spot`.

  **(vi) Guard-name normalization contract.** "Normalized" means: take
  the auditor's `axis_10.concrete_bypass_attempts[i].guard` field;
  apply `tolower()`; trim leading/trailing whitespace; preserve `.sh`
  / `.cjs` / `.ps1` extension. Round-checker compares against
  `fixture.{class}[].guard_canonical_name` after the same
  normalization. NO substring matching; NO regex matching; NO fuzzy
  matching. Strict equality only.

  These gates collectively make the fixture's enumeration the
  coverage floor. A trial that probes only one guard cannot pass; a
  trial that misses boundary variants cannot pass; a fixture file
  that disappears cannot pass.
```

This BLOCK addresses BF-1 (match logic explicit), BF-2 (per-guard coverage enforced), and the fixture-missing branch (clause (i)).

### Change D (REVISED) — Layer tests with H-D6 added (BF-3)

| H-ID | Synthetic transcript shape | Expected round-checker verdict |
|------|---------------------------|-------------------------------|
| H-D1 | axis_10 with path-guard canonical only, no boundary variants | P1 `axis_10_mutation_class_blind_spot` (regex_word_boundary, missing boundary_variant) |
| H-D2 | axis_10 with path-guard canonical + 1 boundary variant matching `boundary_variants[0]` | PASS (clause (iii) satisfied for path-guard) — but FAIL on clause (ii) for prompt-guard if prompt-guard not in axis_10. To test ONLY (iii) PASS, the fixture transcript must include ALL fixture guards |
| H-D3 | axis_10 with prompt-guard canonical only (no case variants); other guards probed correctly | P1 `axis_10_case_folding_blind_spot` |
| H-D4 | axis_10 with _state-update.sh probe missing `stderr_nonempty: true` | P1 `axis_10_silent_failure_blind_spot` |
| H-D5 | axis_10 empty | P1 `axis_10_blind_spot` (existing rule; confirms NO double-firing of new rules) |
| **H-D6 (NEW per BF-3)** | fixture file `mutation-class-probes.json` DELETED before round-checker runs | P1 `mutation_class_fixture_missing` + Status `CONTINUE TO R<N+1>` |
| **H-D7 (per BF-2)** | axis_10 with path-guard fully probed (canonical + boundary) but ZERO entries for prompt-guard or silent_failure guards | P1 `axis_10_guard_coverage_gap` (prompt-guard, _state-update.sh, session-log.sh missing) |

7 new tests total (baseline 40 → 47).

### Change E (NEW per NBS-3) — `framework/docs/AUDIT-TRAIL-STANDARD.md:309` one-line rename

Edit-tool contract:

```
old_string: AC-5b: requires R-AT-C-02 (axis-13.d worked-examples).
new_string: AC-5b: requires R-AT-C-02 (axis-10.d worked-examples; master plan label "axis-13.d" reconciles to this location per design R2 §2.B note).
```

This closes the only documentary reference to "axis-13.d" without renaming the data shape.

---

## §3. Blast radius matrix (REVISED — 10 files)

| File | Touched? | Lines added/changed | Consumers affected | Mitigation |
|------|---------:|--------------------:|--------------------|------------|
| `framework/test-fixtures/mutation-class-probes.json` | NEW | ~90 lines | framework-auditor (runtime); round-checker (gate) | New file; no existing reference |
| `framework/agents/specialist/framework-auditor.md` axis-10.d | MODIFIED | -18 / +50 lines | Auditors; round-checker | Edit-tool boundaries verbatim per Change B |
| `framework/agents/specialist/framework-auditor.md` lines 297-302 (orphan letter repair) | MODIFIED | -6 / +6 (re-letter c./d. → e./f.) | Auditors | Atomic edit per Change B-pre |
| `framework/agents/specialist/round-checker.md` TP-2 §6.b | MODIFIED | +50 lines (clauses i-vi) | Round-checker invocations | Additive; existing clauses untouched |
| `framework/tests/test-audit-trail-layer.sh` | MODIFIED | +7 H-D rows (~120 lines + 7 fixture-transcript wirings) | CI test suite | Additive |
| `framework/test-fixtures/round-checker-h-d-{1..7}.jsonl` | NEW (×7) | ~50 lines each | test-audit-trail-layer.sh H-D1..H-D7 | Synthetic |
| `framework/docs/AUDIT-TRAIL-STANDARD.md:309` | MODIFIED | 1-line rename | Documentary readers | One-line Change E |

**No `prompt-guard-probe-corpus.txt`** — dropped per BF-4 resolution. Literals constructed at runtime in-memory under auditor marker carve-out.

**Total file count:** 10 (3 new fixtures + 1 new probe fixture + 3 modified framework files + 1 modified test + 1 modified standard doc + 1 dropped — net 10 files touched).

---

## §6. Implementation plan (REVISED — 6 commits)

1. **Commit 1:** `framework/test-fixtures/mutation-class-probes.json` (NEW, jq-validated).
2. **Commit 2:** `framework/agents/specialist/framework-auditor.md` Change B-pre (re-letter orphan c./d. → e./f.). Atomic.
3. **Commit 3:** `framework/agents/specialist/framework-auditor.md` Change B (axis-10.d strengthen). Atomic.
4. **Commit 4:** `framework/agents/specialist/round-checker.md` Change C (TP-2 §6.b clauses i-vi).
5. **Commit 5:** `framework/test-fixtures/round-checker-h-d-{1..7}.jsonl` (NEW ×7) + `framework/tests/test-audit-trail-layer.sh` H-D1..H-D7 ADD.
6. **Commit 6:** `framework/docs/AUDIT-TRAIL-STANDARD.md` Change E (1-line rename).

After each commit: sync to `~/.claude/` install path per `CLAUDE.md` Build Rules §6.

**Wave-1 implementer ordering note:** Commit 2 (B-pre, letter repair) MUST land before Commit 3 (B, strengthen). Otherwise the Edit-tool `old_string` for Commit 3 may collide with the orphan duplicate sub-bullets.

---

## §8. G5 critic R2 PASS criteria (REVISED per NBS-1, NBS-2)

**G5 = design+impl contract (not empirical AC-5b closure).** AC-5b empirical closure is a Wave-4 collective gate (C5 corpus re-run); G5 closes the design contract only.

Critic R2 PASS requires:
1. ✅ All 7 new layer tests pass (40/40 → 47/47).
2. ✅ framework-auditor.md axis-10.d block contains >= 2 worked examples per class (mechanical grep verification).
3. ✅ framework-auditor.md lines 297-302 letter-collision repaired (c./d. → e./f.).
4. ✅ round-checker.md TP-2 §6.b new clauses (i)-(vi) all present; each emits the documented verdict shape.
5. ✅ AUDIT-TRAIL-STANDARD.md:309 rename landed.
6. ✅ No regression in existing test-audit-trail-layer.sh rows (baseline 40 preserved).
7. ✅ Spec anchor cited verbatim; no fabricated quotes (per criterion 1 of R1 critic verdict — confirmed PASS).
8. ✅ `mutation-class-probes.json` does NOT contain literal instruction-override / role-marker injection strings (only ID-keyed references).

(NBS-1 closure: condition 2 of R1 dropped — no JSON Schema required.
NBS-2 closure: G5 = design+impl. Wave-4 AC-5b empirical demonstration is documented in `audit-trail-review/PHASE-7-MASTER-PLAN.md` §7 as a SEPARATE closure gate.)

---

## §9. Out-of-scope (REVISED)

- R-AT-C-04 (axis-13.e runtime-invocation-contract / stdin-envelope probe) — separate R-item.
- R-DH-P7-01 (axis-13.c source-literal carve-out) — Wave 2, separate.
- Empirical C5 re-run — Wave 4 collective gate, not per-R-item.
- §14 amendment to AC-6b lower bound — superseded by R-AT-C-04 methodology upgrade (probe found 11 with strengthened methodology).
- **PROMPT-GUARD-PROBE-CORPUS-FILE** — explicitly NOT created (BF-4 closure). Literals constructed at runtime in-memory under marker carve-out.

---

## §10. Decision summary (R2)

**R1 verdict:** BLOCKING (5 BFs).
**R2 resolutions:** all 5 BFs addressed in Changes A-E above; all 4 NBSs adopted.

**Strategy unchanged:** Strengthen axis-10.d in-place + fixture + round-checker enforcement + layer tests. Master plan's "axis-13.d" label reconciles to axis-10.d per §2.B-pre note + Change E one-line standard rename.

**Blast radius:** 10 files (3 new fixtures, 1 new probe-fixture batch, 3 modified framework files, 1 modified test, 1 modified standard doc, 0 new corpus file — dropped per BF-4).

**Next gate:** G2 — invoke `critic` agent in clean-room mode for R2 verdict. If R2 verdict PASS → G3 implementation.
