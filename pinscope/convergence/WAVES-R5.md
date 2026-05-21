# PinScope Wave Map — PS-R5

> Dependency-ordered, write-serial-safe. Source: `REMEDIATION-PLAN-R5.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-502 | Snapshot system — pure, independent. |
| **W2** | R-501 | `examples/vite-react` app — needs built `pinscope/dist/`. |
| **W3** | R-503 | Playwright integration suite — targets the example. |
| **W4** | R-504 | Snapshot tests + full verification (example prod build + grep). |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/runtime/managers/SnapshotManager.ts` | R-502 | W1 |
| `examples/vite-react/**` | R-501 | W2 |
| `playwright.config.ts`, `tests/integration/**` | R-503 | W3 |
| `tests/unit/runtime/snapshot.test.tsx` | R-504 | W4 |

No file has two owners → write-serial safe.

## Per-wave exit criteria

- **W1 done:** `tsc --noEmit` clean on `src/`.
- **W2 done:** `vite build` of `examples/vite-react` succeeds.
- **W3 done:** Playwright suite authored (not run — `BLOCKED`).
- **W4 done:** `grep -rc` over the example `dist/` returns 0; `npx vitest run`
  green — all 188 PS-R1–R4 tests plus the snapshot suite.

## Verification

AC-010 / AC-074 — `grep` the example production `dist/`. AC-042 / AC-075 —
happy-dom snapshot tests. AC-082 — authored only → `BLOCKED`. A claim without
a passing check stays `OPEN`.

## Circuit breaker

No green verification after 3 attempts, or a PS-R1–R4 regression → halt.
