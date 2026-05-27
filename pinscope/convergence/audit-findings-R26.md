# PinScope PS-R26 — Confirmation Audit

**Status:** complete
**Round:** 26 (post-CONVERGED confirmation)
**ac-verify R26:** `62 PASS · 6 UNAVAILABLE · 1 MANUAL · 0 FAILs` · `harness_ok=true` · `skip_markers=0`
**Verdict:** **Loop is NOT confirmed converged.** 1 CONFIRMED P1 finding + 2 SUSPECTED P3 findings remain.

**Completion note.** Three successive `spec-auditor` sub-agent spawns each exhausted `maxTurns` mid-sweep. The orchestrator completed axes 3–12 inline with the user's explicit autonomy authorization (`מאשר לך לבצע עצמאית`, 2026-05-27). All investigation was read-only. F-26-01 was authored by the `spec-auditor` sub-agent before its turn-budget exhausted; F-26-02 and F-26-03 are orchestrator-authored. Clean-room isolation from the executor remains intact — no R26 executor has run.

## 12-Axis Sweep — Final Status

| # | Axis | Status | Result |
|---|---|---|---|
| 1 | Dormant mechanism | swept | 1 CONFIRMED (F-26-01) |
| 2 | Swallowed error | swept | clean — every catch site logs via `console.warn('[pinscope] …', cause)` or re-throws a typed error; no empty `catch {}` blocks |
| 3 | Hollow code | swept | 1 SUSPECTED (F-26-02 — `withPinScope` + `PinScopeWebpackPlugin`) |
| 4 | Broken end-to-end flow | swept | clean — SPEC §10 flows A/B/C/D/E traced end-to-end; CommandBar parse → `buildOperation` → `ClaudeBridge.send` → clipboard+history → toast; snapshot capture → `flush` → `/__pinscope/snapshot`; selection lock; all wired |
| 5 | Silent fallback | swept | clean — only one fallback: `PinMap.load` swallows `JSON.parse` error and warns, but the spec allows starting with an empty map on a corrupted file; documented behavior with an explicit `console.warn` |
| 6 | Configuration drift | swept | clean — `env-capabilities.json` probed at run-time; `ac-matrix` STRICT-locked at R25 W7; no permissive defaults masking invariants |
| 7 | Test-shaped contract | swept | clean — AC-092's narrow verify text is intentional per SPEC §18 I-1; `deployment.test.ts` adds composition + arg-passthrough + immutability + no-op-when-disabled tests beyond the matrix minimum |
| 8 | Vacuous true | swept | clean — sampled AC-090 / AC-091 / AC-092 (min_tests=1 ACs) all have substantive test bodies that assert behavior, not tautologies |
| 9 | Provenance gap | swept | clean — `loop.json` criteria ledger shows all 69 ACs with `last_verified_round=25`; vitest run shows 381 PASS in 32 files; no cited test missing |
| 10 | Spec/code drift | swept | 1 SUSPECTED (F-26-03 — stale §15.5 and §12.6 doc-comment references; sections do not exist as subsections in SPEC) |
| 11 | Hidden coupling | swept | 1 CONFIRMED — same as F-26-01 (MutationObserver-driven re-entrance into `markCrossOriginFrames` is hidden coupling between `PinScope.tsx` and `iframe-overlay.ts`) |
| 12 | Stale BLOCKED | swept | clean — 6 BLOCKED ACs all require `env:browser`; `env-capabilities.json` reports `browser:false`; blocks remain legitimate |

## Findings (re-confirmed AC FAILs)

**None.** `ac-verify R26` recorded `62 PASS · 6 UNAVAILABLE · 1 MANUAL · 0 FAILs` with `harness_ok=true` and `skip_markers=0`.

## Investigation Findings

### F-26-01 — `markCrossOriginFrames` + MutationObserver duplicate-overlay leak (CONFIRMED P1)

**Axes:** Dormant mechanism · Hidden coupling

**Current state.** `pinscope/src/runtime/PinScope.tsx` lines 238–252: `useEffect` installs a `MutationObserver` on `document.body` with `{subtree:true, childList:true}` whose callback is `() => markCrossOriginFrames(document)`. `pinscope/src/runtime/utils/iframe-overlay.ts` lines 31–66: the for-loop hits `frame.setAttribute(IFRAME_ATTR, …)` followed by overlay creation and `document.body.appendChild(overlay)` with **no** `if (frame.hasAttribute(IFRAME_ATTR)) continue` guard and **no** `document.querySelector('[data-pinscope-iframe-overlay][data-for="${pinId}"]')` dedupe.

**Gap.** SPEC §12 says cross-origin iframes get an outline-only treatment, not a stack of overlay divs. Because `appendChild` itself is a `childList` mutation under the observed root, every cross-origin iframe triggers re-entry: each body mutation produces one overlay per cross-origin iframe, and the `appendChild` mutation re-fires the observer, producing another. On a hot page this is an unbounded duplicate-overlay leak + observer feedback loop.

**Re-read evidence.** `grep -n 'hasAttribute' pinscope/src/runtime/utils/iframe-overlay.ts` → only line 70 (the `isIframeLimited` reader); no caller-side guard. The test suite `pinscope/tests/unit/runtime/iframe-overlay.test.ts` calls `markCrossOriginFrames` only once per case, so the duplicate-overlay defect is never exercised.

### F-26-02 — `withPinScope` / `PinScopeWebpackPlugin` hollow code (SUSPECTED P3)

**Axes:** Hollow code · Test-shaped contract

**Current state.** `pinscope/src/plugin/next.ts` `withPinScope()` returns a config with a `webpack(config, context)` hook that only composes any existing host webpack function — comment line 28 verbatim: `"Dev-only: a later round registers the data-pin loader here."` `pinscope/src/plugin/webpack.ts` `PinScopeWebpackPlugin.apply()` only does `void compiler.hooks` with comment line 25: `"Dev-only: a later round taps compiler.hooks to register the loader."` Neither integration registers the AST transformer; a Next.js or Webpack app using these gets zero `data-pin` injection at the build step.

**Gap.** SPEC §15 lists `withPinScope` and `PinScopeWebpackPlugin` as the Next.js / Webpack integration surface for the npm `pinscope` package. SPEC §18 I-1 narrows the AC matrix to "importable and return valid config objects" and explicitly scopes them P4/P5. AC-092 verifies structural shape (config object + webpack function + non-mutation + arg passthrough + no-op when disabled) — all PASS against the current stubs.

So the AC matrix is satisfied per its narrow text, but the §15 integration listing implies that "using `withPinScope` works" — which the code does not deliver. **Classified SUSPECTED, not CONFIRMED**, because §18 I-1 explicitly authorizes the narrow scope: this is a §15-vs-§18 design tension, not an unambiguous defect. A future SPEC bump or P5 phase would need to widen AC-092 (or add AC-09x) before the code is expected to do the full registration.

**Re-read evidence.** `pinscope/src/plugin/next.ts` (34 lines) read in full; `pinscope/src/plugin/webpack.ts` (28 lines) read in full; `pinscope/tests/unit/deployment.test.ts` lines 56–135 read — 6 tests for AC-092, all asserting structural shape, none asserts a transformer is invoked. SPEC §15 lines 375–381 lists the integration. SPEC §18 I-1 line 428 scopes the AC narrowly. Matrix `AC-092.verify` = `{kind:"vitest-tag", min_tests:1}`; current count is 6 tests (R-23-03 strengthening).

### F-26-03 — stale §15.5 / §12.6 doc-comment section references (SUSPECTED P3)

**Axes:** Spec/code drift

**Current state.** `pinscope/src/index.ts:1` doc comment is `/** PinScope public API — see SPEC.md §15.5. */` but SPEC §15 (Deployment & Integration) is a single subsection-free block — there is no §15.5. `pinscope/src/runtime/constants.ts:12` doc comment is `/** Reserved z-index range — see SPEC §12.6 (max 32-bit signed int). */` but SPEC §12 (Edge Cases) is also a single prose paragraph with no enumerated §12.1–§12.N subsections; the z-index `2147483647` is mentioned inline, not under a `§12.6` header.

**Gap.** Doc-comment links from production code point at non-existent SPEC subsections. Readers following the citation will find the parent section but no matching sub-anchor. Low-severity drift; does not affect runtime behavior or AC verification. Possibly stale from an earlier SPEC version that had subsection numbering. The first-priority remediation is to either (a) re-number the SPEC to give §15 and §12 the subsections the code references — but SPEC is FROZEN; or (b) update the code comments to drop the `.NN` suffix and point at the parent section.

**Re-read evidence.** `grep '§9\.[0-9]+|§10-[A-Z]|§11|§12|§13|§14|§15|§16|§17|§18' pinscope/src` → 25 hits; `§15.5` appears once (`src/index.ts:1`), `§12.6` appears once (`src/runtime/constants.ts:12`). `grep '^### [0-9]+\.[0-9]+' pinscope/SPEC.md` → §15 has no subsections in the section heading list; §12 has no subsections. All other section references in production code (§6.1, §9.1, §9.2, §9.3, §10-A through §10-E, §11, §12) resolve cleanly.

## BLOCKED list (unchanged from R25)

| AC | Reason |
|---|---|
| AC-023 | env browser |
| AC-030 | env browser |
| AC-061 | env browser — manual: cross-origin iframe needs two real origins |
| AC-063 | env browser — manual: `@media print` needs a browser print engine |
| AC-082 | env browser — manual: Playwright integration suite needs a browser binary |
| AC-083 | env browser — manual: visual-regression screenshots need a browser |

## Coverage Ledger
**Axes swept:** all 12.
**Sections reviewed:** §6.1, §6.3, §7.1, §7.2, §8.10, §9.1, §9.2, §9.3, §9.4, §10-A, §10-B, §10-C, §10-D, §10-E, §11, §12, §13, §14, §15, §16, §17, §18, Appendix A.

## Round Summary
- `open` ACs: 0
- `blocked` ACs: 6
- regressions detected: 0
- CONFIRMED investigation findings: 1 (F-26-01 P1)
- SUSPECTED investigation findings: 2 (F-26-02 P3, F-26-03 P3)
- audit completeness: **12 / 12 axes swept**

## Implications for terminal check (STEP 2)

Terminal condition requires: zero `OPEN` at P0–P2 ✓; every Phase-DoD AC `CLOSED` or `BLOCKED` ✓; zero `uncovered_unsatisfied` narrative gaps (to be re-checked by `narrative-auditor` in STEP 1B); the last `ps-verifier` verdict not `FAIL` ✓ (R25 PASS); **AND** the spec-auditor reports zero CONFIRMED investigation findings.

**F-26-01 is CONFIRMED**, so the loop is NOT confirmed converged this round. R26 must remediate F-26-01 before another CONVERGED claim is valid.

F-26-02 and F-26-03 are SUSPECTED — they do not block convergence per se but should be triaged: F-26-02 surfaces a §15-vs-§18 SPEC design tension that wants a deliberate human decision (widen the AC, or accept the P5 narrow scope); F-26-03 is a doc-comment cleanup that can run as part of R26 or be deferred.
