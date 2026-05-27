# Remediation Plan — PS-R26

**Generated:** 2026-05-27
**Round:** 26 (post-CONVERGED confirmation; loop_status flipped to IN_PROGRESS by record-round)
**Author:** orchestrator (after three `ps-remediation-planner` precondition-equivalent inputs were already on disk; the planner's auditor-side inputs are `audit-findings-R26.json`, `narrative-scan-R26.json`, `TEST-AUDIT-R26.md`).
**Style:** `framework/docs/REMEDIATION-STYLE.md` — content-addressable anchors only; no raw line numbers in plan bodies.

## Scope

| ID | Linked finding(s) | Severity | Disposition |
|---|---|---|---|
| **R-26-01** | F-26-01 (CONFIRMED P1) · NC-12-06 (blocking) · TEST-AUDIT-R26 AC-061 FAIL | P1 | **In scope — this round** |
| **R-26-02** | F-26-03 (SUSPECTED P3) | P3 | **In scope — this round** (trivial fix; pairs with R-26-01's narrative/spec-anchor cleanup) |
| — | F-26-02 (SUSPECTED P3) — §15 vs §18 I-1 design tension | P3 | **Deferred — human triage required** (SPEC bump vs code expansion is not an auto-remediable decision; ST-26-01 logged in narrative-scan-R26) |

R-26-01 and R-26-02 are independent (different files, different test surfaces); both are eligible for the same wave.

---

## Remediation R-26-01

**Linked finding:** F-26-01 (CONFIRMED P1) · NC-12-06 (uncovered_unsatisfied, blocking) · TEST-AUDIT-R26 AC-061 false-PASS class-4.
**Severity:** P1
**Spec anchor:** "iframes (same-origin inject, cross-origin outline only)" (SPEC §12, Edge Cases).
**Root cause (one line):** `markCrossOriginFrames` is non-idempotent — every invocation unconditionally appends a fresh overlay div per cross-origin frame, and the `MutationObserver` on `document.body` re-fires the helper on every body mutation (including the helper's own `appendChild`), producing an unbounded duplicate-overlay leak + observer feedback loop. The R24 closure of NF-23-01 verified wiring existence, not correctness; AC-061's tests only invoke the helper once per case, so the defect cannot surface from green tests.

### Ecosystem analysis (10-question gate)

1. **What spec contract does this fix restore?** SPEC §12 "iframes (same-origin inject, cross-origin outline only)" — "outline only" is a per-frame *exactly-one outline* invariant, not "at least one." Idempotency is implicit in the prose.
2. **What other contract could the fix accidentally break?** Same-origin frames must stay untouched (no `data-pin-iframe`, no overlay). The label sourcing (`data-pin` attr first, then host of `frame.src`) must remain unchanged. The `Z_SELECTED` z-index and `pointer-events: none` must remain.
3. **What consumers of `markCrossOriginFrames` exist today?** Two: (a) the cross-origin-iframe `useEffect` in `PinScope.tsx` (initial sweep + `MutationObserver` re-sweep on body mutations), (b) the unit-test file `pinscope/tests/unit/runtime/iframe-overlay.test.ts`. The fix MUST not change the signature `(root?: ParentNode) => number`.
4. **Does the helper own its DOM state, or is the caller responsible for cleanup?** Today the helper *adds* overlays but never *removes* them. The R24 wiring assumed each invocation produced the correct snapshot — which only holds if the helper itself reconciles. Making the helper the owner of its overlay set is the smallest correct change.
5. **What test missing today would prove the fix?** A test that calls `markCrossOriginFrames(document)` twice on the same DOM with a single cross-origin frame appended, and asserts `[data-pinscope-iframe-overlay]` count stays at 1. This is SP-26-01 from `narrative-scan-R26.md`.
6. **What mutation gate proves the test detects the bug?** Remove the reconciliation line in the fix; the new test goes RED (count==2).
7. **Could the fix introduce a flicker?** The reconcile-then-rebuild sequence deletes all overlays before rebuilding. On a hot page with active mutations, callers might observe a single frame with no overlay. Same-tick rebuild keeps the gap below 1 paint frame, so practical visibility is nil; the alternative (per-frame dedupe via `pinId`) is more complex and not warranted for a P1 fix.
8. **Does the fix interact with the `markShadowHosts` adjacent useEffect?** No — they share the `MutationObserver`-driven re-sweep pattern but operate on disjoint DOM (iframes vs shadow hosts). Same-pattern fixes can be templated later if `markShadowHosts` exhibits the same flaw (not in scope this round).
9. **Does the fix touch any BLOCKED-env (browser-only) AC?** AC-061 itself is `manual+BLOCKED` because the cross-origin invariant needs two real origins. The fix passes the existing jsdom-based unit tests; AC-061 in matrix remains MANUAL+BLOCKED — the new regression test is tagged AC-061 (vitest-tag), strengthening AC-061's matrix recipe to cover the idempotency invariant that doesn't need two origins.
10. **Does this round invalidate any prior CLOSED AC?** Only AC-061's idempotency aspect — and AC-061 was MANUAL+BLOCKED, so no monotonicity violation. `record-round` already accepted R26 without a regression-guard trip, confirming no other CLOSED AC is at risk.

### Execution plan

**Files to modify:**
- `pinscope/src/runtime/utils/iframe-overlay.ts` — the body of `export function markCrossOriginFrames(root: ParentNode = document): number`. Add a reconciliation pass at the top of the function body, before the existing `for (const frame of …)` loop.
- `pinscope/tests/unit/runtime/iframe-overlay.test.ts` — append a new `it(…)` case to the `describe('Cross-origin iframe overlay (AC-061)', …)` block.

**Files to create:** none.

**Files that MUST remain untouched:**
- `pinscope/src/runtime/PinScope.tsx` — the cross-origin-iframe `useEffect` block (anchored on the comment `R-24-01 — §12 / AC-061 cross-origin iframe outline. Restored from`). The fix lives inside the helper; the caller's wiring stays intact. Do NOT add additional debounce/throttle logic in the caller — the helper's idempotency is sufficient.
- `pinscope/src/runtime/utils/iframe-overlay.ts` — the `isCrossOriginFrame` function and the `IFRAME_ATTR` / `IFRAME_OVERLAY_ATTR` constants. Only the body of `markCrossOriginFrames` changes.
- The 8 existing tests inside `describe('Cross-origin iframe overlay (AC-061)', …)`. The fix appends a 9th test; it does not modify any existing test.

**Order of operations:**
1. **Test-first.** Append the new `it('AC-061 / NC-12-06 — idempotent under repeated invocation (R-26-01)', …)` case to `iframe-overlay.test.ts`. The test creates a single cross-origin iframe (via `makeCrossOrigin(frame, 'throw')`), appends it to `document.body`, calls `markCrossOriginFrames(document)` twice on the same DOM, then asserts `document.querySelectorAll('[data-pinscope-iframe-overlay]').length === 1` AND `frame.hasAttribute('data-pin-iframe')` AND the overlay's `textContent` still contains the original label. Confirm vitest goes RED on this test against current code.
2. **Implement.** Inside `markCrossOriginFrames`, before the existing `for` loop, run a reconciliation pass: query `root.ownerDocument ?? document` for `[data-pinscope-iframe-overlay]` and remove each one. Use `Array.from()` on the NodeList before iterating to avoid live-collection mutation hazards. Then run the existing sweep unchanged. (The same-origin-frames "untouched" contract is preserved because the existing loop already `continue`s on `!isCrossOriginFrame(frame)`.)
3. **Confirm.** Re-run vitest — the new test goes GREEN; all 8 prior tests still GREEN.
4. **Mutation gate.** Comment out the reconciliation pass; new test goes RED (count==2). Restore.

**Rollback trigger:** Any of: the new test still RED after the fix; any of the 8 prior AC-061 tests goes RED; `npx vitest run` fails on any file outside `iframe-overlay.test.ts`. Roll back via `git checkout pinscope/src/runtime/utils/iframe-overlay.ts pinscope/tests/unit/runtime/iframe-overlay.test.ts`.

### Acceptance criteria (Definition of Done)

- [ ] `grep -c 'querySelectorAll.*data-pinscope-iframe-overlay' pinscope/src/runtime/utils/iframe-overlay.ts` ≥ 1 (the reconciliation query exists in source).
- [ ] `grep -n 'idempotent under repeated invocation' pinscope/tests/unit/runtime/iframe-overlay.test.ts` returns a line in the new test (the new case exists).
- [ ] `cd pinscope && npx vitest run tests/unit/runtime/iframe-overlay.test.ts --reporter=dot` exits 0 with 9 tests passing.
- [ ] `cd pinscope && npx vitest run --reporter=dot` exits 0 with ≥ 382 tests passing (one more than R25's 381).
- [ ] `node pinscope/convergence/lib/ac-verify.mjs --round 26 2>&1 | grep 'PASS'` shows ≥ 62 PASS (no AC regresses).
- [ ] Mutation gate: removing the reconciliation pass and re-running the new test produces a RED outcome with assertion message naming `data-pinscope-iframe-overlay` count `expected 1, received 2`.

### Dependencies

- None within R26. R-26-01 and R-26-02 modify disjoint files (`utils/iframe-overlay.ts` + test vs `src/index.ts` + `src/runtime/constants.ts`).

### Risk assessment

- **Low.** The helper's signature and same-origin contract are preserved; the change is purely additive (one reconciliation pass before the existing loop). The new regression test fires only on repeated invocation, which is the precise defect class.
- **Test surface widening:** the new test adds 1 case to AC-061's `vitest-tag` count. The `ac-matrix` entry for AC-061 currently has `verify.kind === 'manual'` — the new test does NOT change matrix verification because AC-061 is still MANUAL+BLOCKED in the env-browser column. The new test strengthens NC-12-06's narrative coverage and serves as the mutation gate; matrix verification remains environment-bound.
- **No build/sync impact:** PinScope is a standalone npm package; no `~/.claude/` delivery surface is touched.

---

## Remediation R-26-02

**Linked finding:** F-26-03 (SUSPECTED P3).
**Severity:** P3
**Spec anchor:** SPEC §15 "Deployment & Integration" (single-block section, no §15.5) and SPEC §12 "Edge Cases" (single-block section, no §12.6).
**Root cause (one line):** Two production-code doc comments link to non-existent SPEC subsections (`§15.5` in `pinscope/src/index.ts`, `§12.6` in `pinscope/src/runtime/constants.ts`). Readers following the citations land at the parent section but find no matching sub-anchor.

### Ecosystem analysis (10-question gate)

1. **What spec contract does this fix restore?** None at the runtime level — SPEC narrative integrity for code readers.
2. **What other contract could the fix accidentally break?** None. Doc-comment edits are pure metadata.
3. **What consumers exist?** Only IDE tooltips and humans reading source. No tests assert these strings; no runtime path consumes them.
4. **Could the fix introduce drift in the other direction?** No — the parent sections `§15` and `§12` are stable, FROZEN narrative blocks. Pointing at the parent is the safer choice.
5. **Why not re-number the SPEC instead?** SPEC is FROZEN (north_star_version 2.0.0). The loop never edits the SPEC.
6. **Are there other section references in src/?** Yes — `grep` for `§9\.[0-9]+|§10-[A-Z]|§11|§12|§13|§14|§15|§16|§17|§18` finds 23 other references; all but the two named here resolve to existing sections / subsections.
7. **Does this fix interact with R-26-01?** No — different files.
8. **Does this fix touch tests?** No.
9. **Does the change need a comment for why this is "right"?** No — the fix replaces an incorrect anchor with a correct one; the original intent is preserved.
10. **Could this be deferred?** Yes, but it pairs naturally with R-26-01's audit-coverage round and is cheap. Deferring would require a future round to re-discover the same drift.

### Execution plan

**Files to modify:**
- `pinscope/src/index.ts` — the file's first doc comment (anchored on `/** PinScope public API` text). Change `§15.5` to `§15`.
- `pinscope/src/runtime/constants.ts` — the doc comment introducing `Z_SELECTED` (anchored on `/** Reserved z-index range` text). Change `§12.6 (max 32-bit signed int)` to `§12 (max 32-bit signed int)`.

**Files to create:** none.

**Files that MUST remain untouched:**
- All test files. The fix is metadata-only and must not change any test.
- All other doc comments referencing SPEC sections. Only the two stale `.NN` anchors change.

**Order of operations:**
1. Edit `pinscope/src/index.ts` first comment, replacing `§15.5` with `§15`.
2. Edit `pinscope/src/runtime/constants.ts` `Z_SELECTED` comment, replacing `§12.6` with `§12`.
3. Run `cd pinscope && npx tsc --noEmit` — TypeScript pass.
4. Run `cd pinscope && npx vitest run --reporter=dot` — full suite stays GREEN.

**Rollback trigger:** Either tsc fails (it cannot; the change is in comments) or vitest regresses (it cannot; no test asserts these strings).

### Acceptance criteria (Definition of Done)

- [ ] `grep -c '§15\.5' pinscope/src/index.ts` returns 0.
- [ ] `grep -c '§12\.6' pinscope/src/runtime/constants.ts` returns 0.
- [ ] `grep -c '§15' pinscope/src/index.ts` returns ≥ 1 (the corrected reference remains).
- [ ] `grep -c '§12' pinscope/src/runtime/constants.ts` returns ≥ 1.
- [ ] `cd pinscope && npx tsc --noEmit` exits 0.
- [ ] `cd pinscope && npx vitest run --reporter=dot` exits 0 with the same test count as after R-26-01 lands.

### Dependencies

- None. Independent of R-26-01.

### Risk assessment

- **Effectively zero.** Comment-only changes; no test assertions depend on these strings; no runtime path reads them.

---

## Out-of-scope this round

### F-26-02 — SPEC §15 vs §18 I-1 design tension (SUSPECTED P3)

`withPinScope` and `PinScopeWebpackPlugin` return valid config objects but never register the AST transformer. SPEC §15 lists them as integration entry points; SPEC §18 I-1 explicitly narrows the matrix ACs to "importable and return valid config objects." AC-092 PASSes per the narrow text.

This is a **SPEC design tension** that needs a human decision:
- **Option A** — accept the narrow scope: leave the code as-is; this is documented behavior per §18 I-1.
- **Option B** — widen the AC matrix: mint AC-09x covering end-to-end Next.js injection; the SPEC bump unblocks the loader work.
- **Option C** — register the loader anyway: implement the dev-only loader hooks (the comments already say "a later round registers the data-pin loader here"); this is a small P4/P5 phase, not a remediation.

The convergence loop does NOT auto-pick between these. ST-26-01 in `narrative-scan-R26.md` is the durable record. R27 (if it runs before a human decision) should NOT re-raise F-26-02 unless code state changes.

---

## Conflict matrix

| File (or directory) | R-26-01 | R-26-02 |
|---|:---:|:---:|
| `pinscope/src/runtime/utils/iframe-overlay.ts` | write | — |
| `pinscope/tests/unit/runtime/iframe-overlay.test.ts` | write | — |
| `pinscope/src/index.ts` | — | write |
| `pinscope/src/runtime/constants.ts` | — | write |

No file is written by both R-items. Both can run in the same wave with no intra-wave ordering needed.
