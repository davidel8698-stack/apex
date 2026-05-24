# Verify Report — PS-R20

**Round:** 20
**Verifier:** ps-verifier (clean-room)
**Generated:** 2026-05-24
**Inputs re-read:** `ac-results-R20.json`, `REMEDIATION-PLAN-R20.md`,
`WAVE-R20-RESULT.md` (data only), `loop.json`, `mutation-R20.json`,
`ac-matrix.json`. Source/config grepped independently.

---

## Verdict

**PARTIAL.**

All 5 R-items meet their pre-written DoDs on disk; harness is intact;
mutation kill-rate is 10/10; commit window is non-empty. However,
`ac-results-R20.json` records 2 FAIL verdicts (AC-090, AC-104) on
previously-`CLOSED` ACs. Per ps-verifier role contract STEP 5, any
previously-`CLOSED` AC now failing is a regression — even when the failure
is not an implementation defect. Therefore `PASS` is not reachable;
`PARTIAL` is the correct verdict.

---

## Confirmed closures

All 5 R-items are confirmed closed against their pre-written Definition of
Done. Independent re-run of each DoD clause:

### R-20-01 — VoidBadges mounted into visible-HUD createPortal tree
- `grep -n 'VoidBadges' pinscope/src/runtime/PinScope.tsx` → **4 hits**
  (L7 import, L303 comment, L326 comment, L330 render). DoD required ≥2
  (import + render) — **satisfied**.
- `grep -rn 'VoidBadges' pinscope/src/` shows the component definition
  (`VoidBadges.tsx`) AND the consumer (`PinScope.tsx`) — DoD min-2-files
  satisfied.
- `git show --stat 98841a4` confirms `PinScope.tsx +51 lines` and
  `pinscope.test.tsx +128 lines` (R-20-01/02/03 DoD tests).
- Mounted under `{pinsVisible && <VoidBadges />}` — the R-20-03 visibility
  gate also wraps the void-badge layer, exactly as the cross-R-item
  ecosystem note Q6 anticipated.

### R-20-02 — RuntimePinObserver lifecycle useEffect in PinScopeHud
- `grep -nE 'RuntimePinObserver|useEffect' pinscope/src/runtime/PinScope.tsx`
  → import line 3 (`useEffect` added to react imports), import line 32
  (`RuntimePinObserver`), comment line 170, `useEffect(() => {` at line 177,
  observer instantiation at line 184. DoD required imports + a `useEffect`
  with cleanup calling `.stop()` — **satisfied** (cleanup verified by
  reading L177ff: `observer = new RuntimePinObserver()` then return path
  calling `.stop()`).
- The DoD's named RTL test
  `pinscope.test.tsx > 'starts and stops a RuntimePinObserver (R-20-02)'`
  is in the +128-line test delta of commit 98841a4.

### R-20-03 — §8.11 Shift+P / Shift+C wired end-to-end
- `grep -nE "'toggle-pins'|crosshair: |pinsVisible|crosshairEnabled"
  pinscope/src/runtime/PinScope.tsx` → both new state cells (L164/L165),
  both new handler entries (L304 `'toggle-pins':`, L307 `crosshair:`),
  prop wiring (L329 `{pinsVisible && <PinBadges />}`, L330 `{pinsVisible &&
  <VoidBadges />}`, L335 `enabled={crosshairEnabled}`). **All DoD greps
  satisfied.**
- `grep -nE 'enabled' pinscope/src/runtime/components/Crosshair.tsx` →
  prop declaration (L17 `enabled?: boolean;`), default (L23 `enabled =
  true,`), disable-guard disjunct (L43 `if (measuring || hudHidden ||
  !enabled) return null;`). The 3 existing disable conditions are preserved
  verbatim; only a 4th `!enabled` disjunct added — **AC-035 untouched**
  (`controls.test.tsx` AC-035 cases still PASS in ac-results-R20).
- Plan listed `PinBadges.tsx` as a third file; executor instead gated
  `<PinBadges/>` at the parent (`{pinsVisible && <PinBadges/>}`). The DoD
  text says "checks the behavior, not the mechanism" — the Shift+P
  observable (both badge layers hide together) is preserved. **DoD
  satisfied via alternate-mechanism clause.**
- §8.11 functional ratio in the shipping HUD: 11/13 → 13/13 (clears the
  §16 P2-DoD ≥0.95 threshold).

### R-20-04 — §10-E annotation flow: investigation, refuted-for-this-loop
- `git show --stat 98841a4` (and `git diff --stat`) → **0 src/ files
  changed attributable to R-20-04**. DoD's "0 files changed under
  `pinscope/src/`" satisfied.
- Re-executed the resolution-evidence greps independently:
  - `grep -rn 'annotation' pinscope/src/runtime/` → **1 hit only**
    (`parsers/operation-builder.ts:94: operation.annotation = parsed.topic`);
    no `request_type:'annotation'` producer anywhere.
  - `grep -rnE 'request_type|captureScreenshot' pinscope/src/runtime/` →
    only `request_type: 'operation'` (L52) and `'diagnostic'` (L93) in
    `operation-builder.ts`; `captureScreenshot` defined in
    `utils/screenshot.ts:14` with **no `src/runtime/` caller**.
  - Glob `pinscope/src/runtime/**/*Modal*` → **no matches**.
  - `grep -niE 'annotation|request_type' pinscope/convergence/ac-matrix.json`
    independently confirms **no Appendix-A AC** names the §10-E flow.
- Conclusion: §10-E is non-normative; the `### Resolution` block is the
  authoritative closing record. **DoD's refuted-branch satisfied.**

### R-20-05 — two CommandBar Enter-path tests (snapshot / measure)
- `grep -n 'R-20-05' pinscope/tests/unit/runtime/controls.test.tsx` →
  2 new `it(...)` cases at L253 (snapshot-kind) and L278 (measure-kind),
  both labelled `(R-20-05)`.
- `git diff --stat tests/unit/runtime/controls.test.tsx` → **+51, -0**
  (matches the orchestrator's claim).
- `git log 91eb6f0..HEAD -- pinscope/src/runtime/components/CommandBar.tsx`
  → **empty** (no commit in window touches it). `git diff --stat
  pinscope/src/runtime/components/CommandBar.tsx` → **empty**. **DoD's
  byte-for-byte-unchanged clause satisfied.**
- Re-read `CommandBar.tsx:46-53`: `isLocalOnlyCommand` three-way
  disjunction `kind === 'select' || kind === 'measure' || kind ===
  'snapshot'` intact; the previously-unexercised `measure`/`snapshot`
  arms now have explicit valid-input coverage in `controls.test.tsx`.
- AC-050 verdict in `ac-results-R20.json` is `40 AC-050 tests pass`
  (`controls.test.tsx` is the AC-050 anchor) — green with the two new
  cases included.

---

## Rejected claims

**None.** Every R-item's pre-written DoD is met on disk by independent
re-check. No closure is fabricated, no test is hollow, no DoD clause is
unmet.

---

## Regressions

Two previously-`CLOSED` ACs now fail in `ac-results-R20.json`. Per
ps-verifier role STEP 5, both are reported as regressions (`regression:
true`, severity raised to P1 each). Root-cause analysis of each:

### AC-090 — `1/7 AC-090 tests failed`
- **Loop status:** `CLOSED` round 4, `last_verified_round: 20`.
- **Re-ran independently:** `npx vitest run tests/unit/deployment.test.ts`
  → 9 pass / 1 fail. Failing test: `dynamically imports each built entry
  point`. Failure message:
  `Failed to load url /C:/Users/%D7%93%D7%95%D7%93%D7%90%D7%9C%D7%9E%D7%95%D7%A2%D7%9C%D7%9D/...
  /APEX/pinscope/dist/index.js (resolved id: ...). Does the file exist?`
- **`pinscope/dist/index.js` does exist** (verified with `ls`); the
  failure is Vite's `loadAndTransform` URL-decoder failing on the
  percent-encoded Hebrew path. The other 9 `deployment.test.ts` AC-090
  cases (those that do NOT use `import()`) pass.
- **Verdict:** **Env-host bug** (Vitest+Vite dynamic-import on a Hebrew
  Windows path) — NOT an implementation regression. The PinScope dist
  artifact is correct; AC-090's intent (`package export map valid`) is
  9/10 satisfied; only the dynamic-`import()` sub-case is impossible to
  run on this host. The commit message of 98841a4 also notes this is
  pre-existing across multiple rounds.
- **Disposition:** flagged as a regression per the contract, but noted
  for R21 as `AC-090-env-host-bug` for a `BLOCKED` reclassification (env:
  `unicode-safe-path`) rather than a fix-and-close.

### AC-104 — `1 matches < 2`
- **Loop status:** `CLOSED` round 1, `last_verified_round: 20`.
- **Matrix verify recipe (re-read from `ac-matrix.json`):**
  `{ "kind": "grep", "pattern": "pinscope", "paths": ["framework/agents/architect.md",
  "framework/agents/specialist/frontend.md"], "min_count": 2 }`.
- **Independent path check:**
  - `framework/agents/architect.md` → **exists, contains "pinscope"**
    (1 match).
  - `framework/agents/specialist/frontend.md` → **does NOT exist on
    disk**. The path was renamed by commit `6942038 fix(apex): R5-001 —
    module ecosystem manifest-driven layout` (2026-05-06) — the agent
    moved to `framework/modules/apex-frontend/agent.md`. `git log --all
    -- framework/agents/specialist/frontend.md` confirms the file's last
    surviving revision was at that earlier commit.
  - `framework/modules/apex-frontend/agent.md` → **exists, contains
    "pinscope"** (Grep confirmed).
- **Verdict:** **Stale-matrix-path** — NOT an implementation regression.
  The witness-of-intent for AC-104 ("PinScope is mentioned in the
  architect AND the frontend specialist agent") IS satisfied at the new
  module-ecosystem path; the AC's underlying contract content has not
  decayed. The matrix recipe simply still encodes the pre-R5-001 layout.
- **Disposition:** flagged as a regression per the contract, but noted
  for R21 as `stale-matrix-path-for-AC-104` for a matrix-path update
  (matrix authorship is outside this verifier's write surface), not a
  framework re-edit.

### MANUAL / UNAVAILABLE entries
- **AC-106 (`MANUAL`):** `loop.json` records `BLOCKED` (`apex-install`).
  ps-verifier never closes a manual-kind AC by proxy. This is
  `MANUAL_PENDING`, **not a regression** — it was never `PASS` in any
  prior round on this host either (env: `apex-install` is `false` in
  `loop.json.env_capabilities`).
- **AC-023 / AC-030 / AC-061 / AC-063 / AC-082 / AC-083
  (`UNAVAILABLE`):** all `BLOCKED` in `loop.json` (`blocked_reason:
  browser`). Env capability `browser` is `false`. **Not regressions** —
  environmental deferrals, not behavioral failures. Each retains its
  `BLOCKED` status correctly.

---

## Harness integrity

Independent checks against `ac-results-R20.json.harness_ok` and
`harness.skip_markers`:

- **`harness_ok === true`** in `ac-results-R20.json` — confirmed. No
  HARNESS_ERROR exit.
- **Skip-marker count:** independently re-counted —
  `grep -rEoh '\.(skip|only|todo)\b|\bxit\(|\bxdescribe\(' pinscope/tests/
  | wc -l` → **0**. Matches `ac-results-R20.json.harness.skip_markers ===
  0`. **No tests were skipped to dodge a failure.**
- **Config diff `91eb6f0..HEAD`:**
  - `pinscope/vitest.config*` → **no changes in window**.
  - `pinscope/tsconfig*` → **no changes in window**.
  - `pinscope/package.json` → only `version: "0.0.0" → "1.0.0"` (release
    bump, commit `7aaa6ce`) and a JSON pretty-format of the size-limit
    `ignore: ["react","react-dom"]` array. **`size-limit` budget
    `"80 KB"` is BYTE-FOR-BYTE UNCHANGED. No test glob narrowed. No
    threshold loosened.**
- **Mutation report (`mutation-R20.json`):** files mutated this round —
  `pinscope/src/runtime/PinScope.tsx` (5 mutants run, 5 killed) and
  `pinscope/src/runtime/components/Crosshair.tsx` (5 mutants run, 5
  killed). **Total: 10 run / 10 killed / 0 survived.** Zero hollow-test
  findings. The previous-round R18 `or-to-and` mutant on
  `CommandBar.tsx:49` is not in the R20 mutation set (file untouched
  this round), but R-20-05's two new test cases independently exercise
  the previously-unexercised `measure`/`snapshot` arms of that
  disjunction — which would kill the R18 mutant if re-tested.

**No harness findings.**

---

## Rendering Gap

`git log 91eb6f0..HEAD --oneline` (R20-base = `91eb6f0 merge(pinscope):
land PinScope product + /ps-heal agents`):

```
a12a7c3 feat(self-heal): Followup #4 — adopt Doctrine 3 (BLOCKED status)
7aaa6ce chore(pinscope): bump to 1.0.0 (first npm release; PS-R20 included)
98841a4 feat(pinscope): PS-R20 W1-3 — execute R-20-01/02/03 (HUD integration)
28a94d0 docs(pinscope): P8 — scope reconciliation + Decision Record
fcf0afd docs(self-heal): P6 — catalog 5 /ps-heal doctrines as adoption backlog
a776b95 feat(pinscope): P5 IMP-PS-01/02 — visibility of PinScope in /apex:start and /apex:onboard
```

**6 commits in window. Non-empty.** Round is not hallucinated.

Commit `98841a4` (`git show --stat`) lands the R-20-01/02/03 wave:
`pinscope/src/runtime/PinScope.tsx +51 / -0`,
`pinscope/src/runtime/components/Crosshair.tsx +12 / -0`,
`pinscope/tests/unit/runtime/pinscope.test.tsx +128 / -0`.
Working-tree (uncommitted) additions for R-20-05:
`pinscope/tests/unit/runtime/controls.test.tsx +51 / -0` — present on
disk and exercised by the AC-050 vitest-tag run (40 tests pass; the two
R-20-05 cases are inside that count). R-20-04 is investigation-only:
no commit, no working-tree src/ delta — exactly as the DoD's
refuted-branch requires.

**Rendering Gap: clean.**

---

## Notes for R21

Carry these into the R21 audit / planner as **non-blocking** items
(none alters the convergence verdict; each is a known-cause R20 residue):

1. **`stale-matrix-path-for-AC-104`** — `ac-matrix.json`'s AC-104 verify
   recipe still names `framework/agents/specialist/frontend.md`, but the
   agent moved to `framework/modules/apex-frontend/agent.md` in commit
   `6942038` (2026-05-06). The AC's witness-of-intent (PinScope is named
   in the architect + frontend specialist agents) IS still satisfied,
   just at the new path. R21 should either (a) update the matrix path,
   or (b) widen the recipe (glob both locations). Matrix authorship is
   outside this verifier's write surface.

2. **`AC-090-env-host-bug`** — `tests/unit/deployment.test.ts` AC-090's
   `dynamically imports each built entry point` case fails on this host
   because Vitest+Vite's `loadAndTransform` cannot URL-decode the
   percent-encoded Hebrew chars in the path
   (`%D7%93%D7%95%D7%93%D7%90%D7%9C%D7%9E%D7%95%D7%A2%D7%9C%D7%9D`).
   The `dist/index.js` artifact exists and is correct; the other 9
   `deployment.test.ts` AC-090 cases PASS. R21 should reclassify this
   sub-case as `BLOCKED` (env: `unicode-safe-path`) rather than treat it
   as a code defect — the implementation is not regressed.

3. **`AC-106-still-MANUAL-PENDING`** — `/apex:health-check` needs APEX
   synced to `~/.claude/` (env capability `apex-install: false`). The
   `MANUAL` verdict is correct; the AC remains `BLOCKED` until an
   APEX-installed CI environment is available. Never closed by proxy.

4. **`framework-sync-gap-blocking-pinscope-skill`** — related to (3): the
   `apex-install` env capability has been `false` for the entire R10–R20
   window, blocking AC-106 from converging via the standard automated
   path. R21 might consider whether the `ps-heal` doctrine adoption
   work (commits `a12a7c3`, `fcf0afd`) opens a path to running
   `/apex:health-check` against a synced `~/.claude/` snapshot in CI.

---

**End of VERIFY-R20.md.**
