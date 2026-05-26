# R-DH-P7-01 — Critic R1 (G2, clean-room adversarial)

**Reviewed:** `audit-trail-review/PHASE-7-RITEM-R-DH-P7-01-DESIGN.md` (G1).
**Closes:** L-DH-01 (Working-corpus Class B 0/3 magic-string allowlist gap).
**Mode:** clean-room — reviewed against task spec + filesystem evidence, no executor narrative consulted.
**Date:** 2026-05-26.

---

## §1. Per-criterion verdicts

| # | Blocking criterion | Verdict | Evidence |
|---|--------------------|:-------:|----------|
| 1 | Letter sequence: 13.c placed between 13.b and 13.e; no conflict with R-AT-C-04 reservation | **PASS** | `framework-auditor.md:436-445` (the R-AT-C-04 axis-13.e block) explicitly states *"Axis-13.c is reserved for Wave-2 R-DH-P7-01 source-literal carve-out; axis-13.d is intentionally skipped"* — exactly the slot the design fills. Insert site (after 13.b ends line 434, before 13.e begins line 436) is clean. |
| 2 | Source-grep procedure soundness (pattern set comprehensiveness) | **FAIL — BLOCKING** | See §2.A. The design lists 3 patterns (`[[ X == *L* ]] && exit 0`, `grep -Fq "L"`, `if echo X \| grep -q "L"`); it OMITS `case "$X" in *L*) exit 0 ;;`. W-B3 itself uses `case "$target_path" in */vendor/*\|*\\vendor\\*) exit 0 ;; esac` — the design's own claimed reproduction-target W-B3 would not surface under the procedure as written. Other miss-classes: function-call delegation, env-var equality, `[[ X == "L" ]]` exact-equal (no globs), `[ "$X" = "L" ]` POSIX, `case` with quoted-glob-variable. |
| 3 | Documented-carve-out exemption well-defined; false-positive risk on legitimate carve-outs (e.g., `__APEX_AUDIT_PROBE__:` marker) | **FAIL — BLOCKING** | See §2.B. Exemption gate is `framework/HOOK-CLASSIFICATION.md` OR `apex-spec.md`. `grep -n __APEX_AUDIT_PROBE__ framework/HOOK-CLASSIFICATION.md apex-spec.md` returns **zero hits** in both. The marker IS a legitimate three-factor carve-out (Campaign C TP-C2, anchored at `audit-trail-review/FIX-DESIGN-C-R4.md §2`). Under the procedure as written, an audit of `_audit-probe-marker.sh` (which defines `marker_prefix="__APEX_AUDIT_PROBE__:"` at line 41) OR `security.cjs:280` would emit a false-positive P0. The exemption-anchor set is structurally incomplete. |
| 4 | W-B1/W-B2/W-B3 reproduction (end-to-end trace) | **PARTIAL — BLOCKING** | W-B1 (`grep -Fq -- "--apex-maintenance-token=ok"`): the mutation uses `printf '%s' "$X" \| grep -Fq` — the design's pattern `grep -Fq "<literal>"` raw-grep flavor matches loosely if the scanner greps for `grep -Fq` token then extracts the adjacent literal. **Probably caught.** W-B2 (`grep -Fq -- 'X-Apex-Trust: 1'`): same shape — **probably caught**. W-B3 (`case "$target_path" in */vendor/*) exit 0`): **NOT caught** — design omits `case`. This is the canonical reproduction target the design claims to fix; missing it directly fails L-DH-01 closure intent. |
| 5 | Clause (ix) anchor point: after (vii)+(viii) in round-checker.md | **PASS** | `round-checker.md:222-254` confirms (vii)+(viii) are the last clauses of the "Runtime-invocation-contract probe minimum (R-AT-C-04 / AC-6b)" block; line 254 ends with closing prose before "c. F-204-013 reconstruction check". Inserting (ix) after line 254 (before sub-section c) is clean. |
| 6 | H-F fixtures must satisfy (i)-(viii) to reach (ix) — constraint stated? | **FAIL — BLOCKING** | §2.C of the design specifies *"axis_10 + axis_13.runtime_contract_probes H-E-shaped baseline + axis_13.source_literal_carveouts[] variant"* but does NOT explicitly state the layer-test simulator wires (ix) as the LAST clause-check (matching simulator order). Critically: the simulator at `test-audit-trail-layer.sh:483-639` exits early on the FIRST failed clause. If H-F1 fixture omits `axis_13.source_literal_carveouts[]` AND its axis_10 baseline is incomplete (no boundary variant, no 3 case variants, no silent_failure stderr token), the simulator returns `axis_10_*_blind_spot` BEFORE evaluating (ix). H-F1's expected verdict (`axis_13_source_literal_scan_blind_spot`) is then unreachable. The fixture-shape contract must replicate H-E3's full baseline (see filesystem: `framework/test-fixtures/round-checker-h-e-3.jsonl` — 11 axis_10 entries spanning all 4 mutation classes + 1 axis_13 runtime_contract_probe). Without this, the H-F tests will green incorrectly (wrong verdict matches expected) OR red because the simulator short-circuited. |
| 7 | Adversarial probe — interaction with audit-probe marker | **FAIL** | Already covered in #3. The design's exemption-anchor set (HOOK-CLASSIFICATION.md, apex-spec.md) does NOT contain `__APEX_AUDIT_PROBE__:`. The literal IS documented but in `audit-trail-review/FIX-DESIGN-C-R4.md` and inline-comments at `destructive-guard.sh:27`, `exfil-guard.sh:39`, `security.cjs:262-291`, `_audit-probe-marker.sh:14`. The exemption gate must either (a) widen to include `audit-trail-review/FIX-DESIGN-C*.md` + inline `# Campaign C TP-C2` comment-block detection, or (b) carve out the audit-probe marker explicitly (named exception). Otherwise the first post-fix self-heal round trips a P0 against the framework itself. |

---

## §2. Blocking findings (detailed)

### §2.A — Scan-pattern set incompleteness (criterion #2)

The design's grep pattern list (3 forms) misses at least 5 documented allowlist-shape variants present in `framework/hooks/`:

1. **`case "$X" in *"L"*) exit 0 ;;`** — used by W-B3 mutation (`/vendor/`) AND by 49 occurrences of `case "$..."` across 25 hook files.
2. **Function-call delegation** — `apex_check_audit_probe "$COMMAND"` (carve-out logic hidden in a sourced function; the literal lives in the sourced file, not the calling hook).
3. **`[[ "$X" == "L" ]] && exit 0`** — exact-equal (no glob), distinct from `*"L"*`.
4. **POSIX `[ "$X" = "L" ]`** — same idea, different syntax.
5. **`printf '%s' "$X" | grep -Fq -- "L"`** — the W-B1/W-B2 form. The design lists `grep -Fq "L"` but not the printf-piped or `--` separator forms.

**Required fix:** widen the pattern set to a regex-disjunction enumerated explicitly OR replace the heuristic-grep approach with a *normalized scan*: walk all `case`, `if`, `[[ ]]`, `[ ]`, and pipe-grep expressions that condition `exit 0` / `return 0` on string-literal substrings of any input variable. The set must explicitly include the form W-B3 uses (else the design fails its own reproduction criterion).

### §2.B — False-positive on legitimate audit-probe carve-out (criterion #3, #7)

`grep -n __APEX_AUDIT_PROBE__ framework/HOOK-CLASSIFICATION.md apex-spec.md` returns 0 matches. The marker carve-out is documented in `audit-trail-review/FIX-DESIGN-C-R4.md` (frozen 2026-05-25, Campaign C TP-C2) and inline-commented at `destructive-guard.sh:16-23,27-35`, `exfil-guard.sh:29-44`, `security.cjs:262-291`, `_audit-probe-marker.sh:1-100`. Under the procedure as written, an auditor scanning `_audit-probe-marker.sh` line 41 (`marker_prefix="__APEX_AUDIT_PROBE__:"`) would emit a P0 false-positive because neither anchor doc contains the literal.

**Required fix:** either (a) extend the exemption-anchor set to include `audit-trail-review/FIX-DESIGN-C-R4.md` + an inline-comment-block check (e.g., literal preceded within 5 lines by `# Campaign C TP-C2` or `audit-trail-review/FIX-DESIGN-C`), or (b) add the audit-probe marker as a named carve-out in `framework/HOOK-CLASSIFICATION.md`. Option (a) is broader and more durable; option (b) is mechanically simpler. The design must pick one.

### §2.C — H-F fixture-shape constraint under-specified (criterion #6)

The simulator at `framework/tests/test-audit-trail-layer.sh:483-639` runs clauses (i) → (vi) → (vii) → (viii) → (ix-NEW) in strict order, returning on first failure. For H-F1 to surface `axis_13_source_literal_scan_blind_spot` (not `axis_10_blind_spot` etc.), its fixture MUST already pass (i)-(viii). Concretely: per `H-E3.jsonl` baseline shape, H-F1 needs:

- `axis_10.concrete_bypass_attempts[]` with at least 1 entry per guard in the 4 mutation classes (UNION coverage, clause ii);
- At least 1 boundary variant per regex_word_boundary guard (clause iii);
- At least 3 case variants per case_folding guard (clause iv);
- `stderr_nonempty: true` per silent_failure guard (clause v);
- At least 1 `axis_13.runtime_contract_probes[]` entry for `destructive-guard.sh` (clause vii);
- No discrepant probes without findings cite (clause viii — easiest to satisfy with `argv_exit == stdin_exit`);
- THEN `axis_13.source_literal_carveouts[]` empty/missing for required guards (the H-F1 trigger).

The design says fixtures use *"H-E-shaped baseline"* but does NOT state this fixture-shape contract explicitly, does NOT name which simulator-extension functions need updating, and does NOT specify the simulator-extension append point (which would land between line 637 closing-brace-of-(viii) and line 639 `echo "PASS"`). Without this, executor will likely produce shape-incomplete fixtures and the layer test will hit the wrong verdict.

**Required fix:** add to §2 a "Fixture coherence contract" sub-section stating: (a) the full clause-(i)-(viii) baseline contents required (link H-E3.jsonl as the canonical template); (b) the simulator-extension append point (between line 637 and 639); (c) the new clause-(ix) sim function logic (mirroring the design's clause-ix verdict shape).

---

## §3. Non-blocking suggestions

- §2 Change C "simulator extension" is one line of text. Specify the new sim function's logic in pseudo-code (mirroring how (vii) and (viii) were specified in R-AT-C-04 design) so executor doesn't re-derive it.
- §3 Blast-radius table says `framework/agents/specialist/framework-auditor.md (axis-13.c INSERT) MODIFIED` lines `+~50`. Actual insert is 47 lines per the design quote — within bounds, no change needed; just flag the rough estimate.
- §6 Implementation plan step 1 (axis-13.c insert) and step 2 (clause ix insert) are textually decoupled; consider noting that if step 1 lands without the fix from §2.A above, step 4 closure-note will claim a closure that the procedure doesn't actually deliver.
- The design's `coverage_map.axis_13.source_literal_carveouts[]` recording-shape schema could specify field types (string `guard`, string `literal`, integer `line`, boolean `documented`, array `probe_payloads[]` of strings, array `probe_exits[]` of integers — pair-aligned by index). Round-checker will need to grep on these field names; ambiguity costs implementation time.
- Consider adding to the "minimum scan set" clause: *"… plus any hook that sources `_audit-probe-marker.sh` is automatically exempt from emitting on the `__APEX_AUDIT_PROBE__:` literal even if it would otherwise be undocumented."* This shortcut bypasses the §2.B problem entirely for the framework's own carve-out.

---

## §4. Final verdict

**FAIL — three BLOCKING issues require G1 revision before G3 implementation.**

Concrete reasoning:

1. **Criterion #2 + #4 (W-B3 not caught)**: the design's own closure target — W-B3 (`/vendor/` magic-string carve-out, the W-B3 row in `WORKING-CORPUS.md:181-202`) — would NOT be surfaced by the scan procedure as written, because W-B3 uses `case "$target_path" in */vendor/*) exit 0` and the design's grep-pattern list omits `case` statements. The L-DH-01 closure target is structurally missed.

2. **Criterion #3 + #7 (audit-probe false-positive)**: the documented-carve-out exemption gate as defined would trigger a P0 false-positive on the framework's own legitimate `__APEX_AUDIT_PROBE__:` carve-out at first post-fix self-heal round, because neither named anchor doc (`framework/HOOK-CLASSIFICATION.md`, `apex-spec.md`) contains the marker literal.

3. **Criterion #6 (fixture shape under-specified)**: H-F fixtures will not satisfy clauses (i)-(viii) baseline unless explicitly constrained to mirror `round-checker-h-e-3.jsonl` shape; without explicit constraint, the layer tests will green-pass or red-fail on the wrong verdict.

PASS items: letter-sequence slot (criterion #1), round-checker anchor point (criterion #5), and partial W-B1/W-B2 reproduction-coverage (criterion #4 partial).

Recommended G1 revision (R2): tighten §2 Change A scan-pattern set to include `case`/POSIX-`[`/exact-equal/printf-pipe forms; widen the documented-carve-out exemption to cover `__APEX_AUDIT_PROBE__:` (option a or b in §2.B); add a "Fixture coherence contract" subsection per §2.C with the simulator-extension append-point logic.

**Next gate:** Re-issue G1 → re-run G2 critic on the revised design.
