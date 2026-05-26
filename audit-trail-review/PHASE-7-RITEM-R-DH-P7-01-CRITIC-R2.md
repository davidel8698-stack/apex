# R-DH-P7-01 — Critic R2 (G2, clean-room adversarial)

**Reviewed:** `audit-trail-review/PHASE-7-RITEM-R-DH-P7-01-DESIGN-R2.md` (G1 R2).
**Closes:** R1 BF-1 (scan-pattern coverage), BF-2 (audit-probe-marker
exemption), BF-3 (fixture coherence + simulator append).
**Mode:** clean-room — reviewed against task spec + filesystem
evidence, no executor narrative consulted.
**Date:** 2026-05-26.

---

## §1. R1 BF closure verdicts

| BF | R1 issue | R2 claim | R2 verdict | Evidence |
|----|----------|----------|:----------:|----------|
| **BF-1** | Scan misses `case`/POSIX/exact-equal/printf-pipe; W-B3 not surfaced | §2.A widened to 7 pattern families incl. case (#4), POSIX `[ = ]` (#3), printf-pipe-grep (#5), function-call delegation (#7) | **CLOSED** | See §2.A walkthrough below — pattern family #4 catches W-B3 case-form directly; #5 catches W-B1/W-B2 printf-pipe form; #7 covers indirection via sourced helpers. |
| **BF-2** | Exemption set missed `__APEX_AUDIT_PROBE__:` — would emit P0 against framework's own hooks | §2.A exemption set expanded to 5 sources: HOOK-CLASSIFICATION.md, apex-spec.md, FIX-DESIGN-C-R4.md, security-patterns.json, inline-comment-block detection | **CLOSED** | See §2.B verification below — `__APEX_AUDIT_PROBE__:` is matched by sources #3 (FIX-DESIGN-C-R4.md line 124 + 163) AND #4 (security-patterns.json line 9 `audit_probe_marker.literal`). Two independent exemption anchors → safe. |
| **BF-3** | Fixture-shape contract under-specified; simulator append point absent | §2.C explicit Fixture Coherence Contract + simulator-extension append-point pseudo-code | **CLOSED with one non-blocking observation** | See §2.C — append point verified (lines 637-639), pseudo-code is logically complete (both blind-spot and unreported branches present). Minor coverage-narrowing concern in `regex_deny_guards` subset noted in §3. |

---

## §2. Detailed verification

### §2.A — BF-1 closure: W-B3 walkthrough

W-B3 mutation per `WORKING-CORPUS.md:181-202`:

```bash
case "$target_path" in
  */vendor/*|*\\vendor\\*) exit 0 ;;
esac
```

Trace through R2 §2.A pattern families:
- Family #4 (`case "$X" in *"<literal>"*) exit 0 ;; esac`) matches the
  W-B3 form literally. The scanner extracts the literal substring
  (`vendor` or `/vendor/`) from the glob match arm.
- Exemption check: `vendor` is NOT in HOOK-CLASSIFICATION.md, NOT in
  apex-spec.md, NOT in FIX-DESIGN-C-R4.md, NOT in
  security-patterns.json, NOT preceded by an exempt-comment-block →
  emit P0 finding with cite `owner-guard.sh:<line>` + literal
  `vendor`. ✅

Similarly W-B1 (`printf '%s' "$COMMAND" | grep -Fq -- '--apex-maintenance-token=ok'`)
matches family #5 explicitly ("in any pipe direction including
printf-pipe"); literal extracted is
`--apex-maintenance-token=ok`; exemption check is clean → emit P0.

W-B2 (`printf '%s' "$COMMAND" | grep -Fq -- 'X-Apex-Trust: 1'`)
matches family #5 identically.

All three working-corpus Class-B targets are now structurally
caught. **BF-1 CLOSED.**

### §2.B — BF-2 closure: `__APEX_AUDIT_PROBE__:` exemption verification

Filesystem evidence (current commit):

| Exemption source | Contains `__APEX_AUDIT_PROBE__:`? | Lines |
|------------------|:---:|-------|
| #1 `framework/HOOK-CLASSIFICATION.md` | (unverified — not checked in R2 text) | — |
| #2 `apex-spec.md` | (unverified — not checked in R2 text) | — |
| #3 `audit-trail-review/FIX-DESIGN-C-R4.md` | **YES** | line 124 (`Edge case: cmd = "__APEX_AUDIT_PROBE__:abc123"`), line 163 (probe payload example) |
| #4 `framework/test-fixtures/security-patterns.json` | **YES** | line 9 `"literal": "__APEX_AUDIT_PROBE__:"` under `audit_probe_marker` |
| #5 inline-comment-block (5-line window) | partial | see below |

For the inline-comment-block variant: in
`framework/hooks/_audit-probe-marker.sh` at line 41 (the actual
`marker_prefix=` assignment), the 5 lines above (36–40) contain
only function-body code, no comment matching the exemption regex
`# Campaign [A-C] TP-`, `# IMP-\d+`, `# spec anchor`,
`# audit-probe`, `# Mythos §`. So source #5 alone would NOT exempt
line 41. However sources #3 AND #4 DO contain the literal text →
literal is exempt via TWO independent anchors. The R2 design's
exemption check is `OR` across the 5 sources, so one match is
sufficient.

For `framework/hooks/security.cjs:280` (`const markerPrefix = '__APEX_AUDIT_PROBE__:';`):
sources #3 and #4 again catch the literal. Same outcome.

Additionally, source #4's `security-patterns.json` line 10 has the
explicit comment `Campaign C TP-C2 — three-factor audit-probe
carve-out. Spec anchor: audit-trail-review/FIX-DESIGN-C-R4.md §2`
inside the JSON value, reinforcing the exemption surface.

**BF-2 CLOSED.** Even if R2's source #5 inline-comment regex
doesn't fire on `_audit-probe-marker.sh:41` (no `Campaign C TP-` in
the 5 lines above), sources #3 and #4 are sufficient on their own.

### §2.C — BF-3 closure: simulator pseudo-code + append point

Append-point claim (R2 §2.C): "between the closing brace of clause
(viii)'s discrepant_guards loop (line ~637 of
test-audit-trail-layer.sh) AND the final `echo \"PASS\"` (line ~639)."

Filesystem verification: `test-audit-trail-layer.sh:637` ends the
`done <<< "$discrepant_guards"` block of clause (viii); line 638 is
blank; line 639 is `echo "PASS"`. Append point is correct. ✅

Pseudo-code logic check:
- **Phase 1 (blind-spot branch).** For each guard in
  `regex_deny_guards`, query `axis_13.source_literal_carveouts[]`
  for an entry with matching `guard`. If none → emit
  `axis_13_source_literal_scan_blind_spot`. **Implements
  clause-(ix) blind-spot branch.** ✅
- **Phase 2 (unreported-bypass branch).** Collect guards where any
  entry has `exempt_via == "undocumented"` AND any
  `probe_exits[]` element is 0 (exit-0 bypass). For each such
  guard, check `.findings[].cite[]` for the guard name. If no
  finding cites it → emit `axis_13_source_literal_bypass_unreported`.
  **Implements clause-(ix) unreported-bypass branch.** ✅

H-F1/H-F2/H-F3 verdicts trace through pseudo-code correctly:
- H-F1 (empty carveouts) → phase 1 fires → `…_blind_spot`. ✓
- H-F2 (one entry, undocumented, exit-0, no finding) → phase 1
  passes (entry present) → phase 2 fires → `…_bypass_unreported`. ✓
- H-F3 (clean entries) → phase 1 passes → phase 2 finds no
  qualifying guard → falls through to `echo "PASS"`. ✓

Fixture Coherence Contract subsection (§2.C top) explicitly lists
the 11-entry H-E-3 axis_10 baseline + 1 axis_13.runtime_contract_probes
entry. Cross-checked against
`framework/test-fixtures/round-checker-h-e-3.jsonl` — listed
contents match the fixture exactly (path-guard 2, prompt-guard 6,
_state-update.sh with jq stderr, session-log.sh stderr,
test-runner-counter, destructive-guard non-discrepant). **BF-3
CLOSED.**

---

## §3. New blocking findings introduced by R2

**None blocking.** Two non-blocking observations:

1. **Simulator's `regex_deny_guards` narrowed subset.** The
   pseudo-code hardcodes `regex_deny_guards="destructive-guard.sh
   path-guard.sh"`. This omits `exfil-guard.sh` (W-B2 target) and
   `owner-guard.sh` (W-B3 target). The R2 text explicitly frames
   this as a "Settings-wired regex-deny subset for layer-test
   purposes" so it is by-design layer-test narrowing — the
   production scan in axis-13.c (Change A) still requires the full
   minimum scan set (every regex-deny / pattern-deny guard in the
   extracted_set). The layer test will not catch a regression
   where exfil-guard or owner-guard skip the scan; that is the
   broader integration test's responsibility. Non-blocking — but
   worth noting in §6 implementation plan so future maintainers
   understand the layer-test simulator deliberately tests less
   than the production procedure.

2. **Function-call delegation depth (pattern family #7).** R2 says
   "the called function definition is searched recursively for
   patterns 1-6". Recursion depth is unbounded. In practice
   single-level recursion (one source/import hop) is sufficient
   for the current corpus (`apex_check_audit_probe` lives in
   `_audit-probe-marker.sh`), but unbounded recursion could
   theoretically loop on mutually-recursive helpers. Recommend
   capping at recursion depth 2 in the executor's implementation
   note — non-blocking.

3. **`exempt_via` resolution ambiguity (minor).** When a literal
   matches multiple exemption sources (e.g.,
   `__APEX_AUDIT_PROBE__:` matches both #3 and #4), R2 does not
   specify which source name is recorded in `exempt_via`. Suggest
   "first match in source order" — non-blocking.

---

## §4. Per-criterion table (carried forward from R1, R2-updated)

| # | Blocking criterion | R1 verdict | R2 verdict | Evidence |
|---|--------------------|:----------:|:----------:|----------|
| 1 | Letter sequence (axis-13.c slot) | PASS | PASS | Unchanged from R1 §1. |
| 2 | Scan-pattern set comprehensiveness | FAIL | **PASS** | §2.A — 7 families catch W-B3 (case), W-B1/W-B2 (printf-pipe-grep), plus POSIX/exact-equal/function-delegation. |
| 3 | Documented-carve-out exemption coverage | FAIL | **PASS** | §2.B — sources #3 (FIX-DESIGN-C-R4.md) + #4 (security-patterns.json) both contain `__APEX_AUDIT_PROBE__:` literal. |
| 4 | W-B1/W-B2/W-B3 reproduction | PARTIAL | **PASS** | §2.A walkthrough — all three Class-B working-corpus cases now structurally surfaced. |
| 5 | Clause (ix) anchor in round-checker.md | PASS | PASS | Unchanged from R1 §1 (Change B unchanged in R2). |
| 6 | H-F fixture-shape constraint | FAIL | **PASS** | §2.C — Fixture Coherence Contract subsection + 11-entry baseline matches H-E-3.jsonl + simulator append point verified at lines 637-639. |
| 7 | Adversarial probe — audit-probe interaction | FAIL | **PASS** | Same as #3; sources #3+#4 close it. |

---

## §5. Verdict

**PASS-WITH-NOTES** (PASS-equivalent — all 3 R1 BFs CLOSED, zero
new blocking findings, three non-blocking observations recorded in
§3 for the executor's implementation note).

All seven blocking criteria from R1 now resolve to PASS. The
design is implementable as written; G3 may proceed.

**Confidence:** 7/7 criteria verified | 0 unverified | 0 missing.

**Next gate:** G3 implementation against R2 design (with executor
implementation note covering the three §3 non-blocking observations).
