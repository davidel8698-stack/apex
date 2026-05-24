# PinScope Convergence Audit — Round 13 (PS-R13)

**Auditor:** spec-auditor (clean context, independent re-audit)
**North-Star:** `pinscope/SPEC.md` v2.0.0 — Appendix A, 69 AC rows
**Spec hash:** `sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`
**Date:** 2026-05-21
**Guard:** APEX learning AP-006 — "The Unchecked Audit." No prior round's reported
numbers are trusted; every figure below comes from a command executed in this round.

---

## 1. Reality Baseline

| Bucket | Count | Definition |
|--------|-------|------------|
| Closed (PASS) | 62 | `env:node` ACs whose mechanical check passed in `ac-results-R13.json` |
| Blocked (UNAVAILABLE) | 7 | ACs whose `env` (`browser` / `apex-install`) is absent per `env-capabilities.json` |
| Open (FAIL) | 0 | No AC failed its mechanical check |
| **Convergence** | **90%** | 62 / 69 acceptance criteria closed |

`env-capabilities.json` for this round: `browser:false`, `apex_install:false`,
`npm_registry:true` (probed `2026-05-21T21:51:34Z`). The 7 blocked ACs are exactly
the set whose matrix `env` field is `browser` (AC-023, AC-030, AC-061, AC-063,
AC-082, AC-083) or `apex-install` (AC-106). No `env:node` AC is blocked, so the
environment is not masking any node-verifiable capability.

---

## 2. Carry-Forward Verification (harness re-run this round)

Both commands were executed fresh from `/home/user/apex/pinscope/`:

| Command | Result | Exit code |
|---------|--------|-----------|
| `npm test` | **257 tests passed**, 27 test files passed, 0 failed | **0** |
| `npm run typecheck` (`tsc --noEmit`) | clean, no diagnostics | **0** |

These figures match `ac-results-R13.json` `harness_ok:true` exactly. The single
`stderr` line observed during `npm test` is an expected, asserted warning inside
`tests/unit/pin-map.test.ts` ('load warns and continues on an unsupported version
— does not throw'); it is not a failure.

Targeted re-confirmation of the two count-gated suites:

| Suite | Tests | SPEC threshold | Status |
|-------|-------|----------------|--------|
| `tests/unit/ast-transformer.test.ts` (AC-080) | 66 | >= 50 input/output pairs | satisfied |
| `tests/unit/operation-parser.test.ts` (AC-050 / AC-081) | 45 | >= 30 cases | satisfied |

(Both suites use `it.each` tables; the harness counts executed cases — 66 and 45 —
not literal `it(` calls.) The mechanical `harness_ok:true` / `0 FAIL` verdict in
`ac-results-R13.json` is therefore confirmed against current code.

### Masked-FAIL spot-check (env:node PASS ACs)

A representative sample of the 62 PASS ACs — spanning build module, runtime,
operation protocol, edge cases, deployment and APEX integration — was traced from
the SPEC Appendix A row to the actual source/test artifact to confirm the check
genuinely exercises the SPEC capability (not a trivially-true assertion):

| AC | Phase / kind | SPEC capability | Artifact verified | Genuine |
|----|--------------|-----------------|-------------------|---------|
| AC-002 | build / vitest | `transformJSX` injects `data-pin="e_N"` | `tests/unit/ast-transformer.test.ts` ('injects data-pin starting at e_1 (AC-002)') asserts `/data-pin="e_1"/` on a real `<button>` fixture | yes |
| AC-005 | build / vitest | stable IDs across two transforms | same suite (AC-005) runs `transformJSX` twice and asserts `a.code === b.code` | yes |
| AC-050 | operation / vitest | parser accepts §11 grammar, rejects malformed | `tests/unit/operation-parser.test.ts` (40 AC-050 cases, valid + invalid) | yes |
| AC-052 | operation / vitest | parsed op conforms to §9.3 schema | `tests/unit/operation-builder.test.ts` (14 AC-052 cases) | yes |
| AC-062 | edge / vitest | SVG rects via `getBBox`+`getCTM` | `tests/unit/edge-utils.test.ts` ('elementRect — SVG-aware (AC-062)') maps a bbox through a CTM and asserts viewport coords `{15,26,30,40}` | yes |
| AC-065 | edge / vitest | >500 pins throttle, badges <16px skipped | `tests/unit/edge-utils.test.ts` ('heavy-page throttling (AC-065)') asserts `HEAVY_PAGE_THRESHOLD===500`, `shouldSkipBadge(10,10)===true` | yes |
| AC-090 | deployment / vitest | export map resolves four subpaths | `tests/unit/deployment.test.ts` (7 AC-090 cases) | yes |
| AC-073 | perf / command | dev bundle < 80 KB | `npm run size` exit 0 | yes |
| AC-100/102/104 | APEX / grep | framework integration edits present | `framework/apex-skills/pinscope.md` (5 headings confirmed), `framework/commands/apex/ui-phase.md` (1 PINSCOPE INSTRUMENTATION), `architect.md`/`frontend.md` (1 `pinscope` each) | yes |

No masked FAIL was found: every sampled mechanical PASS is backed by a real test
that exercises the corresponding SPEC capability with non-trivial assertions.

---

## 3. Findings

**None.** No `findings` entries this round.

| ID | AC | Severity | Title |
|----|----|----------|-------|
| — | — | — | (no findings) |

---

## 4. Assessment of the 7 BLOCKED Acceptance Criteria

This is the AP-006 critical task. For each blocked AC the SPEC Appendix A row was
read and the implementation **and** the authored-but-unrunnable test located in
the `pinscope/` (or `framework/`) tree. The question for each: is the AC `BLOCKED`
purely because the environment is missing, or is a deliverable genuinely ABSENT
(which would be a real finding)? The R10 failure mode — AC-061 and AC-083 marked
`BLOCKED` while their code did not exist — was specifically re-checked.

| AC | Env | Implementation artifact | Test / verify artifact | Impl. present | Correctly blocked |
|----|-----|-------------------------|------------------------|---------------|-------------------|
| AC-023 | browser | `src/runtime/styles/badges.css.ts` — `[data-pin]::before { content: attr(data-pin) }` (lines 5-18) | `tests/integration/pinscope.spec.ts` ('injects a data-pin badge … (AC-023)') reads `::before` content via `getComputedStyle(el,'::before')` | yes | yes |
| AC-030 | browser | `src/runtime/components/InfoPanel.tsx` — Dimensions/Spacing/Typography sections; `getComputedStyle` (l.120), `data-pinscope-panel` host (l.144), 'Width' StyleRow (l.149) | `tests/integration/pinscope.spec.ts` ('hover opens the InfoPanel … (AC-030)') hovers a button, asserts panel visible + 'Width' text | yes | yes |
| AC-061 | browser | `src/runtime/utils/iframe-overlay.ts` — `isCrossOriginFrame` / `markCrossOriginFrames` / `isIframeLimited`; click-through (`pointerEvents:none`) dashed-outline + label overlay, no injection | `tests/unit/runtime/iframe-overlay.test.ts` ('Cross-origin iframe overlay (AC-061)', 8 jsdom cases) — runs green in `npm test`; matrix `kind:manual` because a true two-origin scenario needs real origins | yes | yes |
| AC-063 | browser | `src/runtime/styles/badges.css.ts` lines 37-40 — `@media print { [data-pinscope-ui]{display:none} [data-pin]::before{display:none} }` | matrix `kind:manual` — print-emulation screenshot diff, needs a browser print engine | yes | yes |
| AC-082 | browser | `tests/integration/pinscope.spec.ts` — Playwright §14 checklist suite (5 authored tests) against `examples/vite-react`; `playwright.config.ts` (testDir `./tests/integration`, chromium/firefox/webkit projects, `webServer`) | `@playwright/test ^1.60.0` in devDependencies | yes | yes |
| AC-083 | browser | `tests/integration/visual-regression.spec.ts` — §14 matrix, 4 viewports × light/dark × host-css = 16 tests via `toHaveScreenshot` | `playwright.config.ts` `expect.toHaveScreenshot.maxDiffPixelRatio:0.02`; matrix `kind:manual` artifact diff | yes | yes |
| AC-106 | apex-install | APEX integration edits present: `framework/apex-skills/pinscope.md` (5 headings), `framework/commands/apex/ui-phase.md` (PINSCOPE INSTRUMENTATION), `ui-review.md` (PINSCOPE EVIDENCE), `architect.md`/`specialist/frontend.md` — all verified via AC-100/102/103/104 PASS this round | matrix `kind:manual` — `/apex:health-check` must run against APEX synced to `~/.claude/` | yes | yes |

**R10 regression re-check.** `src/runtime/utils/iframe-overlay.ts` (72 lines, three
exported functions building a real overlay) and `tests/integration/visual-regression.spec.ts`
(60 lines, a full nested-loop §14 matrix) were both opened and read in full this
round. Neither is a stub. The R10-class failure mode — `BLOCKED` masking absent
code — does **not** recur.

**Conclusion of §4:** all 7 blocked ACs have their implementation **and** their
authored test genuinely present in the source tree. Each is `BLOCKED` solely
because the runtime environment lacks a browser binary (6 ACs) or an
installed/synced APEX framework (1 AC) — not because of any absent build artifact.
No `BLOCKED` status is masking a build gap.

---

## 5. Verdict

**`NO_FINDINGS`.**

An independent R13 re-audit confirms a healthy code tree. The harness was re-run
in this round: 257 Vitest tests pass across 27 files (`npm test` exit 0) and
`tsc --noEmit` is clean (`npm run typecheck` exit 0) — matching the
`ac-results-R13.json` `harness_ok:true` claim exactly. The mechanical verdict —
62 PASS / 7 UNAVAILABLE / 0 FAIL — is real: a spot-check sample of `env:node` PASS
ACs across every phase and kind each traces to a test that genuinely exercises its
SPEC capability, and no masked FAIL exists. All 7 UNAVAILABLE ACs have a genuine
implementation artifact and an authored-but-unrunnable test, and are correctly
blocked on a missing environment.

PinScope stands at **90% convergence (62/69)**; the remaining 7 ACs are
environment-blocked, not gap-blocked, and cannot close until a browser binary
(6 ACs) or an APEX install (1 AC) becomes available.
