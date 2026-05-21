# PinScope Audit — PS-R6

> **Round:** PS-R6 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R5.

## Reality baseline (post PS-R5)
42 CLOSED, 3 BLOCKED, 24 OPEN (61%). 192 tests green. Edge-case behaviours
(SPEC §12) unimplemented.
*Re-read:* `ls pinscope/src/runtime/managers/RuntimePinObserver.ts` → absent;
`grep -rl data-pin-shadow pinscope/src` → none.

## Carry-forward verification (AP-006)
PS-R1–R5 closures re-confirmed: `npm test` green (192), typecheck clean.

## Findings — Cluster E (edge cases), headless-verifiable

| Finding | ACs | Sev | Gap (re-read check) |
|---------|-----|-----|---------------------|
| F-6-01 | AC-025 | P2 | no MutationObserver assigning `e_r{N}` runtime ids |
| F-6-02 | AC-060 | P2 | Shadow DOM hosts not marked `data-pin-shadow` |
| F-6-03 | AC-062 | P3 | no SVG-aware rect (`getBBox`+`getCTM`) |
| F-6-04 | AC-065 | P2 | no `mousemove` throttle / small-badge skip for heavy pages |

## PS-R6 scope
Implement the SPEC §12 edge-case behaviours: runtime-id MutationObserver,
Shadow-DOM marking, SVG-aware rect math, and the heavy-page throttle. All four
are **headless-verifiable** (happy-dom integration / unit / perf).

AC-024 (void-element JS-overlay badges) and AC-061/063/064 carry Playwright /
cross-origin `verify:` and are deferred to PS-R7's component round.

**Expected closures:** AC-025, AC-060, AC-062, AC-065 (4) → 46/69 ≈ 67%.
