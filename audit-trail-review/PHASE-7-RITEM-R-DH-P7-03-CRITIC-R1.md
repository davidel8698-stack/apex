# R-DH-P7-03 — Critic R1 Verdict
**Verdict:** BLOCKING
**Date:** 2026-05-26
**Reviewer:** clean-room critic R1
**Design under review:** `audit-trail-review/PHASE-7-RITEM-R-DH-P7-03-DESIGN.md`

---

## Per-criterion verdicts [1-7]

### Criterion 1 — Test scope adequacy (structural-only, no behavioral cache test)
**Verdict: PASS-WITH-CHANGES (acceptable, but design under-sells one cheap probe).**

The "host-side, cannot be exercised from shell" carve-out is defensible —
the Claude Code harness's session-cache is opaque to a shell test, full
stop. The design is honest about this scope reduction, and L-DH-03 in
FINAL-CERTIFICATION.md §3 only requires that "the framework-auditor
subagent picks up the post-install definition on a fresh session AND
[that we] document … fresh-session [requirement]." Structural drift
catches the most likely failure mode (sync ran in some checkouts but
not others; install copy is stale → stale-session would also be stale).

What the design misses: a `stat`-based modification-time check. If
the install copy's mtime is **older than** the source copy's mtime,
that is per-se evidence that sync has not run since the last source
edit — and that signal is stronger than byte-equality (which can be
trivially defeated by running sync immediately before the test; see
Criterion 5). A 5-line addition (`if [ "$SRC" -nt "$DST" ]; then
fail "install copy older than source" …`) is cheap and adds a real
second axis. Non-blocking.

### Criterion 2 — Agent inventory completeness
**Verdict: BLOCKING — the inventory is wrong.**

The design (§2 Change A point 5) lists nine specialist agents:

> `data.md, frontend.md, integration.md, security.md, batch-scheduler.md,
> batch-verifier.md, memory-synthesis.md, remediation-planner.md` + the
> framework-auditor.md and round-checker.md from points 1+4.

Filesystem ground truth (independent verification, this critic run):

`framework/agents/specialist/` actually contains **only 6 files**:
`batch-scheduler.md, batch-verifier.md, framework-auditor.md,
remediation-planner.md, round-checker.md, wave-executor.md`.

The other five (`data.md, frontend.md, integration.md, security.md,
memory-synthesis.md`) **do not exist** at the path the design
proposes to `diff -q` against. They are **generated at sync time** by
`copy_modules_specialists()` in `framework/scripts/sync-to-claude.sh`
(lines 81-115) which walks `framework/modules/apex-<name>/agent.md`
and emits `~/.claude/agents/specialist/<name>.md`. The source-of-truth
path for those five is `framework/modules/apex-<name>/agent.md`, not
`framework/agents/specialist/<name>.md`.

**Concrete sources** (verified via `find framework/modules -name agent.md`):
- `framework/modules/apex-data/agent.md` → installs to `data.md`
- `framework/modules/apex-frontend/agent.md` → installs to `frontend.md`
- `framework/modules/apex-integration/agent.md` → installs to `integration.md`
- `framework/modules/apex-memory-synthesis/agent.md` → installs to `memory-synthesis.md`
- `framework/modules/apex-security/agent.md` → installs to `security.md`
- `framework/modules/apex-test-architect/agent.md` → installs to `test-architect.md` ← **also missing from design's list**

The design also **omits `wave-executor.md`** from its specialist
list — wave-executor.md exists at `framework/agents/specialist/wave-executor.md`
and is a real specialist agent shipped to the cache, so it must be in scope.

Net impact: if the test is implemented as written, six of the eleven
agents the design's prose claims to cover will either (a) fail the
`diff -q` with "no such file" on the source side, or (b) be silently
omitted because the implementer corrects them to module paths but
without re-deriving the apex- prefix strip rule, or (c) be omitted
entirely because the implementer copy-pastes the list verbatim.
**This is a coverage gap masquerading as coverage.** Block.

**Fix:** rewrite §2 Change A to enumerate the agent set by
**parsing `sync-to-claude.sh`'s own delivery declarations** (same
pattern `test-sync-coverage.sh` already uses; lines 65-77 of that
file). Two loops:
1. Iterate `framework/agents/specialist/*.md` (the directly-copied set)
   and diff each against `~/.claude/agents/specialist/$(basename)`.
2. Iterate `framework/modules/apex-*/agent.md` (the flatten-delivered
   set) and diff each against `~/.claude/agents/specialist/${name#apex-}.md`
   (skipping modules without `agent.md` — `apex-core`, `apex-fintech`,
   `apex-healthcare`, `apex-builder` per `copy_modules_specialists` lines 91-93).

This makes the test self-extending: adding a new specialist module or
agent automatically extends the assertion, matching the "source-of-
truth: sync-to-claude.sh itself" pattern already proven by R10-001.

### Criterion 3 — Core agents drift check (executor, critic, verifier, architect, planner)
**Verdict: BLOCKING — coverage gap.**

The design tests only specialist agents. But core agents (`executor.md`,
`critic.md`, `verifier.md`, `architect.md`, `planner.md`, plus
`auditor.md`, `narrative-auditor.md`, `spec-auditor.md`, and the
`ps-*` quartet) all live under `framework/agents/*.md` and are
**equally cached at session start by Claude Code**. The L-DH-03
mechanism (session cache → mid-session edit → install copy diverges
from cached body) applies identically to them.

If the goal is "structural drift → fresh-session would expose
divergence," the goal applies to **every cached agent**, not just
specialists. A bug in `critic.md` syncs post-mid-session would have
the same confound, and the test as designed would not catch it.

`sync-to-claude.sh` line 418 (`copy_tree "$FRAMEWORK_ROOT/agents"
"$CLAUDE_ROOT/agents"`) copies the entire core-agents tree. The test
should mirror that.

**Fix:** add a third loop iterating `framework/agents/*.md` (excluding
the `specialist/` subdirectory, which is handled by loop 1 above).
Compare each against `~/.claude/agents/$(basename)`. Filesystem ground
truth: 13 core-agent files currently exist
(architect, auditor, critic, executor, narrative-auditor, planner,
ps-remediation-planner, ps-scheduler, ps-verifier, ps-wave-executor,
spec-auditor, verifier — and the `specialist/` dir itself which the
glob `*.md` excludes naturally).

Without this loop, the test's L-DH-03 closure claim is partial: it
defends against drift for specialist agents only, but the confound
mechanism affects all cached agents.

### Criterion 4 — SECURITY-RUNTIME.md thematic fit
**Verdict: PASS-WITH-CHANGES.**

`framework/docs/SECURITY-RUNTIME.md` is currently exclusively scoped
to the `.js`/`.cjs` spec-naming-vs-implementation divergence and the
runtime-aware dispatch for security guards (R5-003, IMP-003, IMP-033).
A new top-level `## Subagent cache invalidation` section is a topic
*shift*, not an extension of the existing arc.

That said, the doc's title is "APEX Security Runtime" — broad enough
to cover "runtime caching behavior the operator must know about,"
which the proposed section is. The shift is tolerable; the alternative
(a new `SUBAGENT-CACHE.md` file or appending to
`framework/docs/HOOK-CLASSIFICATION.md`) would create a one-section
file or stretch HOOK-CLASSIFICATION beyond its current "hook
classification" frame.

**Suggestion (non-blocking):** rename the existing doc to a less
literal title (e.g., "APEX Runtime Notes") if more "runtime gotcha"
sections accumulate. For R-DH-P7-03 alone, appending is acceptable —
but add a brief one-line note at the top of the new section saying
"This section addresses subagent runtime caching; the rest of this
document covers `.js`/`.cjs` spec-naming. Both are 'runtime' concerns
for APEX operators." so a reader skimming for security topics does
not bounce.

### Criterion 5 — sync-to-claude.sh interaction (test-trivially-passes risk)
**Verdict: BLOCKING — the test self-defeats if sync runs first.**

The byte-equality contract is: "install copy matches source copy."
But the install copy IS PRODUCED FROM the source copy by
`sync-to-claude.sh`. Any test execution sequence that runs
`sync-to-claude.sh` immediately before `test-subagent-cache.sh`
makes the assertion trivially PASS — by definition, every install
copy will match its source, because sync just wrote them.

This is precisely the scenario `framework/scripts/sync-to-claude.sh`
invokes via the IMP-036 first-deployment gate: sync runs `run-all.sh`
(per `sync-to-claude.sh`'s gate logic), and `run-all.sh` will pick
up `test-subagent-cache.sh` via the `test-*.sh` glob (line 122 of
run-all.sh). So in the sync-driven CI path, this test is
**structurally a no-op**.

The test only catches a real failure when run **without** a preceding
sync — e.g., a developer commits a source-side edit, doesn't run sync,
and CI runs the test directly. The design's G4 step 1 ("`bash
framework/tests/test-subagent-cache.sh` returns exit 0") doesn't
specify which world the test is run in, so we cannot tell whether the
test was actually exercising drift detection.

**Fix:** the test must either:
(a) document explicitly that it asserts the **post-sync** state and
should be paired with a separate "sync was run recently" check
(e.g., `find ~/.claude/agents -newer framework/agents -print -quit` —
if non-empty, fail with "framework newer than install; run sync"); OR
(b) inspect the install copy's mtime vs. the source's mtime (the
Criterion 1 suggestion) — `[ "$src" -nt "$dst" ]` fails when source
is newer than install, which is the actual drift signal we want.
Either approach decouples the test from a same-run sync.

This is blocking because without one of these fixes, the test as
designed is a **vacuous assertion** in the most likely CI execution
path (the IMP-036 gate), and the design's own G5 PASS criterion #1
("test-subagent-cache.sh exists, runs PASS in isolation") could be
satisfied by an empty `exit 0` script. Self-mocking risk per the
critic STEP-4 rubric.

### Criterion 6 — Cross-platform path concerns (Windows / Git-Bash)
**Verdict: PASS.**

`diff -q` is POSIX and available on Git-Bash for Windows (verified
in the running environment). `~/.claude/...` expands correctly via
HOME under Git-Bash. The existing tests in `framework/tests/` (e.g.,
`test-sync-coverage.sh`, `test-sync-doc-coverage.sh`) already use
these primitives without issue and run green on this host.

One minor caveat: the `mtime` suggestion from Criteria 1 + 5 uses
`[ A -nt B ]` which is POSIX `test(1)` — works on Git-Bash. The
fallback `find -newer` form works too. No platform-specific concerns.

### Criterion 7 — Adversarial probe (false-positive scenarios)
**Verdict: PASS-WITH-CHANGES — first-run scenario uncovered.**

**Probe A: mid-session-edit false positive.** If a developer edits
`framework/agents/specialist/framework-auditor.md` and immediately
runs `bash framework/tests/test-subagent-cache.sh` BEFORE running
sync, the test SHOULD fail (drift exists), and that is the CORRECT
behavior — the design's intent is precisely to catch this. Not a
false positive; this is the test working.

**Probe B: missing install path / first-run scenario.** If the user
clones the repo and runs `bash framework/tests/run-all.sh` BEFORE
running `sync-to-claude.sh` for the first time, `~/.claude/agents/`
might not exist at all. The design does not specify behavior in
this case. `diff -q FRAMEWORK ~/.claude/agents/specialist/foo.md`
will fail with "no such file" → test exits non-zero → the
first-time CI run is broken for reasons unrelated to drift. This is
a real false-positive class.

**Fix:** pre-flight check at the top of the test:
```
if [ ! -d ~/.claude/agents/specialist ]; then
  echo "SKIP: ~/.claude/ not initialized (run sync-to-claude.sh first)"
  exit 0
fi
```
Documented as SKIP (not FAIL) so the first-run path is not red.
Same convention as `test-sync-coverage.sh` already uses for similar
pre-flight gating.

**Probe C: user-local edits to `~/.claude/agents/*.md`.** A
sufficiently motivated operator might hand-edit a deployed
specialist agent (e.g., to tune prompts). The byte-equality test
will fail on legitimate user customization. This is a feature, not
a bug — the design's whole point is "drift exists; fresh session
would see it" — but the SECURITY-RUNTIME doc should add one line
saying "If you intentionally customize a deployed agent, you accept
the drift signal; re-sync to restore." Non-blocking.

---

## Blocking findings

**B-1 (Criterion 2):** Agent inventory in §2 Change A is materially
wrong. 5 listed agents (`data, frontend, integration, security,
memory-synthesis`) do not exist at the path the design references;
their source-of-truth is `framework/modules/apex-<name>/agent.md`,
not `framework/agents/specialist/<name>.md`. 2 agents are missing
from the list entirely (`wave-executor`, `test-architect`). Fix:
parse `sync-to-claude.sh`'s own delivery declarations (mirror the
R10-001 `test-sync-coverage.sh` pattern).

**B-2 (Criterion 3):** Test omits core agents
(`executor, critic, verifier, architect, planner, auditor,
narrative-auditor, spec-auditor`, plus the 4 `ps-*` agents). The
L-DH-03 cache mechanism affects them identically. Add a loop over
`framework/agents/*.md` (excluding the `specialist/` subdir).

**B-3 (Criterion 5):** Test is vacuous in the IMP-036 first-deployment
gate execution path, because sync runs `run-all.sh` after writing
the install copies — so byte-equality is guaranteed to hold by
construction. Add an mtime-based drift signal (`[ src -nt dst ]`)
OR a pre-sync state assertion to make the test non-vacuous when
invoked via the sync-driven CI path.

---

## Non-blocking suggestions

**N-1 (Criterion 1):** Add a `stat`/`mtime` axis. `[ "$SRC" -nt "$DST" ]`
catches "source newer than install" — a stronger drift signal than
byte-equality alone, and not defeatable by a same-run sync.

**N-2 (Criterion 4):** Add a one-line topic-shift note at the top of
the new SECURITY-RUNTIME.md section ("This section covers subagent
runtime caching; the rest of the document covers `.js`/`.cjs` spec-
naming") so a reader skimming for security topics is not surprised.

**N-3 (Criterion 7, Probe B):** Pre-flight skip when
`~/.claude/agents/specialist/` does not exist (first-run scenario).
Use SKIP not FAIL.

**N-4 (Criterion 7, Probe C):** Document the user-customization
trade-off in SECURITY-RUNTIME.md ("intentional local edits → re-sync
to restore drift-free state").

**N-5 (§5 G5 PASS criterion #1):** Strengthen the criterion to "test
runs PASS, AND inspection shows at least N>=15 diff/mtime assertions
fire (one per agent × 2 checks)" rather than just "exits 0." Prevents
a vacuous-script regression. Mirrors the explicit assertion-count
expectation in §4 G4 step 1 ("at least 10 PASS assertions").

---

## Final verdict

**BLOCKING.**

Three blocking findings (B-1 inventory wrong, B-2 core agents
omitted, B-3 vacuous in CI path) each independently require design
revision before G3 implementation. Without B-1's fix, the test
references non-existent source paths and will fail on first run for
reasons unrelated to the L-DH-03 confound. Without B-2's fix, the
test covers only the specialist half of the agent surface — half the
L-DH-03 mechanism remains unguarded. Without B-3's fix, the test is
structurally vacuous in the IMP-036 first-deployment gate execution
path that runs it.

The doc change (Change B, §"Subagent cache invalidation") is fine
modulo N-2 — content is correct, anchors are correct, and the
fresh-session operating requirement matches L-DH-03's stated
mitigation. The blocking items are entirely in Change A (the test).

Resubmit with revised §2 Change A that:
1. Parses agent inventory from `sync-to-claude.sh` (handles both
   `copy_tree agents` and `copy_modules_specialists` deliveries).
2. Adds a loop for core agents under `framework/agents/*.md`.
3. Asserts `[ src -nt dst ]` mtime comparison (non-vacuous signal)
   in addition to `diff -q` byte-equality.
4. Pre-flight SKIPs when `~/.claude/agents/specialist/` is absent.
