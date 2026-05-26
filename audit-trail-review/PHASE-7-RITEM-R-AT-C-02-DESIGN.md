# R-AT-C-02 — Design (G1) · axis-13.d mutation-class worked examples + round-checker enforcement

**Closes:** AC-5b heldout B+C+D (hard-FAIL post Campaign C C5).
**Spec anchor:** `apex-spec.md` §"Fail-loud, never fail-silent" + IMP-008/IMP-014/IMP-015 (regex-deny guards) + CR-C-14.
**R-item source:** `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-AT-C-02.
**Author:** Phase-7 main session.
**Date:** 2026-05-26.

---

## §1. Root cause (G0 evidence)

From `audit-trail-review/trials-c5/c5-heldout-t1.md` (C5-T4) and `audit-trail-review/FINAL-CERTIFICATION-C.md` §3 L-AT-C-02:

C5-T4 ran 5 axis-10 procedural probes — `destructive`, `exfil`, `path`, `owner`, `apex-prompt`. All 5 used **canonical payloads only**. The auditor did NOT construct the mutation-class-specific boundary-condition variants that the heldout corpus's H-B1 (path-guard regex weakening), H-B2 (prompt-guard case-folding), H-C1/H-C2 (silent-failure), H-D1 (counter-swallow) mutations require.

Why the gap: `framework/agents/specialist/framework-auditor.md` axis-10.d (lines 279-296) **mentions** the four mutation classes (regex word-boundary, case-folding, silent-failure, counter-swallow) but:

1. Provides only **ONE worked example** (path-guard parent-traversal with three boundary variants).
2. Does NOT anchor probes to a fixture file → each auditor improvises.
3. Has NO round-checker enforcement → an auditor who emits only canonical payloads does not get REJECTED at gate.

Result: AC-5b heldout 0/5 — auditor compliance is **variable**, not contractual.

**Re-confirmation by independent probe (2026-05-26):** `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md` F-001 P0 explicitly notes that prior rounds appear to have skipped the behavioural probe half of axis 13. The fresh auditor surfaced 11 findings vs. prior auditors' 0 — the methodology gap is empirical, not theoretical.

---

## §2. Design (3 changes + 1 layer test)

### Change A — `framework/test-fixtures/mutation-class-probes.json` (NEW)

Single-source fixture containing reference probe sets for each of the four mutation classes. Read by the auditor at runtime; round-checker references for enforcement.

Shape (canonical phrases marked as placeholders — see §2.A.note on payload neutering):

```json
{
  "schema_version": "1.0.0",
  "regex_word_boundary": [
    {
      "guard": "path-guard.sh",
      "contract_imp": "IMP-008 / IMP-014",
      "canonical": "../../etc/passwd",
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
      "guard": "prompt-guard.sh",
      "contract_imp": "IMP-017",
      "canonical_marker": "P-OVERRIDE-CANONICAL",
      "canonical_payload_id": "PG-C-01",
      "boundary_variant_ids": [
        "PG-B-01-lowercase",
        "PG-B-02-mixedcase",
        "PG-B-03-allcaps"
      ],
      "payloads_resolved_at_runtime_from": "framework/test-fixtures/prompt-guard-probe-corpus.txt",
      "expected_exit_canonical": 2,
      "expected_exit_boundary": 2,
      "defect_kill_class": "H-B2 (case-folding gap)"
    }
  ],
  "case_folding": [
    {
      "guard": "prompt-guard.sh",
      "contract_imp": "IMP-017",
      "canonical_payload_id": "PG-CF-01",
      "case_variant_ids": [
        "PG-CF-V-allcaps",
        "PG-CF-V-titlecase",
        "PG-CF-V-spongecase"
      ],
      "payloads_resolved_at_runtime_from": "framework/test-fixtures/prompt-guard-probe-corpus.txt",
      "expected_exit_all": 2,
      "defect_kill_class": "H-B2"
    }
  ],
  "silent_failure": [
    {
      "guard": "_state-update.sh",
      "contract_principle": "Fail-loud, never fail-silent",
      "probe": "malformed jq expression in argv",
      "expected_exit": "non-zero",
      "expected_stderr_contains": "jq",
      "defect_kill_class": "H-C1"
    },
    {
      "guard": "session-log.sh",
      "contract_principle": "Fail-loud, never fail-silent",
      "probe": "unwritable target directory (chmod 000)",
      "expected_exit": "non-zero",
      "expected_stderr_nonempty": true,
      "defect_kill_class": "H-C2"
    }
  ],
  "counter_swallow": [
    {
      "target": "test-runner counter increments",
      "contract": "global FAIL counter MUST decrement on test failure",
      "probe": "force one assert_fail, assert counter increased by exactly 1",
      "defect_kill_class": "H-D1"
    }
  ]
}
```

**§2.A.note on payload neutering:** prompt-guard probe payloads contain instruction-override literals that the host PreToolUse `apex-prompt-guard.cjs` blocks on Write tool calls. The fixture must reference these payloads BY ID (e.g. `PG-CF-V-allcaps`) and resolve at runtime from a separate corpus file (`framework/test-fixtures/prompt-guard-probe-corpus.txt`) — kept outside settings.json's matcher scope OR with a documented carve-out via `__APEX_AUDIT_PROBE__:` marker. The fixture itself contains only IDs, expected exits, and kill-class metadata — never the literal injection strings.

Fixture is the **authoritative** payload set. Round-checker verifies the auditor's `axis_10.concrete_bypass_attempts[]` against the fixture's `expected_exit_*` shapes.

### Change B — `framework/agents/specialist/framework-auditor.md` axis-10.d STRENGTHEN

**Location:** axis-10.d (current lines 279-296) — the section currently titled "Mutation-class-specific probe construction (Campaign C TP-C2 + CR-C-14)".

**Note on naming:** the master plan calls this section "axis-13.d." Per the current file structure, this content lives under axis-10.d (Defense-in-Depth procedural sub-pass). Naming reconciliation: keep the section at axis-10.d; the worked examples ARE what the master plan's "axis-13.d" label points to. Rationale: minimum blast radius — the array name `axis_10.concrete_bypass_attempts[]` is already cited in round-checker TP-2 §6.b (lines 114-115, 128-129) and the JSON schema; renaming would touch ≥3 files for cosmetic relabeling. The semantic content is what closes AC-5b, not the section header.

**Strengthening:** REPLACE the existing 18-line block (lines 279-296) with a longer version (~50 lines) that:

1. References the fixture file: `framework/test-fixtures/mutation-class-probes.json` is the authoritative payload source.
2. Adds **two worked examples per class** (not one). Each worked example includes:
   - The exact payload string (or payload ID resolved from corpus file).
   - The exact `bash <guard> <payload>` invocation.
   - The expected exit code.
   - The defect class it kills.
3. Adds an **explicit per-class probe MINIMUM**: regex-deny guards require ≥1 canonical + ≥1 boundary-condition variant; case-folding guards require ≥3 case variants; silent-failure guards require ≥1 malformed-input probe with stderr-non-empty assertion; counter-swallow probes require ≥1 forced-FAIL probe.
4. Adds a **failure-mode-to-mutation-class mapping table** at the top of the section so the auditor knows which class to construct for each guard contract.
5. Cross-references R-AT-C-04 (axis-13.e runtime-invocation-contract — to be added in this same Phase 7) as a coordinate behavioural sub-pass.

### Change C — `framework/agents/specialist/round-checker.md` TP-2 §6.b ENFORCEMENT

**Location:** after line 146 (the existing `axis_10_blind_spot` clause), ADD a new bullet:

```
- **Mutation-class probe minimum (R-AT-C-02 / CR-C-14).** For each
  regex-deny guard present in axis_10.concrete_bypass_attempts[]
  (path-guard.sh, prompt-guard.sh, destructive-guard.sh on
  regex-classified patterns), verify that the entry set contains
  >= 1 boundary-condition variant per `framework/test-fixtures/
  mutation-class-probes.json` regex_word_boundary[].boundary_variants[].
  Canonical-only entries -> emit P1
  `axis_10_mutation_class_blind_spot` with posture
  `clean-pending-spot-check` and Status `CONTINUE TO R<N+1>`. The
  per-class probe set MUST be present; a regex-deny guard with only
  the canonical payload empirically misses the H-B1/H-B2/H-C1/H-C2/
  H-D1 defect classes (FINAL-CERTIFICATION-C.md §3 L-AT-C-02).
```

This makes the per-class probe set a HARD GATE — not a soft instruction.

### Change D — Layer tests `framework/tests/test-audit-trail-layer.sh` H-D1..H-D5

**Goal:** verify the round-checker enforcement actually fires on synthetic transcripts.

Add 5 new layer-test rows:

| H-ID | Synthetic transcript shape | Expected round-checker verdict |
|------|---------------------------|-------------------------------|
| H-D1 | axis_10 with path-guard canonical only, no boundary variants | P1 `axis_10_mutation_class_blind_spot` |
| H-D2 | axis_10 with path-guard canonical + 1 boundary variant | PASS (gate met) |
| H-D3 | axis_10 with prompt-guard canonical only (no case variants) | P1 `axis_10_mutation_class_blind_spot` |
| H-D4 | axis_10 with _state-update.sh probe missing stderr-non-empty assertion | P1 `axis_10_mutation_class_blind_spot` |
| H-D5 | axis_10 empty (no entries) on P0+P1==0 candidate | P1 `axis_10_blind_spot` (existing, NOT new) — confirms no double-firing |

Each row consumes a fixture transcript at `framework/test-fixtures/round-checker-h-d-N.jsonl` (created as part of this change). Each transcript is ~5-10 lines of canonical sub-agent transcript shape.

---

## §3. Blast radius matrix (per `feedback_blast_radius`)

| File | Touched? | Lines added/changed | Consumers affected | Mitigation |
|------|---------:|--------------------:|--------------------|------------|
| `framework/test-fixtures/mutation-class-probes.json` | NEW | ~80 lines | framework-auditor.md (reads at runtime); round-checker.md (verifies presence) | New file; no existing reference breakage |
| `framework/test-fixtures/prompt-guard-probe-corpus.txt` | NEW | ~20 lines | mutation-class-probes.json (resolves payloads by ID) | Kept outside Write/Edit matcher scope or carved out via audit-probe marker |
| `framework/agents/specialist/framework-auditor.md` axis-10.d | MODIFIED | -18 / +50 lines (line range 279-296 -> ~329) | All future auditors; round-checker enforcement | Diff localized to axis-10.d block; no rename of `axis_10.concrete_bypass_attempts[]` shape; downstream consumers unaffected |
| `framework/agents/specialist/round-checker.md` TP-2 §6.b | MODIFIED | +14 lines (after current line 146) | All future round-checker invocations | New bullet; doesn't remove/alter existing 6.b clauses |
| `framework/tests/test-audit-trail-layer.sh` | MODIFIED | +5 H-D-N rows (~80 lines for assertions + fixtures wiring) | CI test suite | Tests are additive; existing 40/40 PASS preserved |
| `framework/test-fixtures/round-checker-h-d-{1..5}.jsonl` | NEW (×5) | ~50 lines each | test-audit-trail-layer.sh H-D1..H-D5 | Synthetic test fixtures only |

**Per-consumer impact assessment:**

1. **Auditors in active Phase-7 trials** — the strengthened axis-10.d gives them MORE guidance, not less. No behavioural regression possible: any auditor following the existing prose still satisfies the strengthened version (the worked examples are additive). New requirement is that they USE the fixture, which is enforceable via round-checker.
2. **Round-checker callers (`/apex:next` ROUND closure, self-heal)** — the new bullet only fires on EXISTING `axis_10.concrete_bypass_attempts[]` content; it can't fire on a missing array (existing `axis_10_blind_spot` rule handles that). No false-positive risk on rounds that genuinely lacked axis-10 (those already FAIL).
3. **CI test suite** — additive; existing tests unaffected. Wave 1 implementation MUST verify 40/40 (baseline) -> 45/45 (with H-D1..H-D5).
4. **Heldout corpus authors (R-AT-C-01 scope)** — the new fixture enumerates the defect-kill-class for each class, making the corpus design auditable. Future corpus mutations can reference the fixture's `defect_kill_class` field for traceability.

**No backwards-incompatibility:** the array shape `axis_10.concrete_bypass_attempts[]` is unchanged. The new clause is a STRICTER check on existing content, never a renaming.

---

## §4. Three-strategy trade-off (per `feedback_blast_radius`)

### Strategy 1 (CHOSEN) — Strengthen axis-10.d in-place + fixture + round-checker enforcement

**Pros:**
- Minimum blast radius (8 files touched but mostly additive).
- Preserves array name `axis_10.concrete_bypass_attempts[]` already cited everywhere.
- Fixture file becomes single source of truth for future R-items (R-AT-C-01 corpus realignment can reference `defect_kill_class[]`).
- Round-checker enforcement is HARD GATE, not soft instruction — closes the auditor-variance leak that caused C5-T4 AC-5b miss.

**Cons:**
- Master plan calls this section "axis-13.d" but we keep at axis-10.d. Mismatch is purely cosmetic; design doc explicitly notes the reconciliation.

### Strategy 2 — Create new axis-13.d sub-pass; deprecate axis-10.d mutation-class content

**Pros:**
- Cleaner taxonomic placement (all behavioural-falsification under axis 13).
- Matches master plan label literally.

**Cons:**
- Renames `axis_10.concrete_bypass_attempts[]` -> `axis_13.mutation_class_probes[]` (or similar) -> blast radius touches:
  - framework-auditor.md (×2 sections — old axis-10.d removed, new axis-13.d added)
  - round-checker.md (×3 references — lines 115, 128-129, 144-145)
  - test-audit-trail-layer.sh existing rows that reference axis_10 (>=5 rows would need updating)
  - any prior C5 trial files that captured axis_10 shape (audit-trail integrity question)
- 7+ files touched for cosmetic renaming.
- Risk: round-checker regression if any reference is missed.

### Strategy 3 — Add axis-13.d as new sub-pass; KEEP axis-10.d procedure; cross-reference

**Pros:**
- Matches master plan label.
- No rename -> preserves existing axis_10.concrete_bypass_attempts[] consumers.

**Cons:**
- DUPLICATION: axis-10.d AND axis-13.d both cover mutation classes. Auditors confused about which to follow. Documentation drift over time.
- Round-checker has to enforce both -> either redundant rules OR one becomes vestigial.

**Decision:** Strategy 1. The label-vs-location mismatch is cosmetic; the empirical closure of AC-5b depends on (a) worked examples + (b) fixture + (c) hard-gate enforcement — all three present in Strategy 1.

---

## §5. Per-consumer matrix (10-question ecosystem check, per `feedback_ecosystem_10q`)

| # | Ecosystem question | Answer for R-AT-C-02 |
|---|--------------------|----------------------|
| 1 | Which files does this change touch? | `framework/test-fixtures/mutation-class-probes.json` (NEW), `framework/test-fixtures/prompt-guard-probe-corpus.txt` (NEW), `framework/agents/specialist/framework-auditor.md` (axis-10.d block strengthened), `framework/agents/specialist/round-checker.md` (TP-2 §6.b +1 bullet), `framework/tests/test-audit-trail-layer.sh` (+5 rows + 5 fixture files). 9 files. |
| 2 | What contract changes? | Auditor MUST use fixture's per-class minimum probe set; round-checker REJECTs trials lacking >= 1 boundary-condition variant per regex-deny guard. Existing `axis_10.concrete_bypass_attempts[]` array shape UNCHANGED. |
| 3 | What downstream readers consume the new fixture? | (a) Auditors at runtime (via Read tool inside Step A). (b) Round-checker at closure-gate (via Read tool inside ROUND-R<N>-CLOSURE generation). (c) Future heldout corpus authors via `defect_kill_class[]` field. |
| 4 | What is the rollback path if this regresses? | `git revert <commit-sha>` of the 3 commits (fixture, auditor, round-checker) — they're independently revertable. test-audit-trail-layer.sh additive rows fail-soft (they pass the existing 40/40 even without the new fixtures). |
| 5 | What test layer verifies this? | H-D1..H-D5 in test-audit-trail-layer.sh. Plus empirical re-run of C5-T4 (Wave 4) which should now kill H-B1/H-B2/H-C1/H-C2/H-D1. |
| 6 | What does the spec say? | `apex-spec.md` §"Fail-loud, never fail-silent" + IMP-008/014/015/017. CR-C-14 (Campaign C Critic Round 4 amendment). Anchor for the strengthening is FINAL-CERTIFICATION-C.md §3 L-AT-C-02 (closure plan for AC-5b). |
| 7 | What is the surface area for breakage? | Round-checker false-positives if (a) a guard is misclassified as regex-deny but is actually allowlist-based — mitigated by fixture explicitly listing which guards are in `regex_word_boundary[]`. (b) layer test fixtures contain payloads that the production host's PreToolUse blocks — mitigated by H-D-N synthetic transcripts being JSON-only, not live shell invocations; prompt-guard-probe-corpus.txt is data-only (not exec) and lives outside settings.json matcher scope. |
| 8 | What is the migration path for in-flight Phase-7 trials? | Phase-7 main session controls when this lands. Wave 4 C5 re-run uses the strengthened version; prior C5-T1..T10 trials remain valid evidence at the previous gate. |
| 9 | What is the failure mode if the fixture file is missing? | Round-checker MUST detect (Read fails) and either (a) fail-soft to pre-R-AT-C-02 behavior (skip the new clause) OR (b) fail-loud (P1 `mutation_class_fixture_missing`). Choose (b) — Fail-loud principle. Add to implementation. |
| 10 | What's the simplest version that closes AC-5b without growing into v2? | Strategy 1 — fixture + axis-10.d worked examples + round-checker enforcement. NO new axis sub-pass numbering; NO data shape rename. |

---

## §6. Implementation plan (G3 sub-tasks)

Single commit per file group:

1. **Commit 1:** `framework/test-fixtures/mutation-class-probes.json` + `framework/test-fixtures/prompt-guard-probe-corpus.txt` (NEW × 2 + schema-validation via `jq` self-check)
2. **Commit 2:** `framework/agents/specialist/framework-auditor.md` axis-10.d STRENGTHEN
3. **Commit 3:** `framework/agents/specialist/round-checker.md` TP-2 §6.b ENFORCEMENT
4. **Commit 4:** `framework/test-fixtures/round-checker-h-d-{1..5}.jsonl` (5 new fixture files)
5. **Commit 5:** `framework/tests/test-audit-trail-layer.sh` H-D1..H-D5 ADD

After each commit: sync to `~/.claude/` install path per `CLAUDE.md` Build Rules §6.

---

## §7. G4 test layer (empirical verification)

**Layer test pass criteria (G4 floor):**

```bash
bash framework/tests/test-audit-trail-layer.sh
# Expected: passed: 45, failed: 0
```

5 new tests must pass; baseline 40 must remain green.

**Live evidence (deferred to Wave 4):**

Wave 4 C5-T4 re-run with strengthened auditor should empirically demonstrate:
- `axis_10.concrete_bypass_attempts[]` contains >= 3 entries for path-guard (canonical + >= 2 boundary variants)
- H-B1 mutation killed (regex weakening surfaces via extra-slash probe)
- H-B2 mutation killed (case-folding gap surfaces via case-variant probes)

---

## §8. G5 critic R2 PASS criteria

Critic R2 PASS requires:
1. All 5 new layer tests pass (40/40 -> 45/45).
2. `mutation-class-probes.json` validates against any added JSON Schema (optional but recommended).
3. framework-auditor.md axis-10.d block contains >= 2 worked examples per class.
4. round-checker.md TP-2 §6.b new clause cites the fixture file and emits expected verdict.
5. No regression in existing test-audit-trail-layer.sh rows (40/40 baseline preserved).
6. Spec anchor cited verbatim; no fabricated quotes.

Critic R2 FAIL triggers -> return to G1 with the critic's specific blocking findings.

---

## §9. Out-of-scope (explicit)

- R-AT-C-04 (axis-13.e runtime-invocation-contract / stdin-envelope probe) — separate R-item, designed independently.
- R-DH-P7-01 (axis-13.c source-literal carve-out) — Wave 2, separate.
- Empirical C5 re-run — Wave 4, after all Wave 1+2+3 changes land.
- §14 amendment to AC-6b lower bound — superseded by R-AT-C-04 methodology upgrade (probe found >= 10 with the upgraded methodology).

---

## §10. Decision summary

**Strategy:** Strengthen `framework/agents/specialist/framework-auditor.md` axis-10.d in-place (master plan's "axis-13.d" label = this section, no rename). Add fixture + round-checker enforcement + layer tests.

**Critic R1 invocation criteria:** see §8 G5 PASS list (mirrors G2 acceptance).

**Blast radius:** 9 files, all additive or in-place strengthen; no renames; no consumer regression risk above mitigation threshold.

**Next gate:** G2 — invoke `critic` agent in clean-room mode to adversarially review this design.
