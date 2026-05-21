# PinScope Audit — PS-R11 (independent carry-forward re-audit)

> **Round:** PS-R11 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** independent re-audit by a clean-context `spec-auditor`. The
> harness was re-run from `pinscope/`; every Appendix-A AC was diffed against
> the *current* `pinscope/` reality tree. No prior remediation reasoning
> assumed; the tree was not presumed healthy. Guards APEX learning AP-006
> ("The Unchecked Audit").

## Reality baseline

62 CLOSED, 7 BLOCKED, 0 OPEN (90%). 257 tests green across 27 test files.
`ac-results-R11.json` reports 62 PASS, 7 UNAVAILABLE, 0 FAIL
(`harness_ok: true`). The 7 UNAVAILABLE ACs are AC-023, AC-030, AC-061,
AC-063, AC-082, AC-083 (env `browser`) and AC-106 (env `apex-install`).

## Carry-forward verification (AP-006)

The harness was re-run against *current* code, not trusted from a prior claim:

- `npm test` → **257 passed (257), 27 files passed (27)**, exit 0. (The pin-map
  suite emits an expected `assertThrows` stack trace; the iframe-overlay suite
  emits a benign happy-dom `unloadPage` trace — both suites are green.)
  Note: the count rose from 249 (R10 baseline) to 257 — the +8 are the new
  `tests/unit/runtime/iframe-overlay.test.ts` suite (see findings resolution
  below). No prior closure regressed.
- `npm run typecheck` (`tsc --noEmit`, `strict: true`) → **clean**, exit 0.
- PS-R1–R10 closures re-confirmed: every `env: node` AC still resolves to a
  present, passing test/check against current code.

## Findings

No real findings. The 0-FAIL mechanical verdict holds for every `env: node`
AC — an independent re-read of current code/tests confirms no automatable
FAIL is masked by the matrix. The two P3 findings carried by the prior round
(F-10-01 AC-061, F-10-02 AC-083 — `BLOCKED` ACs whose implementation/test
artifact was absent) have both been **remediated** since R10 and are verified
closed below; no new finding is introduced in their place.

| Finding | AC | Severity | Disposition |
|---------|-----|----------|-------------|
| _(none)_ | — | — | No real finding in PS-R11. |

### Resolution of prior-round findings

- **F-10-01 (AC-061) — RESOLVED.** A real runtime implementation now exists at
  `src/runtime/utils/iframe-overlay.ts`: `isCrossOriginFrame` detects a
  cross-origin frame (`contentDocument` throws `SecurityError` or yields
  `null`); `markCrossOriginFrames` sweeps for `<iframe>` elements, stamps
  `data-pin-iframe`, and appends an absolutely-positioned, click-through
  outline + label overlay (`data-pinscope-iframe-overlay`) with no injection —
  exactly the SPEC §12 / Appendix A.5 "outline + label only" behavior.
  `tests/unit/runtime/iframe-overlay.test.ts` ("Cross-origin iframe overlay
  (AC-061)") authors 8 unit tests, all green, exercising detection, marking,
  count, label fallback, and overlay styling.
- **F-10-02 (AC-083) — RESOLVED.** A real visual-regression suite is now
  authored at `tests/integration/visual-regression.spec.ts` ("PinScope visual
  regression (AC-083)"). It uses `expect(page).toHaveScreenshot(...)` across
  the SPEC §14 matrix: 4 viewports × light/dark × with/without host CSS, two
  screenshots per arm (baseline + InfoPanel-open). `playwright.config.ts`
  carries a `toHaveScreenshot` expect block (`maxDiffPixelRatio: 0.02`) and 3
  browser projects (Chromium/Firefox/WebKit). The test artifact genuinely
  exists; only the browser binary is missing in this environment.

## Assessment of the 7 BLOCKED ACs

Each was opened in `ac-matrix.json` and cross-read against Appendix A.

| AC | env | kind | Implementation evidence | Correctly blocked |
|------|-----|------|--------------------------|-------------------|
| AC-023 | browser | vitest-tag | Badge `::before` rule in `src/runtime/styles/badges.css.ts`; `data-pin` injected by `src/plugin/ast-transformer.ts`; Playwright test `tests/integration/pinscope.spec.ts:13`. Impl present. | yes — env-only |
| AC-030 | browser | vitest-tag | `src/runtime/components/InfoPanel.tsx` renders Dimensions/Spacing/Typography sections; Playwright hover test `pinscope.spec.ts:24`. Impl present. | yes — env-only |
| AC-061 | browser | manual | Real runtime impl `src/runtime/utils/iframe-overlay.ts` (`isCrossOriginFrame`, `markCrossOriginFrames`, `isIframeLimited`); 8 green unit tests in `tests/unit/runtime/iframe-overlay.test.ts`. Needs two real origins to manual-attest. Impl present. | yes — env-only |
| AC-063 | browser | manual | `@media print { [data-pinscope-ui]{display:none} [data-pin]::before{display:none} }` present in `src/runtime/styles/badges.css.ts`. Needs a browser print engine. Impl present. | yes — env-only |
| AC-082 | browser | manual | Playwright integration suite present at `tests/integration/pinscope.spec.ts` + `playwright.config.ts`. Needs a browser binary. Impl present. | yes — env-only |
| AC-083 | browser | manual | Real visual-regression suite `tests/integration/visual-regression.spec.ts` with `toHaveScreenshot` across the §14 matrix; `playwright.config.ts` carries the screenshot config + 3 browser projects. Needs a browser binary. Test authored. | yes — env-only |
| AC-106 | apex-install | manual | `/apex:health-check` command (`framework/commands/apex/health-check.md`) invokes `~/.claude/scripts/self-test.sh`. Needs APEX synced to `~/.claude/`. Impl present. | yes — env-only |

All 7 BLOCKED ACs are now **correctly** `BLOCKED`: each one's implementation
and (where applicable) test artifact is genuinely present, and only its
`verify.env` (`browser` / `apex-install`) is missing in this environment.
Unlike PS-R10, AC-061 and AC-083 are no longer masking absent artifacts — the
prior P3 findings have been remediated and the `BLOCKED` status now accurately
reflects "implementation built + test authored". AC-061, AC-063, AC-082,
AC-083 and AC-106 are `manual`-kind ACs: they can never close via an
automated proxy and require an explicit `manual-attest` on a capable
environment.

## Verdict

**NO_FINDINGS.** The `env: node` reality tree (62/62) is clean — no automatable
FAIL is masked by the matrix. The 7 `UNAVAILABLE` ACs are all correctly
env-blocked with implementation/test artifacts present; the two prior-round
P3 findings (AC-061, AC-083) are verified remediated. No closure regressed;
the harness was re-run independently (257 tests green, typecheck clean).
