# PinScope Spec-Conformance Audit — Round R19

**Generated:** 2026-05-22T13:50:00Z
**Auditor:** `spec-auditor` (STEP 1–5, context-isolated)
**North-Star:** `pinscope/SPEC.md` v2.0.0 (FROZEN)
**Machine input:** `ac-results-R19.json` — 62 PASS · 7 UNAVAILABLE · 0 FAIL · `harness_ok: true` · `skip_markers: 0`

---

## Verdict

**Zero CONFIRMED findings.** R19 is a convergence-confirmation round and the full
STEP 5 12-axis sweep — run independently and adversarially against a re-read of
the implementation tree — found no off-matrix behavioral gap, dead path,
swallowed failure, or hollow implementation that the 69 ACs miss.

One **P3 SUSPECTED** investigation finding is recorded: a benign test-coverage
margin (the R18 carry-over mutant), explicitly NON-BLOCKING. It is reported
because STEP 5 does not filter early, not because the shipping code is wrong.

The off-matrix finding stream falls 11 → 8 → 3 → 1 → **0 confirmed**. The tree
matches its frozen North-Star.

---

## STEP 1–4 — AC re-confirmation & regression scan

- **STEP 1–2 (re-confirm FAILs):** `ac-results-R19.json` reports **0 FAIL**.
  There is no machine-flagged gap to re-confirm; no AC finding is emitted.
- **STEP 3 (environment limits):** 7 ACs are `UNAVAILABLE` — recorded as
  `BLOCKED`, never `OPEN`. See the BLOCKED list below.
- **STEP 4 (regression scan):** every AC the loop previously recorded `CLOSED`
  shows `PASS` in `ac-results-R19.json`; the 7 `BLOCKED` ACs show `UNAVAILABLE`
  for their declared `browser`/`apex-install` env reason — expected, not
  regressions. Independent re-run: `npx vitest run` → **303 passed (30 files)**;
  `npx tsc --noEmit` → exit 0. **0 regressions.**

---

## STEP 5 — Free investigation (off-matrix gap hunt)

### P3 — SUSPECTED

#### F-19-01 · Axis 7 — un-asserted `measure`/`snapshot` margin of `isLocalOnlyCommand`

*Carry-over from `VERIFY-R18.md`'s non-blocking mutation observation, investigated directly.*

- **Current state:** `src/runtime/components/CommandBar.tsx:49` —
  `isLocalOnlyCommand` returns
  `kind === 'select' || kind === 'measure' || kind === 'snapshot'`. The
  **production code is correct**: a `snapshot` (or a valid `measure ... to ...`)
  command typed into the CommandBar correctly returns `true` and receives its
  single recall-supporting `parsed: null` history entry per SPEC §8.6/§9.4.
- **Gap (coverage margin, not behavior):** no test submits a *valid*
  `snapshot`-kind or `measure e_N to e_M`-kind command through the CommandBar
  Enter path. `controls.test.tsx` submits only `select e_1` (exercises the 1st
  disjunct) and `measure e_2 e_3` — the latter is **invalid grammar**
  (`RE_MEASURE = /^measure\s+(e_\d+)\s+to\s+(e_\d+)$/i` requires the `to`
  keyword), so `parseCommand` *throws* and `isLocalOnlyCommand` returns `true`
  via its `catch` branch — L49's `measure`/`snapshot` disjuncts are never
  reached. Hence the R18 `or-to-and` mutant (`select || (measure && snapshot)`,
  which `&&`-binding reduces to `select`-only) survives. This is a **benign
  coverage margin** — there is no behavioral gap, dead path, or swallowed
  failure; the shipping path is correct. Recorded P3/SUSPECTED so the planner
  may close the margin (a `snapshot foo` + `measure e_2 to e_3` CommandBar Enter
  test would kill the mutant). **It does not block convergence.**
- **`re_read`:**
  ```
  # Empirically reproduce mutant survival, then restore:
  cp src/runtime/components/CommandBar.tsx /tmp/CommandBar.orig.tsx
  sed -i "s/|| kind === 'measure' ||/|| kind === 'measure' \&\&/" \
    src/runtime/components/CommandBar.tsx
  npx vitest run tests/unit/runtime/controls.test.tsx \
    tests/unit/runtime/history-persist-ownership.test.tsx   # -> 17/17 PASS (mutant survives)
  cp /tmp/CommandBar.orig.tsx src/runtime/components/CommandBar.tsx  # restored
  # Confirm no valid snapshot/measure command is ever submitted:
  grep -n 'snapshot\|measure\|select' tests/unit/runtime/controls.test.tsx
  #   -> only 'select e_1' (L184,L237) and 'measure e_2 e_3' (L260, INVALID grammar)
  grep -n 'RE_MEASURE' src/runtime/parsers/operation-parser.ts
  #   -> /^measure\s+(e_\d+)\s+to\s+(e_\d+)$/i  — 'measure e_2 e_3' does not parse
  ```

*(No P0, P1, or P2 investigation findings — none found after the 12-axis sweep.)*

---

## BLOCKED — environment-limited ACs (never `OPEN`)

| AC | Sev | Reason |
|---|---|---|
| AC-023 | P0 | `env: browser` unavailable — Playwright `::before` content read needs a browser engine. |
| AC-030 | P1 | `env: browser` unavailable — Playwright InfoPanel hover assertion needs a browser. |
| AC-061 | P3 | `verify: manual` / `browser` — cross-origin iframe needs two real origins. |
| AC-063 | P3 | `verify: manual` / `browser` — `@media print` rendering needs a browser print engine. |
| AC-082 | P1 | `verify: manual` / `browser` — Playwright integration suite, browser binary unavailable. |
| AC-083 | P3 | `verify: manual` / `browser` — visual-regression screenshots need a browser. |
| AC-106 | P2 | `env: apex-install` unavailable — `/apex:health-check` needs APEX synced to `~/.claude/`. |

All 7 are closeable only on a capable CI (`env-capabilities.json`:
`browser=false`, `apex_install=false`). No remediation is proposed for any
`BLOCKED` AC.

---

## Coverage ledger

**12 axes swept** (SPEC §1–§17), each re-read against the code and judged on
"does it work end to end, with nothing swallowed":

| # | Axis | Result |
|---|---|---|
| 1 | Build pipeline | `transformJSX` injects `data-pin`; enabled/`filePattern`/`excludePattern` gating + `excludeTags`/`data-pin-ignore` honored. Sound. |
| 2 | Pin-ID stability | `stableKey = file:line:column`; `getOrAssign` monotonic; `reconcile` soft-deletes without ID reuse. Sound. |
| 3 | Production-zero | `transformIndexHtml`→`stripPins`; AC-010/AC-074 build-grep over `dist/` returns 0. Sound. |
| 4 | Runtime isolation | `createPortal` to `document.body` under `[data-pinscope-ui=root]`; z-index `2147483645–647`. Sound. |
| 5 | Inspection layer | `useHoveredElement` walks to nearest `[data-pin]` ancestor; InfoPanel sections; PinBadges/VoidBadges. Sound. |
| 6 | Measurement layer | Rulers, Crosshair, GridOverlay (4 modes), MeasurementTool (`measure()` dx/dy/diagonal/gap). Sound. |
| 7 | Operation protocol | `parseCommand` covers all §11 grammar forms + typed `OperationParseError`. One P3 coverage margin → F-19-01. |
| 8 | Data schemas | Operation/Snapshot/History types match §9; 32 `TRACKED_STYLES`; history persist body `{version,entries}`. Sound. |
| 9 | Edge cases | `iframe-overlay`, `shadow-dom`, `throttle`, `long-press`, `rect-math`, `screenshot` utils present. Sound. |
| 10 | Performance budgets | AC-070/071/072/073/074/075/076 all PASS; `html2canvas` dynamically imported (I-4). Sound. |
| 11 | Integration surface | Vite plugin functional; `package.json` exports map present; Next/Webpack scoped P4/P5 per §18 I-1 (see note). |
| 12 | Phase DoD | P1–P5 DoD ACs all PASS or BLOCKED-by-env. Sound. |

**Sections reviewed:** §3–§18, Appendix A (69 ACs), Appendix B (loop contract).

**Blind-spot notes (recorded, not findings):**

- `withPinScope` (`next.ts`) and `PinScopeWebpackPlugin` (`webpack.ts`) carry
  explicit *"a later round registers the data-pin loader"* comments and do not
  yet inject `data-pin`. **Not an off-matrix finding:** §18 resolution **I-1**
  explicitly scopes the Next.js wrapper and Webpack plugin as **P4/P5**, and the
  only AC naming them — **AC-092** — requires solely that they "are importable
  and return valid config objects" (AC-092 PASS). The frozen spec does not
  require functional Next/Webpack injection at north-star v2.0; the "later
  round" comments match the spec's phased intent.
- `package.json` `size-limit` config has a single entry (`runtime (dev)`,
  `80 KB`) and lacks discrete `<25 KB` gzip / `<30 KB` P1 sub-budget / prod
  `0-byte` entries that §13's prose table enumerates. **Not an off-matrix
  finding:** AC-073 verify is `npm run size` exit 0 and AC-074 verify is the
  `dist/` build-grep (AC-074 is explicitly "covered by AC-010 at artifact
  level") — both PASS. §13 is non-normative prose; AC-073/074 are the normative
  contract and they pass.

---

## Round summary

R19 is a convergence-confirmation round and the audit confirms it. STEP 1–4
found nothing to re-confirm (0 machine FAILs), 0 regressions across 62 `CLOSED`
ACs, and 7 correctly-`BLOCKED` env-limited ACs. The STEP 5 12-axis free
investigation ran in full against a fresh re-read of `pinscope/src/` and
`pinscope/tests/` and found **zero confirmed off-matrix findings** — every
spec-named mechanism is invoked, no `catch` block swallows a failure (parse,
clipboard, history-persist, and snapshot-persist failures are all surfaced on
the console), and every end-to-end §10 flow connects. The single carry-over
item — the R18 `or-to-and` mutant at `CommandBar.tsx:49` — was investigated
directly and empirically: the mutant survives, but the production code is
correct and the survival is a benign un-asserted test margin in the
`measure`/`snapshot` recall path, recorded as **F-19-01 (P3, SUSPECTED,
non-blocking)**. With 0 OPEN findings at P0–P2 and every Phase-DoD AC `PASS` or
`BLOCKED`-by-env, the tree has reached its frozen North-Star — the loop is clear
to converge.
