# PinScope Wave Map — PS-R10

> Dependency-ordered, write-serial-safe. Source: `REMEDIATION-PLAN-R10.md`.
> Within a wave, every file has exactly one owning R-item — no two R-items
> edit the same file in the same wave.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-061, R-083 | Both are self-contained, mutually independent, and touch fully disjoint file sets (`src/runtime/utils/` + `tests/unit/` vs. `tests/integration/` + `playwright.config.ts`). They can be executed concurrently. |
| **W2** | R-STATUS (verification + STATUS.md reclassification) | After both implementations land: run typecheck + the headless unit suite, then reclassify AC-061 / AC-083 in `convergence/STATUS.md` from "absent implementation/artifact" to env-only `BLOCKED`. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/utils/iframe-overlay.ts` *(new)* | R-061 | W1 |
| `tests/unit/runtime/iframe-overlay.test.ts` *(new)* | R-061 | W1 |
| `tests/integration/visual-regression.spec.ts` *(new)* | R-083 | W1 |
| `playwright.config.ts` *(modify)* | R-083 | W1 |
| `convergence/STATUS.md` *(modify)* | R-STATUS | W2 |

No file appears under two owners → **write-serial-safe**. R-061 and R-083
share zero files, so W1 concurrency is safe. `playwright.config.ts` has a
single owner (R-083). `convergence/STATUS.md` is touched only in W2, after
W1 completes, so it never collides with an implementation R-item.

## Per-wave exit criteria

- **W1 done:**
  - `npm run typecheck` (`tsc --noEmit`) clean across `src/` and `tests/`.
  - `npx vitest run tests/unit/runtime/iframe-overlay.test.ts` green — the
    headless-verifiable portion of R-061 passes in jsdom.
  - `tests/integration/visual-regression.spec.ts` type-checks; it is **not
    run** here (no browser binary — expected env-only block).
- **W2 done:**
  - `npx vitest run` green — all PS-R1–R9 tests (baseline 249) plus the new
    `iframe-overlay.test.ts` suite.
  - `convergence/STATUS.md` reclassifies AC-061 and AC-083 as env-only
    `BLOCKED` (implementation present + test authored).

## Verification

| AC | Verified by | Result in this env |
|----|-------------|--------------------|
| AC-061 | `iframe-overlay.test.ts` (jsdom) proves detection + overlay DOM construction; full cross-origin visual behavior needs a real browser. | Detection/DOM logic **headlessly verified**; AC stays `BLOCKED` on `env: browser` for visual confirmation — now *correctly* blocked (implementation present). |
| AC-083 | `visual-regression.spec.ts` is an authored, well-formed Playwright suite a browser CI runs (`toHaveScreenshot` across the §14 matrix). | Cannot run here (`env: browser`, no binary). AC stays `BLOCKED` — now *correctly* blocked (test artifact present). |

A claim without a passing check (or, for browser-only ACs, without a
present-and-type-checking artifact) stays `OPEN`.

## Headless vs. browser-only split (R-061)

- **Headlessly unit-testable (proven in W1 here):** the iframe-detection
  decision `isCrossOriginFrame` (the `try/catch` over `contentDocument`),
  the `markCrossOriginFrames` sweep + count, the outline+label overlay DOM
  node construction (attributes, label text, inline styles), and
  `isIframeLimited`. jsdom simulates a cross-origin frame via a throwing
  `Object.defineProperty` getter.
- **Browser-only residual (env-gated, not verifiable here):** the *visual
  correctness* of the rendered outline against a genuine second origin and
  a real `SecurityError` from an actual cross-origin frame. This residual
  is what keeps AC-061 `BLOCKED` on `env: browser` — correctly, since the
  implementation is now present.

## Circuit breaker

No green verification after 3 attempts, or a regression in any PS-R1–R9
test, or a check that `playwright.config.ts`'s `webServer`/`baseURL` or
`src/runtime/utils/shadow-dom.ts` were altered → halt and escalate.
