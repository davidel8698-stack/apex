# PinScope Convergence Audit — Round 12 (PS-R12)

**Auditor:** spec-auditor (clean context, independent re-audit)
**North-Star:** `pinscope/SPEC.md` v2.0.0 — Appendix A, 69 AC rows
**Spec hash:** `sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`
**Date:** 2026-05-21
**Guard:** APEX learning AP-006 — "The Unchecked Audit." No prior round's reported
numbers are trusted; every figure below comes from a command executed in this round.

---

## 1. Reality Baseline

| Bucket | Count | Definition |
|--------|-------|------------|
| Closed (PASS) | 62 | `env:node` ACs whose mechanical check passed in `ac-results-R12.json` |
| Blocked (UNAVAILABLE) | 7 | ACs whose `env` (`browser` / `apex-install`) is absent per `env-capabilities.json` |
| Open (FAIL) | 0 | No AC failed its mechanical check |
| **Convergence** | **90%** | 62 / 69 acceptance criteria closed |

`env-capabilities.json` for this round: `browser:false`, `apex_install:false`,
`npm_registry:true`. The 7 blocked ACs are exactly the set whose matrix `env`
field is `browser` (AC-023, AC-030, AC-061, AC-063, AC-082, AC-083) or
`apex-install` (AC-106). No `env:node` AC is blocked, so the environment is not
masking any node-verifiable capability.

---

## 2. Carry-Forward Verification (harness re-run this round)

Both commands were executed fresh from `/home/user/apex/pinscope/`:

| Command | Result | Exit code |
|---------|--------|-----------|
| `npm test` | **257 tests passed**, 27 test files passed, 0 failed | **0** |
| `npm run typecheck` (`tsc --noEmit`) | clean, no diagnostics | **0** |

Targeted re-run of the two count-gated suites:

| Suite | Tests | SPEC threshold | Status |
|-------|-------|----------------|--------|
| `tests/unit/ast-transformer.test.ts` (AC-080) | 66 | >= 50 input/output pairs | satisfied |
| `tests/unit/operation-parser.test.ts` (AC-050 / AC-081) | 45 | >= 30 cases | satisfied |

`npm run size` (AC-073) was also re-run: exit 0, runtime dev bundle 1.84 kB vs the
80 kB limit. The mechanical `harness_ok:true` and `0 FAIL` verdict in
`ac-results-R12.json` is therefore confirmed against current code.

### Masked-FAIL spot-check (env:node PASS ACs)

A representative sample of the 62 PASS ACs was traced from the SPEC Appendix A row
to the actual source/test artifact to confirm the check genuinely exercises the
SPEC capability (not a trivially-true assertion):

| AC | SPEC capability | Artifact verified | Genuine |
|----|-----------------|-------------------|---------|
| AC-002 | `transformJSX` injects `data-pin="e_N"` | `tests/unit/ast-transformer.test.ts` ('injects data-pin starting at e_1 (AC-002)') | yes |
| AC-005 | stable `file:line:column` IDs | `tests/unit/ast-transformer.test.ts` (AC-005) | yes |
| AC-009 | `transformIndexHtml` strips PinScope | `tests/unit/plugin.test.ts` ('transformIndexHtml (AC-009)') | yes |
| AC-050/081 | operation-parser grammar coverage | `tests/unit/operation-parser.test.ts` (45 tests) | yes |
| AC-071 | hover→InfoPanel update < 8 ms | `tests/unit/runtime/perf.test.tsx` (AC-071) | yes |
| AC-073 | dev bundle < 80 KB | `npm run size` exit 0, 1.84 kB | yes |
| AC-100/102/104 | APEX-framework integration | `framework/apex-skills/pinscope.md` (5 headings), `framework/commands/apex/ui-phase.md` (PINSCOPE INSTRUMENTATION) | yes |

No masked FAIL was found: every sampled mechanical PASS is backed by a real test
that exercises the corresponding SPEC capability.

---

## 3. Findings

**None.** No `findings` entries this round.

| ID | AC | Severity | Title |
|----|----|----------|-------|
| — | — | — | (no findings) |

---

## 4. Assessment of the 7 BLOCKED Acceptance Criteria

For each blocked AC, the SPEC Appendix A row was read and the implementation +
test artifact located in the `pinscope/` (or `framework/`) tree. The question is
whether the AC is `BLOCKED` purely because the environment is missing, or whether
an artifact is genuinely ABSENT (which would be a real finding).

| AC | Env | Implementation artifact | Test / verify artifact | Implementation present | Correctly blocked |
|----|-----|-------------------------|------------------------|------------------------|-------------------|
| AC-023 | browser | `src/runtime/styles/badges.css.ts` — `[data-pin]::before { content: attr(data-pin) }`; injected by `src/runtime/components/PinBadges.tsx` | `tests/integration/pinscope.spec.ts` ('injects a data-pin badge … (AC-023)') reads `::before` content via Playwright | yes | yes |
| AC-030 | browser | `src/runtime/components/InfoPanel.tsx` — Dimensions/Spacing/Typography collapsible sections from `getComputedStyle`/`getBoundingClientRect` | `tests/integration/pinscope.spec.ts` ('hover opens the InfoPanel … (AC-030)') | yes | yes |
| AC-061 | browser | `src/runtime/utils/iframe-overlay.ts` — `isCrossOriginFrame` / `markCrossOriginFrames` / `isIframeLimited`; click-through outline+label overlay, no injection | `tests/unit/runtime/iframe-overlay.test.ts` (8 jsdom cases, 'Cross-origin iframe overlay (AC-061)') — runs green; matrix `kind:manual` because a true two-origin scenario needs real origins | yes | yes |
| AC-063 | browser | `src/runtime/styles/badges.css.ts` — `@media print { [data-pinscope-ui]{display:none} [data-pin]::before{display:none} }` | matrix `kind:manual` — print-emulation screenshot diff, needs a browser print engine | yes | yes |
| AC-082 | browser | `tests/integration/pinscope.spec.ts` — Playwright §14 checklist suite dropping PinScope into `examples/vite-react`; `playwright.config.ts` (testDir `./tests/integration`, chromium/firefox/webkit projects, `webServer`) | `@playwright/test ^1.60.0` in devDependencies | yes | yes |
| AC-083 | browser | `tests/integration/visual-regression.spec.ts` — §14 matrix (4 viewports × light/dark × host-css) via `toHaveScreenshot` | `playwright.config.ts` `toHaveScreenshot` config; matrix `kind:manual` artifact diff | yes | yes |
| AC-106 | apex-install | APEX integration edits present: `framework/apex-skills/pinscope.md`, `framework/commands/apex/ui-phase.md` (PINSCOPE INSTRUMENTATION), `ui-review.md` (PINSCOPE EVIDENCE), `architect.md`/`frontend.md` — all verified via AC-100/102/103/104 PASS this round | matrix `kind:manual` — `/apex:health-check` must run against APEX synced to `~/.claude/` | yes | yes |

**Conclusion of §4:** all 7 blocked ACs have their implementation genuinely
present in the source tree. Each is `BLOCKED` solely because the runtime
environment lacks a browser binary or an installed/synced APEX framework — not
because of any absent build artifact. No BLOCKED status is masking a build gap.

---

## 5. Verdict

**`NO_FINDINGS`.**

An independent R12 re-audit confirms a healthy code tree. The harness was re-run
in this round: 257 Vitest tests pass across 27 files (`npm test` exit 0) and
`tsc --noEmit` is clean (exit 0). The mechanical `ac-results-R12.json` verdict —
62 PASS / 7 UNAVAILABLE / 0 FAIL, `harness_ok:true` — is real: a spot-check sample
of `env:node` PASS ACs each traces to a test that genuinely exercises its SPEC
capability, and no masked FAIL exists. All 7 UNAVAILABLE ACs have a genuine
implementation artifact and are correctly blocked on a missing environment.

PinScope stands at **90% convergence (62/69)**; the remaining 7 ACs are
environment-blocked, not gap-blocked, and cannot close until a browser binary
(6 ACs) or an APEX install (1 AC) becomes available.
