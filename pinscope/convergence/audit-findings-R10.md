# PinScope Audit — PS-R10 (independent carry-forward re-audit)

> **Round:** PS-R10 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** independent re-audit by a clean-context `spec-auditor`. The
> harness was re-run from `pinscope/`; every Appendix-A AC was diffed against
> the *current* `pinscope/` reality tree. No prior remediation reasoning
> assumed; the tree was not presumed healthy. Guards APEX learning AP-006
> ("The Unchecked Audit").

## Reality baseline

62 CLOSED, 7 BLOCKED, 0 OPEN per `STATUS.md` (90%). 249 tests green across
26 test files. `ac-results-R10.json` reports 62 PASS, 7 UNAVAILABLE, 0 FAIL
(`harness_ok: true`).

## Carry-forward verification (AP-006)

The harness was re-run against *current* code, not trusted from a prior claim:

- `npm test` → **249 passed (249), 26 files passed (26)**, exit 0. (The pin-map
  suite emits an expected `assertThrows` stack trace; the suite is green 9/9.)
  Note: the count rose from 241 (R9 baseline) / 248 (STATUS R9 row) to 249 —
  no closure regressed.
- `npm run typecheck` (`tsc --noEmit`, `strict: true`) → **clean**, exit 0.
- PS-R1–R9 closures re-confirmed: every `env: node` AC still resolves to a
  present, passing test/check against current code.

## Findings

The 0-FAIL mechanical verdict holds for every `env: node` AC — no automatable
FAIL is masked by the matrix. However, an independent re-read of two
`env: browser`, `manual`-kind ACs that the harness reports `UNAVAILABLE`
shows their *implementation is absent* — the `BLOCKED` status (which the
`STATUS.md` legend defines as "implementation built + test authored") is
masking a real gap. The harness cannot catch these because their `verify.env`
is `browser`; the re-read audit is the intended guard.

| Finding | AC | Severity | Disposition |
|---------|-----|----------|-------------|
| F-10-01 | AC-061 | P3 | Cross-origin iframe outline+label rendering is **not implemented**. No code in `src/runtime/` detects iframe elements or renders the required "outline + label only" overlay (`grep -rEin 'iframe' src/ tests/` → zero hits). The AC requires an active runtime rendering behavior; "the transformer never injects across documents" is *not* the same thing. By contrast the sibling edge-case AC-060 (Shadow DOM) has a real impl in `src/runtime/utils/shadow-dom.ts`. Currently `BLOCKED` — should be `OPEN` (or `BACKLOG` by explicit user decision, as a P3). |
| F-10-02 | AC-083 | P3 | The visual-regression suite is **not authored**. `tests/integration/` contains only `pinscope.spec.ts`, a functional Playwright assertion suite with zero screenshot/visual-diff calls (`toHaveScreenshot`, snapshot diff). AC-083 requires "a visual-regression suite ... across the §14 matrix" with "CI artifact diff". The browser env is genuinely unavailable, but the *test artifact itself* is missing — so `BLOCKED` ("test authored") is inaccurate. Currently `BLOCKED` — should be `OPEN` (or `BACKLOG`, P3). |

Both findings are P3. Per the Appendix-B loop contract, P3 findings "may be
moved to `BACKLOG` by explicit user decision" — they do not block the loop's
terminal condition (zero OPEN at P0–P2). They are surfaced here so the
decision is explicit rather than silently absorbed into `BLOCKED`.

## Assessment of the 7 BLOCKED ACs

Each was opened in `ac-matrix.json` and cross-read against Appendix A.

| AC | env | kind | Implementation evidence | Correctly blocked |
|------|-----|------|--------------------------|-------------------|
| AC-023 | browser | vitest-tag | Badge `::before` rule in `src/runtime/styles/badges.css.ts:5`; `data-pin` injected by `src/plugin/ast-transformer.ts`; Playwright test `tests/integration/pinscope.spec.ts:13`. Impl present. | yes — env-only |
| AC-030 | browser | vitest-tag | `src/runtime/components/InfoPanel.tsx:148` renders Dimensions/Spacing/Typography sections; Playwright hover test `pinscope.spec.ts:24`. Impl present. | yes — env-only |
| AC-061 | browser | manual | **No implementation** — see finding F-10-01. | **no — masks absent impl** |
| AC-063 | browser | manual | `@media print { [data-pinscope-ui]{display:none} [data-pin]::before{display:none} }` present in `src/runtime/styles/badges.css.ts:37`. Needs a browser print engine. Impl present. | yes — env-only |
| AC-082 | browser | manual | Playwright integration suite present at `tests/integration/pinscope.spec.ts` + `playwright.config.ts`. Needs a browser binary. Impl present. | yes — env-only |
| AC-083 | browser | manual | **No visual-regression suite authored** — see finding F-10-02. | **no — masks absent test** |
| AC-106 | apex-install | manual | `/apex:health-check` command (`framework/commands/apex/health-check.md`) invokes `~/.claude/scripts/self-test.sh` (TEST 0e). Needs APEX synced to `~/.claude/`. Impl present. | yes — env-only |

5 of the 7 (AC-023, AC-030, AC-063, AC-082, AC-106) are correctly `BLOCKED`:
their implementation is present and only the `verify.env` (`browser` /
`apex-install`) is missing here. AC-061 and AC-083 claim env-blockage but
their underlying implementation/test artifact is genuinely absent — those are
the two findings above. AC-061, AC-063, AC-082, AC-083 and AC-106 are
`manual`-kind ACs: they can never close via an automated proxy and require an
explicit `manual-attest` on a capable environment.

## Verdict

**FINDINGS_PRESENT.** Two P3 findings (F-10-01 AC-061, F-10-02 AC-083):
`BLOCKED` ACs whose implementation/test is absent rather than merely
env-gated. Both are P3, so the loop's terminal condition (zero OPEN at P0–P2)
is unaffected — but the audit must surface them. The 5 other BLOCKED ACs are
correctly env-blocked with implementation present. The `env: node` reality
tree (62/62) is clean; no closure regressed; harness re-run independently
confirmed (249 tests, typecheck clean).
