# R-P8-A G2 CRITIC R1

## Overall verdict: PASS-WITH-CHANGES

Pure-additive helper file with no consumer cuts in this R-item, so the
blast radius is genuinely small. Several design-level gaps must be
closed before G3 implementation: the invocation-count number is wrong,
H-G0..H-G5 rows are named but never spelled out, and there is a
predicted-impl subshell hazard (module-scope cache flag will not survive
through a `$(...)` extractor call) that needs an explicit decision.
Honesty axis is borderline because "9 argv-style test invocations" is
empirically false.

---

## Per-axis findings

### Axis 1 — API soundness

- **PASS** Function-naming `apex_hook_input_{command,filepath,tool_name,raw}`
  is unambiguous and namespace-safe (long prefix, no collision with
  `_sec_*` family in `_security-common.sh:35-50`).
- **NIT** API spec at `PHASE-8-R-P8-A-DESIGN.md:12-15` does not state
  the return contract (echo to stdout? set a named variable? exit
  code?). owner-guard.sh:64-72 uses `FILEPATH=$(...)`-style capture, so
  the implicit contract is stdout-echo, but the design never says so.
  Consumers will copy-paste wrong without this.
- **PASS** Argv-first priority is the correct choice — it preserves
  the 27 (see Axis 3) argv-style test invocations untouched, and
  argv+stdin precedence matches the existing owner-guard.sh:64-72
  canonical pattern.
- **NIT** No statement on whether the helper exports the functions
  (i.e., whether `$(...)` subshells inherit them). bash function export
  requires `export -f`; missing this will silently break any consumer
  that calls the extractor inside `$(...)`. See Axis 2 for the
  follow-on subshell hazard.

### Axis 2 — Predicted impl bugs

- **BLOCKING** Module-scope cache flag `_APEX_HOOK_STDIN_CACHED`
  (line 17) does NOT survive a `$(...)` subshell. The canonical
  consumer pattern is
  `FILEPATH=$(apex_hook_input_filepath "$@")` (mirroring owner-guard.sh:64,
  `FILEPATH=$(... | jq -r ...)`), which runs in a subshell. The cache
  flag set inside that subshell is lost on return, and the second
  extractor call will re-read stdin — which is by then drained. Net
  result: second extractor returns empty. Design must either (a)
  prescribe call-once-then-use-variable pattern in consumers, or (b)
  cache via a file/named-pipe under `/tmp`, or (c) accept that the
  helper only supports ONE field per invocation. Pick one and document
  it.
- **BLOCKING** `[ ! -t 0 ]` (line 17) is true whenever stdin is not a
  TTY — including a closed/empty pipe such as `bash hook.sh "arg"
  </dev/null`. The current owner-guard.sh:65 already guards this with
  `[ -z "$FILEPATH" ] && [ ! -t 0 ]`, so argv-first short-circuits the
  problem there. But if the helper is called as
  `apex_hook_input_raw "$@"` (no argv → falls to stdin), an
  argv-supplied test invocation with a closed stdin would block on
  `cat` waiting for EOF. Actually `cat </dev/null` returns immediately
  — so this is OK, but the design must state explicitly that callers
  must NOT use `apex_hook_input_raw` when argv is the source. The
  `[ -p /dev/stdin ] || [ ! -t 0 ]` alternative mentioned in the
  task prompt is less portable (no `/dev/stdin` on some bare-bones
  shells) — owner-guard.sh's `[ ! -t 0 ]` is fine; keep it.
- **NIT** Quote handling: design says "`printf '%s' "$1"` vs jq `-r`"
  is a concern. The correct combo is `printf '%s' "$PAYLOAD" | jq -r
  '...'` (no extra newline, no shell expansion). `_security-common.sh:39`
  uses `printf '%s' "$input" | sed ...`, same idiom — adopt it
  verbatim. `echo "$x"` would corrupt payloads with leading `-` or
  embedded backslashes; design must commit to `printf '%s'`.
- **NIT** `set -u` is asserted in Critic R1 focus item 6 but the
  design never confirms the helper itself runs under `set -u`. Add
  `set -u` to the helper header so a consumer that forgets to source
  it under `set -u` still surfaces unbound-variable bugs.

### Axis 3 — Backward-compat verification

- **BLOCKING (honesty)** Design line 5 + line 35 say "9 argv-style
  test invocations." Actual count across the three referenced test
  files: `test-fix-plan-emit.sh` 6 + `test-hooks-security.sh` 15 +
  `test-hooks-blocking.sh` 6 = **27** argv-style invocations
  (verified via grep, regex
  `bash\s+"\$HOOKS_DIR/<hook>\.sh"\s+`). This is a 3x undercount.
  Either the design surveyed the wrong scope or "9" refers to 9
  unique hooks — say which. Until corrected this axis cannot be
  certified, because the test-plan coverage claim is based on the
  wrong denominator.
- **PASS (mechanism)** For each of those 27 invocations, argv-first
  priority returns `"$1"` verbatim — byte-equivalent to the existing
  `FOO="${1:-}"` line in each consumer. So the *mechanism* is correct;
  it's just the *count* that is wrong.
- **NIT** `test-imp016-writer-side.sh` (sequence-guard) is not listed
  in the design's three target test files. Confirm whether it is
  in-scope for R-P8-A or deferred to a later R-item.

### Axis 4 — Test plan completeness

- **BLOCKING** H-G0..H-G5 are named at design line 28 + 43 but never
  *defined*. A G2 design that hands off to G3 must spell out each row:
  what is asserted, what the input is, what the expected output is.
  As written, the implementer is free to invent any 6 rows and call
  it done — that is exactly the kind of phantom-evidence gap the
  framework's own phantom-check hook exists to catch.
- **BLOCKING** Missing test rows even at the name level:
  - "helper does NOT execute standalone" (i.e., `bash _hook-input.sh
    foo` exits 0 with no side effects, matching `_security-common.sh`
    convention "Never executed directly").
  - "double-source reentrance" (sourcing the helper twice in the
    same process must not redefine functions or corrupt the cache
    flag). This is called out as a critic-focus item (line 37, line
    44) but has no corresponding test row.
  - "stdin double-read with subshell capture" — the bug in Axis 2,
    BLOCKING #1.
  - "set -u compatibility under empty argv" — argv-first with no
    `$1` must not bomb on `unbound variable` (the `${1:-}` default
    expansion covers this, but it deserves a regression row).
- **NIT** The H-G* rows are claimed to live "before summary block" in
  `test-audit-trail-layer.sh`, but that file's summary block is at
  the very end (around line 329+). Pick a more specific anchor (e.g.,
  "after section X, before section Y") so the implementer cannot
  drift.

### Axis 5 — Pattern parity

- **PASS** Sourcing pattern (`PHASE-8-R-P8-A-DESIGN.md:22-26`) matches
  `_audit-probe-marker.sh`'s contract: defensive `[ -f ]` guard before
  `source`, identical to `destructive-guard.sh:11-23`.
- **PASS** File header convention can be inherited from
  `_security-common.sh:1-29` (purpose, sourced-by, usage, provides) —
  parity is fine.
- **NIT (justified)** Function-naming distinction: `_sec_*`
  (underscore-prefixed → "private to security guards") vs
  `apex_hook_input_*` (long form, no underscore prefix → "public
  shared API"). This *is* a legitimate distinction: `_sec_*` is local
  to the security family; the new helper is a project-wide
  primitive. Recommend the design state this explicitly so the
  pattern doesn't drift over time (someone will eventually ask why
  the inconsistency exists).
- **NIT** `_audit-probe-marker.sh` uses lowercase `local cmd` for
  function-internal variables (line 40); owner-guard.sh uses uppercase
  `FILEPATH` at module scope. Pick one for `_hook-input.sh` and state
  it (local lowercase is the bash idiom; uppercase is the APEX
  convention) — implementer needs guidance.

### Axis 6 — Honesty

- **BLOCKING** Design line 56: "Pure additive (new file only). Zero
  existing hooks affected." This is true for R-P8-A *as scoped here*
  (just creating the helper), but the surrounding task framing
  ("15 hooks will source" — task prompt) means the second wave will
  affect every one of those 15 hooks. If the design genuinely means
  "R-P8-A in isolation has zero blast radius," say so. As written, the
  sentence is technically accurate but misleading in context.
- **BLOCKING** "9 argv-style test invocations" is empirically false.
  See Axis 3.
- **PASS** "Module-scope flag `_APEX_HOOK_STDIN_CACHED` prevents
  double-read" is stated as a *claim*, not as a *verified
  property* — but as noted in Axis 2 BLOCKING #1, the claim is
  itself wrong under `$(...)` subshell capture. Treat this as an
  honesty issue once Axis 2 BLOCKING #1 is acknowledged.

---

## Confidence + rationale

**Confidence: HIGH** that the helper concept is sound and the
canonical-template choice (owner-guard argv-first → stdin-fallback) is
correct. **Confidence: HIGH** that the design as written is too thin to
hand off to G3 implementation safely — the subshell-cache hazard, the
27-vs-9 invocation undercount, and the unspecified H-G* test rows are
all independently sufficient to block.

**BLOCKING count: 5**
1. Subshell cache flag bug (Axis 2)
2. `[ ! -t 0 ]` + cat semantics not fully documented (Axis 2)
3. "9 invocations" wrong count — actual 27 (Axis 3 + Axis 6)
4. H-G0..H-G5 rows undefined (Axis 4)
5. Missing test rows for standalone-no-execute + double-source +
   subshell-capture (Axis 4)

**NIT count: 8** (return-contract; function-export; quote idiom;
helper-internal `set -u`; test-imp016 scope; double-source row name;
anchor specificity; function-name distinction documentation; local
vs uppercase variable idiom — 9 actually; recount welcome)

**G3 entry recommendation:** address BLOCKINGs 1, 3, 4 (numeric +
test-row gaps) in a brief design R2 before implementation. BLOCKINGs 2
and 5 can be folded into the same R2.
