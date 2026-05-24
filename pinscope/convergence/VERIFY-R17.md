# VERIFY-R17 — Clean-Room Verification (PS-R17, STEP 6)

**Verdict:** `PASS`

Round 17 closed three residual seam gaps (R-17-01, R-17-02, R-17-03). All three
claimed closures independently re-confirmed; zero rejected claims, zero
regressions, zero harness findings, non-empty commit window. The loop converges
into R18 re-audit.

---

## Confirmed closures

### R-17-01 — `select e_N` command routes through the canonical SelectionManager (F-17-01, P2)
- **Named DoD test passes.** Re-ran `npx vitest run tests/unit/runtime/selection.test.tsx`
  → `7 passed (7)`, including `it('the \`select e_N\` command locks the InfoPanel')`
  (selection.test.tsx:102). The test mounts the real `<PinScope/>`, submits
  `select e_2`, and asserts the InfoPanel `[data-testid="pin-id"]` reflects `e_2`
  with no prior `[data-pin]` click. The flow-B regression guard
  `a [data-pin] click still locks the InfoPanel` (selection.test.tsx:131) also passes.
- **DoD clause 3 — grep predicates.** `grep -rn 'new SelectionManager' src` → exactly
  one match (`useSelectedElement.ts:43`, lazy `managerRef` init).
  `grep -rn 'command\.selection' src/runtime/PinScope.tsx` → 0 matches (exit 1).
  All five acceptance-criteria greps re-verified true.
- **DoD clause 2 — no regression.** Full suite green (see Harness section).
- Code re-read: `onSubmit`'s `select` branch calls the hook-exposed `selectPin`
  (PinScope.tsx:184); `useSelectedElement` exposes `select` on the interface
  (line 17) and return (line 100). The orphan `command.selection` instance is gone.

### R-17-02 — Flow-D snapshot persist failure surfaced, never swallowed (F-17-02, SUSPECTED, P2)
- **STEP-1 confirm reasoning sound, branch correct.** The SUSPECTED finding was
  recorded CONFIRM. Independently verified the pre-fix state was a genuine gap:
  pre-fix `onSnapshot` had no `flush()` (now `grep -n 'flush' src/runtime/PinScope.tsx`
  → 4 matches, operative `flush().catch` at line 158). The chosen branch
  (proceed-to-fix, not `### Resolution`) is correct — the finding was real.
- **Named DoD test passes.** Re-ran `npx vitest run tests/unit/runtime/flow-wiring.test.tsx`
  → `4 passed (4)`, including `it('Flow D — a failed snapshot persist is surfaced,
  never swallowed')` (flow-wiring.test.tsx:137). The test stubs `fetch` to a
  `{ok:false,status:500}` response, spies `console.warn`, registers an
  `unhandledrejection` listener, and asserts a `[pinscope]`-prefixed snapshot
  failure warn fired AND zero unhandled rejections escaped.
- **DoD clause 3.** `git diff` of `src/runtime/managers/EndpointSnapshotStore.ts`
  across the round window (4175916→HEAD) is empty — store error semantics unchanged.

### R-17-03 — StatePanel override lifted so TopBar reflects live state (F-17-03, SUSPECTED, P3)
- **STEP-1 confirm reasoning sound, branch correct.** SUSPECTED finding recorded
  CONFIRM. Independently verified: pre-fix `stateOverride={null}` was a hardcoded
  literal (`grep -n 'stateOverride={null}'` now → 0 matches, exit 1; replaced by a
  `useState<StateOverride>` at PinScope.tsx:130, bound at line 261). Chosen branch
  (proceed-to-fix) is correct.
- **Named DoD test passes.** Re-ran `npx vitest run tests/unit/runtime/controls.test.tsx`
  → `16 passed (16)`, including `it('TopBar reflects the live StatePanel override')`
  (controls.test.tsx:68). The test mounts the real `<PinScope/>`, clicks
  `[data-state-btn="hover"]`, and asserts the TopBar `[data-field="state"]` span
  text contains `hover` and not `none`.
- **AC-037 advisory resolved.** The R-17-03 test genuinely exercises the now-live
  **non-null** `stateOverride` branch of `TopBar` (asserts `state` field shows
  `hover`). The carried-over AC-037 TEST-AUDIT-R17 advisory ("the non-null
  `stateOverride` branch is never exercised") is resolved as claimed. The existing
  AC-037 (`stateOverride={null}`) and AC-040 StatePanel tests still pass in the
  same file.
- **DoD clause 3.** `git diff` of `src/runtime/components/TopBar.tsx` across the
  round window is empty — `TopBar.tsx` untouched, per the preservation directive.
- `StatePanel` gained `onStateChange?:(state:StateOverride)=>void` (StatePanel.tsx:98),
  destructured (line 101), invoked in `choose` (line 107). The §8.8
  `applyStateOverride` `<html data-state-override>` write is byte-for-byte preserved.

---

## Rejected claims

None. All three R-item closures re-confirmed.

---

## Mutation check (STEP 3)

`mutation-R17.json`: 12 mutants, 11 killed, **1 survived**.

- Survivor **M1** — `or-to-and` at `src/runtime/hooks/useSelectedElement.ts:24`:
  `if (!pinId || typeof document === 'undefined')` →
  `if (!pinId && typeof document === 'undefined')` inside `resolveSelected`.
- **Assessment: coverage finding, NOT a rejection.** The R-17-01 DoD test calls
  `select('e_2')` with a non-null `pinId` in a defined-document (happy-dom) env.
  Both original and mutated predicate evaluate to `false` for that input — the
  function proceeds identically and the load-bearing DoD assertion (InfoPanel
  locks onto `e_2`, `pinIdLabel.textContent` contains `e_2`) is unaffected. The
  mutant only diverges when exactly one operand is true (null `pinId` XOR
  undefined `document`) — the SSR / null-pin guard margin, which carries no
  R-17-01 DoD assertion. Per STEP 3, a survivor in an un-asserted margin is
  reported as a coverage finding and does **not** by itself reject the claim.
- Recommendation for R18: add a `resolveSelected(null)`-returns-null /
  SSR-guard test to kill M1. Advisory, non-blocking.
- `PinScope.tsx` (5/5) and `StatePanel.tsx` (5/5) — all mutants killed.

---

## Regressions (STEP 5)

None. All 62 ACs marked `CLOSED` in `loop.json` show `PASS` in `ac-results-R17.json`.
The 7 `BLOCKED` ACs (AC-023, -030, -061, -063, -082, -083 browser; AC-106
apex-install) show `UNAVAILABLE` — environment-blocked, not findings, consistent
with their `loop.json` status. Provenance spot-check: every `CLOSED` AC carries a
`provenance` block (`verify` kind + `closed_round: 17`) — no unverifiable closure.

---

## Harness integrity (STEP 4)

- **`ac-verify` harness OK.** `ac-results-R17.json` `harness_ok: true`; no
  HARNESS_ERROR exit.
- **Skip-count delta: 0.** `grep -rEn '(it|test|describe)\.(skip|only|todo)' tests/`
  → 0. Matches `ac-results-R17.json` `harness.skip_markers: 0`. No test skipped,
  `.only`-ed, or `.todo`-ed this round. (Wave-3 RESULT's "15 skipped" was an
  artifact of a `-t` name filter during its targeted run; a full-file run of
  `controls.test.tsx` shows `16 passed (16)`, 0 skipped.)
- **Config diff: clean.** `git diff 9e5878c..HEAD` over `vitest.config.ts`,
  `playwright.config.ts`, `package.json`, `tsconfig.json` → empty. No loosened
  threshold, disabled check, or narrowed glob.
- **Full suite re-run:** `cd pinscope && npx vitest run` → `Test Files 29 passed (29)`.
  `npx tsc --noEmit` → exit 0. Preservation-list files (`SelectionManager.ts`,
  `EndpointSnapshotStore.ts`, `TopBar.tsx`) confirmed unchanged across the round
  window via `git diff --stat`. No edit to `pinscope/SPEC.md` (frozen).

---

## Rendering Gap (STEP 6)

Commit window non-empty — **3 real wave commits** back the claimed closures:

- `0919b29` — `fix(pinscope): R-17-W1 — route select e_N command through canonical SelectionManager so InfoPanel locks` (Wave 1)
- `5fb7877` — `fix(pinscope): R-17-W2 — observe snapshot persist failure in flow D, never swallow` (Wave 2)
- `c05d4f6` — `fix(pinscope): R-17-W3 — lift StatePanel override so TopBar shows the live state` (Wave 3)

All three confirmed via `git log`. No closure on paper without a commit behind it.

---

## Summary

`PASS` — 3/3 claimed closures re-confirmed independently, 0 rejected, 0
regressions, 0 harness findings, 3-commit window. One mutation survivor (M1,
`useSelectedElement.ts:24`) reported as a non-blocking coverage finding for R18.
The two SUSPECTED findings (R-17-02, R-17-03) were correctly CONFIRMED with sound
STEP-1 reasoning. The AC-037 TEST-AUDIT advisory is resolved. R18 may proceed to
the convergence re-audit.
