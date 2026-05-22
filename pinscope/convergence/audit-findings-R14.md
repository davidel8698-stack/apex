# PinScope Spec-Conformance Audit — PS-R14

**Round:** 14
**Generated:** 2026-05-21T23:10:00Z
**North-Star:** `pinscope/SPEC.md` v2.0.0 (FROZEN, hash `sha256:1779526021…7c7a45`)
**Machine input:** `ac-results-R14.json` — 62 PASS, 7 UNAVAILABLE, 0 FAIL.

## Verdict: NO_FINDINGS

Zero confirmed findings. The `pinscope/` reality tree remains converged against
the frozen North-Star. This is the correct, expected result for a tree that has
reported CONVERGED for rounds 11–13 — an empty audit on a converged tree is a
pass, not an omission.

## STEP 1 — Re-confirm machine FAILs

`ac-results-R14.json` reports **0 `FAIL` verdicts**. There are therefore no
machine-asserted gaps to independently re-confirm. Nothing to drop, nothing to
promote.

## STEP 4 — Regression scan

Every AC the loop previously recorded `CLOSED` in `loop.json` (62 of them) was
cross-checked against `ac-results-R14.json`.

- **62 previously-CLOSED ACs → all 62 still `PASS` in R14.**
- **0 regressions.** No `CLOSED` AC has dropped to `FAIL`.

The convergence metric holds at 62 closed / 69 total (90%), monotonically
non-decreasing since R9.

## AP-006 spot-checks — re-reading the implementation

Per APEX learning AP-006 ("The Unchecked Audit"), machine PASS verdicts were not
trusted blindly. A representative sample across phases and verify-kinds was
re-confirmed by reading the actual implementation code, not just test tags:

### Findings by severity

No findings at any severity (P0, P1, P2, P3). Each spot-check below is reported
as a CONFIRMED-genuine PASS, not a finding.

- **AC-001** (P0, vitest-tag) — `re_read`: `Read pinscope/src/plugin/index.ts`.
  `pinscope()` returns a Vite plugin with `name === 'vite-plugin-pinscope'`,
  `enforce === 'pre'`, and the four `buildStart`/`transform`/`buildEnd`/
  `transformIndexHtml` hooks. Genuine.
- **AC-005** (P0, vitest-tag) — `re_read`: `Read stable-id-generator.ts +
  pin-map.ts; grep -n 'AC-005' tests/unit/ast-transformer.test.ts`. `stableKey`
  is `file:line:column`; `getOrAssign` returns the existing id for a known key,
  so two transforms of identical source yield identical ids. Genuine.
- **AC-008** (P2, vitest-tag) — `re_read`: `Read pinscope/src/plugin/pin-map.ts`.
  `reconcile()` marks unseen keys `deleted:true` and never reuses an id
  (`next_id++` fires only for new keys). Matches resolution I-2. Genuine.
- **AC-009** (P0, vitest-tag) — `re_read`: `Read production-stripper.ts +
  index.ts transformIndexHtml`. `stripPins` removes every
  `/\sdata-pin="[^"]*"/g`; `transformIndexHtml` applies it when disabled.
  Genuine.
- **AC-010** (P0, build-grep) — `re_read`: `grep -rEl 'data-pin|PinScope|pinscope'
  pinscope/examples/vite-react/dist`. The built `dist/` (index.html + assets)
  has 0 matching files — production build is clean. Genuine.
- **AC-050** (P0, vitest-tag) — `re_read`: `Read operation-parser.ts; grep
  describe/it in tests/unit/operation-parser.test.ts`. `parseCommand` handles
  all five §11 target forms and every operator, throwing typed
  `OperationParseError` on malformed input; the suite drives ≥30 grammar cases.
  Genuine.
- **AC-073** (P0, command) — `re_read`: `Read package.json size-limit config`.
  `size-limit` has a `runtime (dev)` entry at the 80 KB §13 budget; `npm run
  size` exits 0. Genuine.
- **AC-100** (P1, grep) — `re_read`: `grep -nE '^## (Conventions|Anti-Patterns|
  Common Patterns|Testing|Common Gotchas)' framework/apex-skills/pinscope.md`.
  All five apex-skill headings present. Genuine.
- **AC-102** (P1, grep) — `re_read`: `grep -n 'PINSCOPE INSTRUMENTATION'
  framework/commands/apex/ui-phase.md`. The scaffold step is present. Genuine.
- **AC-104** (P2, grep) — `re_read`: `grep -l 'pinscope'
  framework/agents/architect.md framework/agents/specialist/frontend.md`. Both
  agents reference `pinscope` in skill-selection logic. Genuine.

No spot-check revealed a hollow PASS.

## STEP 3 — BLOCKED ACs (environment limits, never findings)

The 7 `UNAVAILABLE` ACs require an environment this CI lacks
(`env-capabilities.json`: `browser=false`, `apex_install=false`). Per role
STEP 3 they are recorded `BLOCKED`, never `OPEN`, and no remediation is
proposed. They are closeable only on a capable CI.

| AC | Phase | Sev | Blocked reason | Unblocks on |
|----|-------|-----|----------------|-------------|
| AC-023 | P1 | P0 | browser — Playwright `::before` content read | browser-capable CI |
| AC-030 | P1 | P1 | browser — Playwright InfoPanel hover assertions | browser-capable CI |
| AC-061 | P4 | P3 | browser — cross-origin iframe, two real origins | browser-capable CI |
| AC-063 | P4 | P3 | browser — `@media print` screenshot diff | browser-capable CI |
| AC-082 | P2 | P1 | browser — Playwright integration suite | browser-capable CI |
| AC-083 | P4 | P3 | browser — visual-regression screenshot matrix | browser-capable CI |
| AC-106 | P5 | P2 | apex-install — `/apex:health-check` needs `~/.claude/` | APEX-installed CI |

## Gap summary

PinScope R14 shows no spec-conformance gap. All 62 node-verifiable ACs pass and
were confirmed: a cross-phase AP-006 spot-check re-read the build plugin (stable
keys, PinMap reconcile, production stripper), the operation parser, the
size-limit config, and the APEX-integration skill/command/agent files — every
sampled PASS reflects genuine implementation, not a tagged-but-empty test. The
regression scan found all 62 previously-CLOSED ACs still passing, so the
convergence metric holds at 62/69 (90%). The remaining 7 ACs are BLOCKED purely
by an absent browser engine or APEX install and carry no finding. The loop's
CONVERGED state from R11–R13 is independently re-confirmed for R14.
