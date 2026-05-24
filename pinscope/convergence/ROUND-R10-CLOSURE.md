# Round Closure — PS-R10 (integrity round)

**Round:** PS-R10 — re-audit a converged tree; remediate two `BLOCKED` ACs
that were masking absent deliverables
**Status:** CONVERGED — loop terminal condition holds
**Date:** 2026-05-21

## Outcome
PS-R10 began as a no-op re-confirmation of the PS-R9 `CONVERGED` tree. The
independent `spec-auditor` re-ran the harness (249 tests green, typecheck
clean — no PS-R1–R9 closure regressed) but did **not** confirm zero findings:
re-reading the 7 `UNAVAILABLE` ACs surfaced two P3 findings where a `BLOCKED`
status masked a genuinely absent deliverable rather than an environment gap.
By explicit user decision the loop remediated (rather than `BACKLOG`-ing) both.

After remediation, AC-061 and AC-083 remain `BLOCKED` — but now **correctly**:
implementation present + test authored, blocked only by `env: browser` in this
environment. Verified by **257 passing tests** (249 baseline + 8 new) and a
clean strict typecheck; the clean-room `verifier` returned `VERIFIED` — no
regression, no false closure.

## Findings remediated this round — 2 (both P3)
- **F-10-01 / AC-061** — cross-origin iframe "outline + label only" rendering
  was not implemented (`grep -rEin 'iframe' src/ tests/` → zero hits).
  Remediation R-061 created `src/runtime/utils/iframe-overlay.ts`
  (`isCrossOriginFrame` / `markCrossOriginFrames` / `isIframeLimited`,
  mirroring the AC-060 `shadow-dom.ts` sibling) + a jsdom unit test
  (`tests/unit/runtime/iframe-overlay.test.ts`, 8 tests, tagged `AC-061`).
- **F-10-02 / AC-083** — no visual-regression suite was authored.
  Remediation R-083 created `tests/integration/visual-regression.spec.ts`
  (`toHaveScreenshot` across the SPEC §14 matrix — 4 viewports × light/dark ×
  host-CSS on/off) and added `chromium`/`firefox`/`webkit` `projects` +
  `expect.toHaveScreenshot` tuning to `playwright.config.ts`.

## Acceptance criteria closed this round — 0
No AC moved to `CLOSED`. AC-061 and AC-083 are `manual`-kind, `env: browser`;
with no browser binary they stay `BLOCKED`. The round's purpose was integrity,
not metric movement — converting two falsely-`BLOCKED` ACs into honestly-
`BLOCKED` ones.

## Convergence metric

| Round | Closed | Total | %   |
|-------|--------|-------|-----|
| PS-R8 | 57     | 69    | 83% |
| PS-R9 | 62     | 69    | 90% |
| **PS-R10** | **62** | 69 | **90%** |

CLOSED 62 · BLOCKED 7 · **OPEN 0**. Monotonic (closed non-decreasing). ✓

## Still BLOCKED — 7 (all environment-gated, implementation present)
AC-023, AC-030, AC-063, AC-082 (`browser`), AC-061, AC-083 (`browser` — newly
*correctly* blocked this round), AC-106 (`apex-install`). Each unblocks
verbatim on a capable CI; none is masking an absent deliverable.

## Still OPEN — 0
Zero `OPEN` acceptance criteria at every severity.

## Terminal condition
> Zero `OPEN` criteria — every Phase-DoD AC `CLOSED` or `BLOCKED`.

Met: every AC is `CLOSED` (62) or `BLOCKED` (7). The PS-R{N} loop holds its
terminal condition — and the `BLOCKED` set is now fully honest.

## Circuit breaker
Clear. Never triggered across all ten rounds.
