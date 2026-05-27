# Wave 3 (R-P8-C11..C15) — G2 critic R1

## Overall verdict: PASS-WITH-CHANGES

The design is structurally sound and the 5 migrations preserve byte-equivalent
behavior across every shape exercised by the existing regression suite. I ran
each charter trace against the actual pre-migration source on disk and against
the helper's actual function bodies in `framework/hooks/_hook-input.sh`. No
BLOCKING divergence found.

Two issues raised below as PASS-WITH-CHANGES rather than NIT because they
deserve to be addressed before G3 implementation: (a) C12's outer guard
narrows from "stdin-present" to "argv-empty" — a documented divergence in
the "argv AND stdin both present" corner case, harmless in the test suite
and in production but worth an inline comment so future maintainers do not
re-discover it; (b) ci-scan source-position is unspecified by the design
and matters because the helper sets `set -u`.

## Per-check findings (charter 1-7)

### C11 owner-guard — byte-equivalent — PASS

Verified by side-by-side reading of `framework/hooks/owner-guard.sh` L64-72
against `apex_hook_input_filepath` (helper L86-100):

- Both argv-first: original `FILEPATH="${1:-}"` then `[ -z "$FILEPATH" ]`
  fallback; helper `if [ -n "${1:-}" ]; then printf '%s' "$1"; return 0; fi`.
  Identical priority.
- Both jq query: original L69
  `.tool_input.file_path // .tool_input.path // empty`; helper L96
  `.tool_input.file_path // .tool_input.path // empty`. **Byte-identical query.**
- Both fail-safe-empty: original wraps in `|| true` and tolerates missing jq
  (the outer `command -v jq` guard); helper internally does
  `command -v jq >/dev/null 2>&1` before invoking jq, and returns empty
  when stdin is TTY. Both return empty under missing-jq and under empty-stdin.
- The helper's `printf '%s'` (no trailing newline) matches the original's
  `printf '%s'` use in the jq fallback path. The original argv path uses
  `FILEPATH="${1:-}"` (no printf at all — direct assignment), which is
  fully equivalent at the `FILEPATH` variable level since the design's
  `FILEPATH=$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")`
  captures the helper's printf'd output, and trailing-newline behavior is
  irrelevant because the consumer (owner-guard L75 `[ -z "$FILEPATH" ]`,
  L153 string match) does not depend on it.

All 10 cases in `test-owner-guard.sh` pass argv via `$1` (lines 109, 129,
150, 173, 191, 207, 226, 230) — every one short-circuits to the argv leg
of the helper. Net behavior unchanged.

### C12 ci-scan 3-shape routing — PASS-WITH-CHANGES

Trace per charter:

1. **`bash ci-scan.sh .github/workflows` (S-11/S-12/S-14):** Original L123
   `[ -p /dev/stdin ] || [ ! -t 0 ]` *may* fire in a non-TTY test harness;
   stdin would be empty/non-JSON → `HOOK_PATH` stays empty → falls through
   to argv branch L145 → `WORKFLOWS_DIR=".github/workflows"` → scan. New
   code: outer `[ -z "${1:-}" ]` is **false** (argv present) → skip stdin
   block entirely → straight to argv branch. **Same end state.** ✓

2. **`bash ci-scan.sh .github/workflows/ci.yml` (argv = file):** Outer
   false → skip stdin → argv branch → `[ -f "$ARG" ]` true → case-glob
   matches → `WORKFLOWS_DIR=dirname`. Identical in both. ✓

3. **`bash ci-scan.sh nonexistent-dir` (S-13):** Outer false → skip stdin →
   argv branch → not a file → `WORKFLOWS_DIR=nonexistent-dir` → L163
   `[ ! -d ]` → `exit 0`. Identical. ✓

4. **`echo '{"tool_input":{"file_path":".github/workflows/ci.yml"}}' | bash ci-scan.sh` (C-5):**
   Outer true (no argv) → helper called → `[ ! -t 0 ]` true + jq present →
   reads payload via `cat`, runs the jq query
   `.tool_input.file_path // .tool_input.path // empty`. **The helper's jq
   query is byte-identical to original L127** — confirmed at `_hook-input.sh`
   L96. Output `.github/workflows/ci.yml` → case-glob matches →
   `WORKFLOWS_DIR=.github/workflows` → scan. ✓

5. **`echo '{"tool_input":{"file_path":"README.md"}}' | bash ci-scan.sh` (C-4):**
   Outer true → helper returns `README.md` → case-glob fails → `exit 0`.
   Identical. ✓

6. **`bash ci-scan.sh` (C-7 / C-8 default):** Outer true (no argv) → helper
   called → either TTY-stdin (returns empty) or piped non-envelope (e.g.,
   `tool_input:{}` C-8 case — jq returns empty). `HOOK_PATH` empty → skip
   case-glob → `WORKFLOWS_DIR` stays empty → fall to L145 argv branch →
   `ARG="${1:-.github/workflows}"` → `.github/workflows`. Identical. ✓

**Divergence in one corner case (charter "ANY shapes where new diverges"):**
Original outer guard fires on *stdin-present-regardless-of-argv*. New outer
guard fires on *argv-empty-regardless-of-stdin*. Therefore:

- `echo '{...envelope outside-workflows...}' | bash ci-scan.sh .github/workflows`
  (BOTH argv-dir AND stdin envelope present): **original** would enter
  stdin block, extract `src/foo.ts`-style path → case-glob fails → `exit 0`
  (self-filter wins over argv). **New** skips stdin block, goes straight
  to argv branch → scans `.github/workflows`. **Behaviorally different.**

No test exercises this combination (S-11..S-14, C-5..C-8 all use argv XOR
stdin, never both). Claude Code's PostToolUse runtime never pairs argv with
stdin (settings.json invocation passes envelope on stdin only). Manual CLI
invocation never pairs argv with stdin envelope. The corner case is
unreachable in practice, but the design's stated "3-shape routing preserved"
is technically a 4-shape question and the design does not call out this
narrowing. **Recommend:** add a one-line comment near the new outer guard
explicitly noting that argv-present now short-circuits stdin (intentional
narrowing — matches the design intent that argv-style test invocations
"bypass the self-filter exactly as before"). This makes the divergence
auditable in-tree without changing behavior.

### C13 test-deletion-guard multi-field — PASS

- Original L40-43: `PAYLOAD=""; if [ ! -t 0 ]; then PAYLOAD=$(cat 2>/dev/null || true); fi`.
- Helper `apex_hook_input_raw` with no args: L121-128
  `if [ -n "${1:-}" ]; then printf '%s' "$1"; return 0; fi; if [ ! -t 0 ]; then cat 2>/dev/null || true; fi`.
- With no args, `[ -n "${1:-}" ]` is false → falls to `[ ! -t 0 ]` → `cat`.
  **Byte-identical to original.** ✓
- Empty-piped-stdin edge case: `cat` reads zero bytes → returns empty string
  → helper echoes empty → captured `PAYLOAD=""` → L45 `[ -z "$PAYLOAD" ] && exit 0`.
  Identical in both. ✓
- Multi-field consumption: `PAYLOAD` is read once and re-piped through jq
  on L53-54 for `.tool_name` and `.tool_input`. The helper consumes stdin
  exactly once (single `cat` inside the helper), then exits the subshell
  releasing payload via stdout. The captured `PAYLOAD` is then re-used for
  the two jq queries. **Identical to original.** ✓
- Degraded install: `command -v apex_hook_input_raw` false → `PAYLOAD` stays
  empty → L45 fail-safe `exit 0`. Acceptable per design G4 "fail-safe" claim.
- One observation: the `apex_hook_input_raw` helper does NOT require jq for
  the stdin path (it just does `cat`), whereas the original does not require
  jq for the cat-step either (jq comes in at L53). Equivalent. ✓

### C14 pre-task-snapshot argv ≠ command — PASS

- `bash pre-task-snapshot.sh "T-123"` with stdin envelope `{command:"git status"}`:
  helper called with NO args (per design L218 `apex_hook_input_command` —
  not `"$@"`) → `[ -n "${1:-}" ]` is false → `[ ! -t 0 ]` true + jq present →
  reads payload, runs jq `.tool_input.command // empty`. **Helper jq query
  byte-identical to original L40** (`.tool_input.command // empty`). Returns
  `git status` → `USER_CMD="git status"` → self-filter parses → matches
  `status` second token under `git` first token → `exit 0`. Identical. ✓

- `bash pre-task-snapshot.sh "T-123"` with NO stdin (CLI mode):
  helper called with no args → no $1 → `[ ! -t 0 ]` false (TTY) → returns
  empty → `USER_CMD=""` → skip self-filter block → snapshot path proceeds.
  L66 `TASK_ID=${1:-"unknown"}` = "T-123" — argv preserved. ✓ Identical to
  original L37-58 (which also enters the block only when `[ ! -t 0 ]` is
  true → in TTY mode, original also skips).

- `bash pre-task-snapshot.sh` with NO argv AND stdin envelope:
  helper returns command string. TASK_ID at L66 falls to "unknown". Self-
  filter logic still parses USER_CMD correctly. ✓ Identical.

- **The critical design decision (calling helper with NO args) is correct.**
  If the design had used `apex_hook_input_command "$@"`, then a CLI
  invocation `bash pre-task-snapshot.sh "T-123"` would treat "T-123" as
  `USER_CMD`. The self-filter would parse FIRST_TOK="T-123", which is
  not "git" → self-filter skipped → snapshot fires. Outcome would
  *coincidentally* be the same (TASK_ID is essentially never "git" — APEX
  task IDs are like "T-7-001" or "R-P8-C14"), but the semantic confusion
  would be a future-bug pit. The design correctly sidesteps this.

- All four cases in `test-pre-task-snapshot.sh` (Case 1 git-status envelope,
  Case 2 npm-build envelope, Case 3 CLI standalone, Case 4 git-stash
  envelope) are exercised: argv `task-1..task-4` are TASK_IDs in every
  case, and stdin is either an envelope or `</dev/null`. New helper call
  (no args) extracts only from stdin, preserving the argv/stdin decoupling.
  All four cases will remain green.

- `test-critic-git-trace.sh` E3 anchor `task_start_sha.*rev-parse HEAD`
  scans for the LITERAL substring in `pre-task-snapshot.sh` source —
  Wave 3 does NOT touch L94 (`task_start_sha=$(git -C "$REPO_ROOT" rev-parse HEAD ...)`),
  so this anchor remains green.

### C15 workflow-guard `.path` superset — PASS (forward-compat correct)

- Original L58: `jq -r '.tool_input.file_path // empty'`.
- Helper L96: `jq -r '.tool_input.file_path // .tool_input.path // empty'`.

The helper's jq query is a strict **superset** of original behavior:

- Case `.tool_input.file_path` set: both return that value. ✓
- Case `.tool_input.file_path` unset, `.tool_input.path` set: original
  returns empty, new returns `.path` value.
- Case both unset: both return empty. ✓

Is the second case exercised by any fixture? Searched the test files: no
fixture in `test-hooks-security.sh` S-7..S-10/S-8b emits `.tool_input.path`
— all argv-driven. `test-hooks-blocking.sh` and other workflow-guard tests
similarly do not emit `.path`. **No regression.**

Is the second case reachable in production? Claude Code's hook protocol
emits `.tool_input.file_path` for Write/Edit and Read tools — never `.path`.
The `.path` key is a legacy/alternate convention that the helper accepts
defensively but no current caller emits. **Design's "forward-compatible"
claim is accurate.**

Wave 2 precedent: `path-guard.sh` and other Wave-2 hooks were also migrated
to `apex_hook_input_filepath` which has the same `.path` superset. Wave 2
critic R2 explicitly verified that the superset did not introduce regressions
(7/7 stdin probes green). Same applies here.

### 6. Source order — PASS-WITH-CHANGES

The design does not specify where to insert the new `_hook-input.sh` source
in each hook. Reading the actual hook sources:

| Hook | Existing sources (order) | Recommended insertion point |
|------|---------------------------|------------------------------|
| `owner-guard.sh` | L51-53 `_fix-plan-emit.sh` | After L53, before L56 fast-path |
| `ci-scan.sh` | L18 `_security-common.sh` | After L18, before debounce gate L40 |
| `test-deletion-guard.sh` | L32 `_require-jq.sh` | After L32, before L35 carve-out (or before L40 PAYLOAD block) |
| `pre-task-snapshot.sh` | L23 `_require-jq.sh`, L25 `_state-update.sh` | After L25, before L29 self-filter block |
| `workflow-guard.sh` | L22 `_security-common.sh`, L29-31 `_fix-plan-emit.sh` (conditional) | After L31, before L54 FILE assignment |

**Why this matters:** `_hook-input.sh` does `set -u` at its L64. Sourcing
into a hook that already runs `set -u` is a no-op (already set). But the
helper also defines functions named `apex_hook_input_*` — these do NOT
clash with any existing function names in the other helpers (`_security-common.sh`
uses `_sec_*`, `_fix-plan-emit.sh` uses `emit_fix_plan`, `_state-update.sh`
uses `_state_update`, `_require-jq.sh` uses `require_jq`). No function
shadowing risk.

**One subtle interaction in `workflow-guard.sh`:** L32-51 capture
`_sec_block_orig` and conditionally redefine `_sec_block`. The helper
source must come **after** L29-31's `_fix-plan-emit.sh` source (so the
override pattern stays intact) but **before** L54's `FILE="${1:-}"` (so
the design's replacement of L54-59 can reference the helper). The natural
insertion is L52-53, between the override block and the FILE assignment.

**Recommend:** the design should specify the insertion line range per hook
(matching the Wave 2 design convention) so the executor cannot accidentally
insert above an earlier source that the override depends on. The Wave 2
critic R2 showed source-position correctness was verified per-hook —
Wave 3 should adopt the same explicit-line convention.

### 7. `set -u` compatibility — PASS

Verified pattern usage in design:

- `${1:-}` — set-u safe (default-substitution). Used in C11, C12 outer guard,
  C15. ✓
- `${VAR:-}` inside helper — set-u safe. Helper itself sets `set -u` at L64
  but uses `${1:-}` consistently in all four extractors. ✓
- `command -v apex_hook_input_filepath` — does not reference variables. ✓
- `$(apex_hook_input_filepath "$@" 2>/dev/null || printf '%s' "${1:-}")` —
  `"$@"` is set-u safe (degrades to empty string list when no positional
  args). ✓

All 5 hooks already start with `set -u` (owner-guard L48, ci-scan L2,
test-deletion-guard L2, pre-task-snapshot L2, workflow-guard L2). The
helper additionally sets `set -u` at L64. Sourcing is idempotent. No
unbound-variable surface introduced.

### Layer test row count math — PASS

Wave 2 closed at 81 PASS (per `PHASE-8-WAVE-2-CRITIC-R2.md` §4). Design
adds H-G26..H-G30 = +5 rows. 81 + 5 = 86. ✓

Skip label update `H-G0..H-G25` → `H-G0..H-G30` is consistent with Wave 1
(H-G0..H-G17) → Wave 2 (H-G0..H-G25) → Wave 3 (H-G0..H-G30) progression.

### Wave 2 precedent alignment — PASS

The Wave 3 canonical drop-in pattern (owner-guard L66-68, workflow-guard
L264-266) matches the Wave 2 canonical pattern verbatim (8 lines: 3 comment
+ 3 source guard + 1 blank + 1 extraction). Both rely on the same
degraded-install gate (`[ -f "$(dirname "$0")/_hook-input.sh" ]`) and the
same fallback (`|| printf '%s' "${1:-}"`). Style consistency confirmed.

## BLOCKING

none

## NIT

1. **ci-scan source-position underspecified.** Design G3 step 2 says
   "replace L122-142 stdin block" but does not state where the new
   `source "$(dirname "$0")/_hook-input.sh"` line goes. From the
   pre-Wave-3 source, the natural site is between L18 (`_security-common.sh`
   source) and L40 (debounce gate). Recommend the design explicitly state
   "insert helper source between L18 and L20" to avoid executor ambiguity.
   Same applies to the other 4 hooks (see source-order table in check 6).

2. **C12 outer-guard narrowing not documented in the hook source.** The
   new outer guard `[ -z "${1:-}" ]` is narrower than the original
   `[ -p /dev/stdin ] || [ ! -t 0 ]`. The corner case
   "argv + stdin envelope BOTH present" is unreachable in practice but
   diverges behaviorally. Recommend the design add an inline comment in
   the new C12 code:
   `# Helper invoked only when argv is absent — argv-style invocations bypass`
   `# the self-filter exactly as before (3-shape routing preserved).`
   This makes the intentional narrowing auditable in-tree.

3. **No regression test for the C12 stdin path.** Design G4 defers C12
   parity to "G5 manual probe" because of fixture cost. However,
   `test-ci-scan-wiring.sh` C-5 already exercises the stdin envelope path
   with a fixture. Recommend adding **one** automated parity row
   `H-G27b: ci-scan stdin envelope yields same WORKFLOWS_DIR as original`
   by replaying the C-5 fixture and asserting exit-2 on the malicious
   bad.yml. Cost is low (the fixture is already built in test-ci-scan-wiring)
   and it locks the most subtle migration into automated regression.

4. **No automated parity test for C14 pre-task-snapshot stdin extraction.**
   Same observation as #3 — `test-pre-task-snapshot.sh` Cases 1 and 4
   already provide stdin envelopes; the layer test could replay one of
   them. Optional given the dedicated test file covers the path.

5. **`test-deletion-guard.sh` has no dedicated regression test.** Design
   G0 calls this out; no layer-test parity row is added (only the
   sources-helper probe H-G28). The behavior change risk is low (stdin-only
   hook with one path), but a single H-G probe firing the
   `{"tool_name":"Bash","tool_input":{"command":"rm test/foo.test.js"}}`
   envelope and asserting exit-2 would lock the multi-field consumption
   into regression. Optional — design G4's exclusion rationale ("stdin-only,
   no argv path to compare") is technically true but does not preclude a
   "stdin → exit-2" assertion in isolation.

6. **Cross-reference accuracy.** Design G0 lists `test-audit-trail-layer.sh`,
   `test-fix-plan-emit.sh`, `test-hooks-blocking.sh` in the G5 regression
   sweep, but these were never specifically the ones the Wave-3 hooks
   touch. The actual minimum regression set for Wave 3 is:
   - `test-owner-guard.sh` (C11)
   - `test-hooks-security.sh` lines 100-145 (C12 + C15)
   - `test-pre-task-snapshot.sh` (C14)
   - `test-critic-git-trace.sh` (C14 anchor only — passes if L94 untouched)
   - `test-ci-scan-wiring.sh` (C12)
   - `test-hooks-blocking.sh` (B-5 grep-only — C14)
   - `test-audit-trail-layer.sh` (H-G section update)

   The design lists this correctly in G5 §1 but the broader G0 table is
   slightly under-specified. Minor.

## Confidence

**HIGH** — Every charter trace was executed against the actual on-disk
pre-migration hook sources (owner-guard L64-72, ci-scan L122-142,
test-deletion-guard L40-43, pre-task-snapshot L37-58, workflow-guard L54-59)
and against the actual `_hook-input.sh` helper function bodies (L70-130).
The jq queries are confirmed byte-identical for all four extractors
relative to the originals (`.tool_input.file_path // .tool_input.path //
empty`, `.tool_input.command // empty`, raw cat). The Wave 2 precedent
provides the canonical 8-line pattern which is reused verbatim in C11 and
C15. The C12 3-shape routing is preserved end-to-end with one documented
narrowing in the unreachable "argv+stdin both present" corner. The C14
"call helper with NO args" decision is structurally correct and prevents
the TASK_ID/USER_CMD confusion. The C13 multi-field consumption via
`apex_hook_input_raw` matches the documented helper-API use case from
`_hook-input.sh` L19-23. Source-order analysis confirms no function-name
clashes with the four already-sourced helpers. Layer test math is correct
(81 → 86 = +5). PASS-WITH-CHANGES is conservative: zero behavior-change
blockers, six low-cost improvements that would harden the migration without
expanding scope.
