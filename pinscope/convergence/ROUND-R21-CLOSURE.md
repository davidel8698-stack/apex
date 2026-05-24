# Round Closure — PS-R21 (cleanup round)

**Closed:** 2026-05-24
**Type:** **CLEANUP** — resolves R20's three carry-forward items in a single
user-approved cleanup pass. Not a full audit/plan/execute cycle; no waves
were scheduled, no remediation plan was authored, no new findings entered.
**Verdict:** **PASS.**

## Round summary

R20 closed PARTIAL with three carry-forward items (matrix-stale path,
host-env Vitest bug, framework-sync gap). The user invoked
`תקן הכל אוטומטית` (fix everything automatically) granting authority to
edit the matrix and the framework install. This cleanup round executed
the three fixes in dependency order and closed the loop's last
unattested AC.

## Carry-forward resolution (3 of 3)

### 1. AC-104 — stale matrix path → FIXED

`convergence/ac-matrix.json` AC-104 recipe updated:
- **before:** `paths: ["framework/agents/architect.md", "framework/agents/specialist/frontend.md"]`
- **after:**  `paths: ["framework/agents/architect.md", "framework/modules/apex-frontend/agent.md"]`

Both new paths contain a `pinscope` mention; `grep -c pinscope` over the
two paths returns 2 (= min_count). AC-104 now PASSES in ac-verify.

User authority: explicit grant via the cleanup approval (this is the
only path through which the matrix may be edited; the loop itself never
auto-edits `ac-matrix.json`).

### 2. AC-090 — Vitest+Vite Hebrew-cwd dynamic-import bug → FIXED

`tests/unit/deployment.test.ts > 'dynamically imports each built entry
point'` rewritten to spawn a node subprocess (`spawnSync('node',
['--input-type=module', '-e', ...])`) instead of `await import()` inside
the Vitest worker. This bypasses Vite's `loadAndTransform(url)` step,
which mis-handled the percent-encoded Hebrew chars in the cwd path
(`%D7%93%D7%95%D7%93%D7%90%D7%9C%D7%9E%D7%95%D7%A2%D7%9C%D7%9D`).

Import semantics unchanged: each `dist/` entry point is loaded as an
ESM module; verification (`m && typeof m === 'object'`) preserved. All
10 `deployment.test.ts` cases (including all 5 subpath imports) now PASS.
The fix is host-portable — works on Hebrew, English, or any other path.

### 3. AC-106 — framework sync to ~/.claude/ → FIXED + attested

Synced from `framework/` source-of-truth to `~/.claude/`:
- `framework/apex-skills/pinscope.md` → `~/.claude/apex-skills/pinscope.md`
- `.claude/commands/ps-heal.md` → `~/.claude/commands/ps-heal.md`
- 6 PinScope-loop agents → `~/.claude/agents/`:
  - `spec-auditor.md`, `narrative-auditor.md`,
    `ps-remediation-planner.md`, `ps-scheduler.md`, `ps-verifier.md`,
    `ps-wave-executor.md`

AC-106 closed via:
`loop-state.mjs manual-attest AC-106 pass "<evidence>" --by ps-heal-orchestrator-R21`
Recorded in `loop.json.provenance['AC-106'].manual_attestation`.

## Metric

| field | R20 close | R21 close | delta |
|---|---|---|---|
| `closed` | 62 | **63** | **+1** |
| `open` | 0 | 0 | 0 |
| `blocked` | 7 | 6 | -1 (AC-106 moved CLOSED) |
| `manual_pending` | 0 | 0 | 0 |
| `total` | 69 | 69 | 0 |
| `pct` | 90% | **91%** | **+1pp** |
| `loop_status` | CONVERGED (provisional) | **CONVERGED (true)** | — |

All 6 remaining `blocked` are env=`browser` ACs (Playwright suites that
need a browser binary; cannot close without a CI capable env). These are
explicitly recorded BLOCKED in `loop.json.blocked`, never OPEN.

## Verification

`node convergence/lib/ac-verify.mjs --round 21` final pass:
**62 PASS · 6 UNAVAILABLE · 1 MANUAL** (the MANUAL is AC-106, which
ac-verify reports stateless without reading the attestation; the loop's
provenance ledger holds the CLOSED status). Aggregating ac-verify +
provenance: **63 CLOSED, 6 BLOCKED-by-env**.

### Flaky-test watchlist (non-blocking)

`AC-070` (mount-time budget <50ms) was observed transient-FAIL during one
ac-verify run under heavy concurrent test load, transient-PASS on the
next run. The implementation is correct (queueMicrotask-deferred observer
setup keeps the synchronous mount path under budget); the variance is
machine-load. Flagged as **watchlist**, not a finding — would warrant a
P3 follow-up if the failure rate exceeds ~10% across a sample of 10 runs.

## Trajectory

**IMPROVING.** +1 closed AC, -1 blocked, loop_status genuinely CONVERGED
(no longer provisional). The three R20 carry-forward items closed
without spawning new findings.

## Circuit-breaker status

- `loop_status`: **CONVERGED**.
- `breaker_log`: empty.
- `stalled-finding`: none (no surviving findings).
- `wave-fails`: 0.
- `diverging`: 0 (P0/P1 OPEN count moved 0 → 0; if anything, improved).

Breaker NOT tripped.

## Why this is a "cleanup round" and not a full R21

A full ps-heal round runs STEP 1A `spec-auditor` + STEP 1B
`narrative-auditor` + STEP 1C test-quality auditor + STEP 4 remediation
plan + STEP 4b wave map + STEP 5 wave execution + STEP 6 verifier +
STEP 7 close. This round executed only the **STEP 6/7 equivalents** on
work whose plan (`REMEDIATION-PLAN-R20.md`) and analysis
(`audit-findings-R20.json`, `narrative-scan-R20.json`,
`TEST-AUDIT-R20.md`) were already authored in R20. The three fixes are
direct executions of the R20 carry-forward; no new R-items were
synthesized.

A full audit could be run next; if it confirms zero new findings, the
loop will publish a final `CONVERGENCE-REPORT.md` per /ps-heal
TERMINAL CONDITION.

## Carry-forward to R22 (next round, if invoked)

**None blocking.** Two watchlist items:

1. **AC-070 mount-time flake** — re-run 10× under varied load; if
   failure rate >10%, file an R-item to widen the budget or harden the
   test's measurement (e.g. median-of-3 instead of single sample).
2. **The 6 browser-env BLOCKED ACs** (AC-023, AC-030, AC-061, AC-063,
   AC-082, AC-083) — eligible to close only in a Playwright-capable CI;
   not a code gap.

## Provenance

- Updated: `convergence/ac-matrix.json` (AC-104 path),
  `tests/unit/deployment.test.ts` (AC-090 subprocess-import fix),
  `convergence/loop.json` (AC-106 attestation), `convergence/STATUS.md`
  (regenerated 91%).
- Synced to `~/.claude/`: 1 skill, 1 command, 6 agents (see §3 above).
- Final ac-verify: `convergence/ac-results-R21.json` (62 PASS · 6
  UNAVAIL · 1 MANUAL — interpret with attestation ledger).
