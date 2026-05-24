# Wave Results — PS-R9 (terminal)

Both waves **PASS**.

## W1 — R-901 + R-902 + R-903
- `components/InfoPanel.tsx` rewritten — six collapsible sections (Dimensions,
  Spacing, Typography, Appearance, Layout, Hierarchy); `CollapsibleSection`
  persists collapsed state to `localStorage`; `StyleRow` renders a color
  swatch / `—` for empty values. PS-R2 `data-testid` hooks preserved.
- `utils/screenshot.ts` — `captureScreenshot` with a dynamic
  `import('html2canvas')`; `html2canvas` added as a runtime dependency.
- `examples/roundtrip/scenario.ts` — scripts the PinScope half of the APEX
  round-trip.

## W2 — R-904 verification

| Check | Command | Result |
|-------|---------|--------|
| Strict typecheck | `npm run typecheck` | exit 0 |
| Full suite | `npx vitest run` | 26 files, **248 tests pass** |
| Framework self-test | `bash framework/scripts/self-test.sh` | see AC-106 below |

No regression: all 241 PS-R1–R8 tests still green. New (7): infopanel (3),
screenshot (2), roundtrip (2).

## Closed by this round — 5
- **AC-031** — Appearance / Layout / Hierarchy sections render.
- **AC-032** — section collapse persists via `localStorage` across remount.
- **AC-033** — color values show a swatch; empty values show `—`.
- **AC-076** — `html2canvas` is dynamically imported, never static.
- **AC-107** — the scripted `examples/roundtrip` scenario resolves a change in
  1 round (≤ 2 asserted).

## AC-106 — BLOCKED (honest finding)
`self-test.sh` reports 6/103. Its harness explicitly tests `$HOME/.claude/`
installed files — which were never synced in this repo — so 97 failures are
**pre-existing and unrelated to PinScope** (the APEX framework here is itself a
partial build). Confirmed: `ui-phase.md` retains `mkdir -p .apex/phases`, every
PinScope-edited file is intact, and PinScope adds **zero** new self-test
failures. Verifying AC-106 properly would require syncing APEX into
`~/.claude/`, which would overwrite the live Claude Code session config — so
AC-106 is `BLOCKED`, closeable on a CI with a clean `~/.claude/` install.

## Reclassified to BLOCKED — 3
AC-061 (cross-origin iframe), AC-063 (`@media print` rendering), AC-083
(visual-regression screenshots) — all genuinely need a real browser engine.
