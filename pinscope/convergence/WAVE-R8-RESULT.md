# Wave Results — PS-R8

Both waves **PASS**.

## W1 — control components (R-801..804)
- `managers/SelectionManager.ts` — selection state, `data-pin-selected`
  movement, `#select=e_N` URL-hash mirroring + restore.
- `components/TopBar.tsx` — viewport / grid / state / live pin count.
- `components/StatePanel.tsx` — `<html data-state-override>` writer.
- `components/CommandBar.tsx` — input with `Cmd/Ctrl+K` focus, history nav,
  `Esc` blur.
- `hooks/useKeyboardShortcuts.ts` — the §8.11 shortcut table + `matchShortcut`.
- `utils/long-press.ts` — tap/long-press detector + compact-viewport check.

## W2 — verification (R-805)
Created `tests/unit/runtime/{selection,controls,shortcuts}.test.tsx` and
`tests/unit/long-press.test.ts`.

| Check | Command | Result |
|-------|---------|--------|
| Strict typecheck | `npm run typecheck` | exit 0 |
| Full suite | `npx vitest run` | 23 files, **241 tests pass** |

No regression: all 213 PS-R1–R7 tests still green. New (28).

## Closed by this round
AC-037 (TopBar fields + pin count), AC-038 (CommandBar focus/blur/history),
AC-040 (StatePanel override), AC-041 (SelectionManager URL hash + restore),
AC-043 (keyboard shortcut table), AC-064 (touch long-press + compact viewport).
