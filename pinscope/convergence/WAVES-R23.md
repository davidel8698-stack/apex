# Wave Map — PS-R23

## Plan validation

`ACCEPTED`

Gate result for `REMEDIATION-PLAN-R23.md` (6 R-items, R-23-01 / R-23-03 / R-23-05 / R-23-06 / R-23-07 / R-23-08):

- **Mandatory sections.** All six R-items carry the six mandatory sections — Ecosystem analysis, Execution plan, Acceptance criteria, Definition of Done, Dependencies, Risk assessment.
- **Root cause, not symptom.** R-23-01 + R-23-07 share root cause (verify-clause-vs-test-mismatch class). R-23-05 + R-23-06 are dead-code cleanups (R20 pattern continuation). R-23-03 is test-rigor strengthening. R-23-08 is hollow-interaction fix. Each addresses the root cause; none is symptom-patch.
- **Definition of Done.** Every DoD is mechanically checkable: grep predicates, `git diff --stat` counts, `npm test` / `npm run typecheck` exit codes, mutation gates with specific RED expectations.
- **No silent scope reduction.** Audit-findings-R23.json has 5 CONFIRMED + 1 SUSPECTED investigation findings (F-23-01/03/05/06/07 + F-22-01 carry-forward). Plan maps R-23-01↔F-23-01, R-23-03↔F-23-03, R-23-05↔F-23-05, R-23-06↔F-23-06 (+NF-23-01 narrative gap), R-23-07↔F-23-07, R-23-08↔F-22-01. All 6 covered; nothing dropped. F-23-02 and F-23-04 were initially raised in plan-mode but REFUTED/downgraded by test-quality auditor — explicitly recorded in audit-findings-R23.json `coverage.notes` as polish opportunities, not gating.
- **No line-number anchors in plan body.** Plan uses content anchors (component identifier names, regex names, JSX block markers, AC IDs). Line numbers appear ONLY inside cited audit findings — permitted (frozen audit snapshot).
- **Deletion-safety honored.** Narrative-auditor's deletion-safety warning incorporated: R-23-06 scope corrected from 3 files to 1 (iframe-overlay.ts only). screenshot.ts and rect-math.ts NOT deleted (would break AC-076 + AC-062).

> **Scheduler authorship.** ps-scheduler sub-agent was sandbox-denied write access in this session. The orchestrator's main thread composes this wave map following the same structure as WAVES-R22.md and WAVES-R20.md.

The plan is scheduled below.

## Dependency analysis

Files touched, by R-item:

- **R-23-01** — `pinscope/scripts/check-bundle-size.mjs` (new), `pinscope/package.json`
- **R-23-03** — `pinscope/tests/unit/deployment.test.ts`
- **R-23-05** — `pinscope/src/runtime/hooks/useKeyboardShortcuts.ts`, `pinscope/SPEC.md` (§8.11 footnote)
- **R-23-06** — `pinscope/src/runtime/utils/iframe-overlay.ts` (delete), `pinscope/tests/unit/runtime/iframe-overlay.test.ts` (delete), `pinscope/src/index.ts` (potentially — only if iframe-overlay is re-exported), `pinscope/convergence/SPEC-BUMP-PROPOSAL-R23.md` (new)
- **R-23-07** — `pinscope/tests/unit/runtime/perf.test.tsx`
- **R-23-08** — `pinscope/src/runtime/PinScope.tsx`, `pinscope/tests/unit/runtime/pinscope.test.tsx`

Blocking relationships:

- **No true logical dependency between any two R-items.** R-23-01 (P0) and R-23-07 (P0) share a conceptual root cause but are independent files. R-23-06 only proposes a SPEC bump; the actual SPEC.md is not modified by R-23-06 (the bump is recorded as a proposal). R-23-05 modifies SPEC.md (§8.11 footnote — docs-only, frozen-permitted). The two SPEC.md changes (R-23-05 footnote, R-23-06 proposal record) don't conflict because R-23-06 doesn't touch SPEC.md.
- **Write-serial coupling.** Each wave is verified single-owner per file (table below).
- **Layering.** All P0/P2 R-items target reality (the SPEC is frozen). R-23-05's SPEC.md footnote is the one docs-only edit; the orchestrator will tag the commit as `docs(spec)` to make the doc-only nature explicit.

## Waves

Three waves, ordered to keep the highest-severity items in the earliest waves so any breakage surfaces immediately.

### Wave 1 — R-23-05, R-23-07, R-23-08

- **R-23-05** — files: `pinscope/src/runtime/hooks/useKeyboardShortcuts.ts`, `pinscope/SPEC.md` (§8.11 footnote)
- **R-23-07** — files: `pinscope/tests/unit/runtime/perf.test.tsx`
- **R-23-08** — files: `pinscope/src/runtime/PinScope.tsx`, `pinscope/tests/unit/runtime/pinscope.test.tsx`
- **One-owner check:** disjoint file sets. SPEC.md (R-23-05) ≠ PinScope.tsx (R-23-08) ≠ perf.test.tsx (R-23-07) ≠ useKeyboardShortcuts.ts (R-23-05) ≠ pinscope.test.tsx (R-23-08).
- **Dependency check:** none of the three depends on an R-item in a later wave.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0; `npm test` is green; R-23-07's rewritten AC-071 test passes (and the mutation gate — 1e8 busy-loop injection — turns it red); R-23-08's compact-tap-summon DoD test transitions red→green. Wave 2 does not start until this gate passes.

### Wave 2 — R-23-01, R-23-03

- **R-23-01** — files: `pinscope/scripts/check-bundle-size.mjs` (new), `pinscope/package.json`
- **R-23-03** — files: `pinscope/tests/unit/deployment.test.ts`
- **One-owner check:** scripts/check-bundle-size.mjs (R-23-01) ≠ deployment.test.ts (R-23-03). package.json owned only by R-23-01.
- **Dependency check:** R-23-03's strengthened AC-091 test imports from the runtime export map declared in `package.json`. If R-23-01 modifies the `size-limit` array AND ALSO modifies the `exports` map (it does NOT — R-23-01 only touches the `scripts` + `size-limit` fields), there'd be a conflict. Verified: no overlap.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0; `npm run build && npm run size` exits 0 (new dual-budget check passes against current bundle); R-23-03's 4 new wrapper-contract tests pass; both mutation gates (immutability + no-op-when-disabled) turn red on documented mutations. Wave 3 does not start until this gate passes.

### Wave 3 — R-23-06

- **R-23-06** — files: `pinscope/src/runtime/utils/iframe-overlay.ts` (delete), `pinscope/tests/unit/runtime/iframe-overlay.test.ts` (delete), `pinscope/src/index.ts` (review for re-exports), `pinscope/convergence/SPEC-BUMP-PROPOSAL-R23.md` (new)
- **One-owner check:** R-23-06 is sole owner of all 4 files.
- **Dependency check:** R-23-06 is independent. Placed last so any deletion-related test surprise surfaces against a known-green W1+W2 baseline.
- **Gate check:** `grep -rn "iframe-overlay\|markCrossOriginFrames\|isIframeLimited\|IFRAME_OVERLAY_ATTR" pinscope/src pinscope/tests` returns 0; `cd pinscope && npm run typecheck` exits 0; `cd pinscope && npm test` is green (full suite; expected -8 tests from deleted iframe-overlay.test.ts); `pinscope/convergence/SPEC-BUMP-PROPOSAL-R23.md` exists and names the §12 clause.

## Conflict matrix

File → R-items that touch it, with wave assignment:

| File | R-23-01 | R-23-03 | R-23-05 | R-23-06 | R-23-07 | R-23-08 |
|---|---|---|---|---|---|---|
| `pinscope/scripts/check-bundle-size.mjs` (new) | W2 | — | — | — | — | — |
| `pinscope/package.json` | W2 | — | — | — | — | — |
| `pinscope/tests/unit/deployment.test.ts` | — | W2 | — | — | — | — |
| `pinscope/src/runtime/hooks/useKeyboardShortcuts.ts` | — | — | W1 | — | — | — |
| `pinscope/SPEC.md` | — | — | W1 | — | — | — |
| `pinscope/src/runtime/utils/iframe-overlay.ts` (delete) | — | — | — | W3 | — | — |
| `pinscope/tests/unit/runtime/iframe-overlay.test.ts` (delete) | — | — | — | W3 | — | — |
| `pinscope/src/index.ts` | — | — | — | W3 | — | — |
| `pinscope/convergence/SPEC-BUMP-PROPOSAL-R23.md` (new) | — | — | — | W3 | — | — |
| `pinscope/tests/unit/runtime/perf.test.tsx` | — | — | — | — | W1 | — |
| `pinscope/src/runtime/PinScope.tsx` | — | — | — | — | — | W1 |
| `pinscope/tests/unit/runtime/pinscope.test.tsx` | — | — | — | — | — | W1 |

**Intra-wave collision check:**

- **Wave 1:** R-23-05 owns useKeyboardShortcuts.ts + SPEC.md; R-23-07 owns perf.test.tsx; R-23-08 owns PinScope.tsx + pinscope.test.tsx. **5 disjoint files — no collision.**
- **Wave 2:** R-23-01 owns scripts/check-bundle-size.mjs + package.json; R-23-03 owns deployment.test.ts. **3 disjoint files — no collision.**
- **Wave 3:** R-23-06 alone — sole owner of all 4 files.

No file is multiply-owned in any wave. The one-file-one-owner-per-wave invariant holds across all 3 waves.
