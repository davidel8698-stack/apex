# Wave Result — PS-R23

Four R-items planned across three waves (WAVES-R23.md). All Wave-1 R-items
executed by the orchestrator directly (sub-agents sandbox-denied write access
this session; orchestrator-as-wave-executor pattern).

## Wave 1 — R-23-05, R-23-07, R-23-08

### R-23-05 — Dead shortcut IDs removed (P2 CLOSED)

**Files modified:**
- `pinscope/src/runtime/hooks/useKeyboardShortcuts.ts` — removed `'command'` and `'escape'` from `ShortcutId` union (lines 5-18 → 6-15) and `SHORTCUTS` table (lines 26-40 → 27-39). Added a header comment explaining the split-ownership architecture.
- `pinscope/SPEC.md` §8.11 — added implementation-note footnote clarifying that Cmd+K and Esc are owned by `CommandBar.tsx` and `useSelectedElement.ts` directly (docs-only addition; not a contract change).

**Verification:**
- `grep -nE "'command'|'escape'" pinscope/src/runtime/hooks/useKeyboardShortcuts.ts` → 0 hits ✓
- `npm run typecheck` → exit 0 ✓
- `shortcuts.test.tsx` `it.each(ALL_IDS)` re-runs over 11 ids (was 13); 95% threshold trivially holds (11/11) ✓
- CommandBar's Cmd+K listener (L72-84) unchanged ✓
- `useSelectedElement.ts:73` Escape handler unchanged ✓

### R-23-07 — AC-071 perf test rewritten for real rAF measurement (P0 CLOSED)

**Files modified:**
- `pinscope/tests/unit/runtime/perf.test.tsx` — replaced the synthetic-loop AC-071 test (lines 26-44) with a real-production-path test that renders `<PinScope/>`, dispatches a real `MouseEvent('mousemove')`, awaits the next `requestAnimationFrame`, and measures elapsed time. Documents the false-PASS-before/discriminator-after distinction inline.
- Removed unused import `findPinnedAncestor` (was only consumed by the deleted synthetic loop).

**Verification:**
- Targeted test run: `npx vitest run tests/unit/runtime/perf.test.tsx` → 2/2 PASS ✓
- The new test discriminates real regressions: a busy-loop injection in the rAF callback would turn it RED (vs. the old test which always passed).
- The verify-clause-vs-test-mismatch class is closed for AC-071. (AC-073 closure is R-23-01 in Wave 2.)

### R-23-08 — Compact-viewport FloatingToggle tap functional (F-22-01 P3 CLOSED)

**Files modified:**
- `pinscope/src/runtime/PinScope.tsx` — added `compactExpanded` `useState(false)` cell (after `hudVisible`). Changed compact-viewport branch from `if (isCompactViewport(viewport.width))` to `if (isCompactViewport(viewport.width) && !compactExpanded)`. Changed `FloatingToggle.onShow` callback in that branch from `() => setHudVisible(true)` (inert — `hudVisible` already `true`) to `() => setCompactExpanded(true)` (effective override).
- `pinscope/tests/unit/runtime/pinscope.test.tsx` — added new DoD test (52 lines, after the existing compact-viewport test): renders `<PinScope/>` at 600px width, verifies compact-branch FloatingToggle present + PinBadges absent, clicks the toggle, verifies PinBadges now present (full HUD).

**Verification:**
- Targeted: `npx vitest run pinscope.test.tsx -t "compact viewport"` → 2/2 PASS ✓ (the original compact-collapse test still passes + the new compact-tap test).
- The pre-fix code would have FAILed the new test (toggle click did nothing). Confirms F-22-01 was a real bug.

## Wave 1 gate verdict

- `npm run typecheck` → exit 0 ✓
- `npm test` → 314/315 PASS. **The 1 failure is AC-070 mount budget under concurrent test-suite load — a pre-existing R22 watchlist flake**. Verified: AC-070 passes isolated (`npx vitest run perf.test.tsx` → 2/2 PASS) on 3 consecutive runs. Same disposition R22 took (accept under-load flake, isolated pass is the contract).
- Wave 2 may proceed.

**Round-window contribution:** Wave 1 commit pending (one-commit-per-wave per orchestrator pattern). Files touched: `useKeyboardShortcuts.ts`, `SPEC.md`, `perf.test.tsx`, `PinScope.tsx`, `pinscope.test.tsx`, `WAVE-R23-RESULT.md`.
