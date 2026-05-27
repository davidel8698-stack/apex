# R-P8-A G5 CRITIC R2 — closure adversarial review

## Overall verdict: PASS

R2 design + implementation closes all 5 BLOCKING items from CRITIC-R1.
Live execution evidence: `test-audit-trail-layer.sh` standalone → 65/65
passed (delta +10 vs pre-R-P8-A baseline of 55), exit 0. `bash -n`
clean. Multi-field `_raw` pattern verified by manual probe →
`Bash`/`ls`. Three representative pre-existing test suites
(test-fix-plan-emit, test-hooks-security, test-hooks-blocking) all
PASS (37/37, 18/18, 12/13 — pre-existing skip count unchanged).
Blast radius confirmed pure-additive: only `_hook-input.sh` (new
untracked) + `test-audit-trail-layer.sh` (the H-G insertion block) in
the working tree.

---

## Per-criterion findings (1-13)

### Closure of R1 BLOCKINGs

**1. BLOCKING-1 (subshell cache hazard) — CLOSED via design pivot.**
Implementation does NOT use either source-time or module-scope-cache
patterns. It uses **lazy-inside-function** (lines 70-130 of
`_hook-input.sh`) — each extractor consumes stdin via `cat` once per
call. The hazard is acknowledged at lines 38-50 of the helper header
and the design explicitly redirects multi-field consumers to the
`apex_hook_input_raw` pattern (one stdin consumption, then in-process
jq). H-G8 row in `test-audit-trail-layer.sh:789-798` PROVES the
documented multi-field pattern works: payload
`{"tool_name":"Bash","tool_input":{"command":"ls"}}` → `Bash:ls`. Manual
re-probe with the prompt's exact command line returns `Bash` + `ls`
(2 lines). NOTE: the R2 design document at §"Critical design correction"
prescribes source-time read, but the implementation instead chose the
lazy-inside-function variant with explicit `apex_hook_input_raw`
escape hatch. The lazy approach is documented inline in the helper
header (lines 38-50) with a clear constraint statement; functionally
equivalent for the documented `_raw`-then-local-jq use pattern. Not a
regression — both designs converge on the same multi-field user
experience via H-G8.

**2. BLOCKING-2 (`[ ! -t 0 ]` + cat semantics) — CLOSED.** Helper
header lines 38-42 document the lazy-read rationale ("source-time read
would block in CI environments where stdin is inherited from a
non-TTY non-EOF parent process"). `[ ! -t 0 ]` semantics are explicit
in the R2 design §"`[ ! -t 0 ]` semantics" with no-deadlock
guarantee. H-G2 standalone test (exit 0, no output) proves
no-deadlock empirically. H-G4 (empty stdin) PASS proves
`cat </dev/null` returns immediately.

**3. BLOCKING-3 (count error 9→27) — CLOSED.** Helper header lines
31-33 state "27 argv-style test invocations across
test-fix-plan-emit.sh + test-hooks-security.sh + test-hooks-blocking.sh
covering 9 distinct hooks." Design R2 §"G2-R1 BLOCKING resolution
map" row 3 confirms the correction.

**4. BLOCKING-4 (H-G rows undefined) — CLOSED.** R2 design §"G4-R2 —
Layer tests" defines 10 rows (H-G0..H-G9) with mechanism + expected
columns. Test file lines 723-808 implements all 10 rows with explicit
assertion checks (`if [ ... ] = ... ]; then ok ... else nope ...`).
Live run: 10/10 PASS.

**5. BLOCKING-5 (missing rows) — CLOSED.** H-G2 (standalone no-op),
H-G8 (multi-field `_raw` pattern — the canonical subshell-capture
fix), H-G7 (argv-priority when both present), and H-G6 (stdin-only
path) all present and PASS. Note: R2 design table called H-G9 the
"double-source reentrance" row, but implementation uses H-G9 for
filepath extraction. Reentrance is implicitly safe under the lazy
pattern (no module-scope cache to corrupt; functions are idempotently
re-defined on re-source) — but the explicit double-source row from
the design table is NOT present in the test file. **Minor** —
treated as NIT, not BLOCKING, because (a) the lazy design eliminates
the cache-corruption failure mode that the row was designed to
catch, and (b) bash function redefinition on re-source is a documented
language guarantee.

### Implementation correctness (live)

**6. `bash framework/tests/test-audit-trail-layer.sh` → 65/65 passed,
skipped: 0, exit 0.** Delta +10 over pre-R-P8-A baseline of 55.
**VERIFIED.**

**7. `bash -n framework/hooks/_hook-input.sh` → exit 0, no output.
"SYNTAX OK".** **VERIFIED.**

**8. Manual H-G probes:** H-G3 → `rm -rf /`; H-G5 → empty; H-G6 →
`abc`; H-G7 → `FROM_ARGV`; H-G2 → exit 0 / no output. All match
expectations. **VERIFIED.**

**9. Multi-field probe (criterion-9 exact command):** returns `Bash`
then `ls` on separate lines. **VERIFIED.**

**10. Regression:** `test-fix-plan-emit.sh` 37/37 PASS;
`test-hooks-security.sh` 18/18 PASS; `test-hooks-blocking.sh` 12/13
PASS (the 1 pre-existing skip is unchanged from baseline). No new
regressions. **VERIFIED.**

### Honesty / pattern parity

**11. File header parity with `_security-common.sh`:** purpose
statement (line 2), spec-equivalence block (lines 4-9), sourced-by
declaration (line 10), usage examples (lines 12-23), provides list
(lines 25-29) — structure mirrors `_security-common.sh:1-33`.
**VERIFIED.**

**12. Sourcing pattern matches `_audit-probe-marker.sh` precedent:**
helper header lines 13-15 prescribe `[ -f ... ] && source ...`
defensive guard — identical to the `_audit-probe-marker.sh` consumer
contract documented at its header. **VERIFIED.**

### Blast radius

**13. Pure-additive:** `git status --porcelain` shows only
`?? framework/hooks/_hook-input.sh` (new) +
`M framework/tests/test-audit-trail-layer.sh` (H-G block addition).
No other framework file modified. `pinscope/package-lock.json` is
pre-existing unrelated noise (Campaign-B leftover). **VERIFIED.**

---

## Confidence + rationale

**Confidence: HIGH.** All 5 BLOCKINGs closed (one via a sanctioned
design pivot from source-time to lazy-inside-function, the other four
verbatim). Live test execution proves the helper works exactly as
documented: 65/65 layer tests pass, multi-field pattern returns
correct values, regression suite unaffected, syntax clean,
pure-additive blast radius.

**Single residual minor:** double-source reentrance row was relabeled
to filepath extraction (H-G9). The reentrance property is implicitly
held by the lazy design (no module-scope cache → nothing to corrupt;
bash function re-definition is idempotent and language-guaranteed).
This is a documentation drift between design R2 table and the actual
test rows — not a correctness gap. Catalog as **NIT-1** for the
optional Wave-2/3 follow-up to add an explicit reentrance row if the
double-source case ever becomes load-bearing.

**BLOCKING count: 0** (all 5 R1 BLOCKINGs closed).
**NIT count: 1** (double-source row swapped for filepath row; no
correctness impact).

**Recommendation: COMMIT.** R-P8-A is ready for the `phase8(helper):
R-P8-A — shared input-extraction helper _hook-input.sh` atomic commit
and the subsequent R-P8-B/R-P8-C wave hook migrations may proceed.
