# Audit Findings — PS-R18 (spec-conformance + free investigation)

**Round:** 18 · **Generated:** 2026-05-22T13:20:00Z
**Spec:** `pinscope/SPEC.md` v2.0.0 (FROZEN) · **Verdicts:** `ac-results-R18.json`
**Result:** 1 CONFIRMED off-matrix finding (P2) · 0 AC findings · 0 regressions · 7 BLOCKED

This was a convergence-confirmation round. STEP 1–4 had nothing to re-confirm
(62 PASS, 0 FAIL). The full STEP 5 12-axis sweep ran adversarially against the
re-read tree and surfaced **one genuine off-matrix gap** in the §10-C history
persist path. The loop must **not** declare convergence this round: an open P2
(`F-18-01`) remains.

---

## STEP 1–4 — AC re-confirmation, environment limits, regression scan

- **STEP 1–2 (re-confirm FAIL list):** `ac-results-R18.json` reports **62 PASS,
  0 FAIL, 7 UNAVAILABLE**. There is no `FAIL` list to independently re-confirm;
  zero AC findings.
- **STEP 3 (environment limits):** the 7 `UNAVAILABLE` ACs are recorded as
  `BLOCKED`, never `OPEN` — their verify methods need a browser engine or an
  APEX `~/.claude/` install, both absent (`env-capabilities.json`:
  `browser=false`, `apex_install=false`). No remediation is proposed for them.
- **STEP 4 (regression scan):** every AC the loop previously recorded `CLOSED`
  still shows `PASS` in `ac-results-R18.json`. **Zero regressions.**

---

## Investigation findings (STEP 5 — off-matrix gap hunt)

### P2

#### F-18-01 — `.pinscope/history.json` is double-written and lossy on the §10-C operation flow `[CONFIRMED]`

- **Axis:** 8-data-schemas / 11-integration-surface (§8.6, §9.4, §10-C)
- **Current state:** The §10-C operation flow appends to the shared
  `command.history` HistoryManager **twice** per operation, and persists
  `.pinscope/history.json` with a **lossy, lagging** payload.
  `CommandBar`'s Enter handler (`CommandBar.tsx:111-125`) appends a placeholder
  entry `{ parsed: null, result: 'sent' }`, then synchronously calls
  `persistHistory(history.list())` (`CommandBar.tsx:121`) which POSTs the full
  list to `/__pinscope/history`. It then calls `onSubmit` →
  `PinScope.onSubmit` → `command.bridge.send` (`PinScope.tsx:208`) →
  `ClaudeBridge.send` appends a **second** entry
  `{ parsed: <Operation>, result: 'sent' }` to the **same** `command.history`
  (`ClaudeBridge.ts:35`). `ClaudeBridge` never calls `persistHistory`, and
  `PinScope.tsx` never re-POSTs history after a send.
- **Gap:** §9.4 defines a history entry's `parsed` field as the parsed
  Operation; §10-C ("Operation via CommandBar … clipboard + history") and §8.6
  ("History persisted to `.pinscope/history.json`") require the persisted
  history to record the operation. Two defects:
  1. **Duplication** — every operation produces two `command.history` rows
     (the `parsed:null` CommandBar placeholder plus the `parsed:<Operation>`
     ClaudeBridge entry), so the persisted file carries doubled entries.
  2. **Loss / lag** — ClaudeBridge's real `parsed:<Operation>` entry is never
     persisted when it is created; it reaches disk only if a *later* CommandBar
     submit happens to trigger another `persistHistory`. The most recent
     operation's parsed record never lands on disk, and a session's final
     operation is permanently unpersisted.
- **Why STEP 1–4 misses it:** AC-053 verifies `ClaudeBridge.send` in
  **isolation** (`claude-bridge.test.ts:77` asserts `data.entries.length`
  `toBe(1)` against a directly-constructed `HistoryManager`); AC-054 only
  measures autocomplete latency. Neither exercises the persisted-file content
  of the full `CommandBar → onSubmit → ClaudeBridge` path, so the gap is
  invisible to the 69-AC matrix.
- **`re_read` check:**
  > Live trace: a temp test `tests/unit/runtime/__trace2.test.tsx` rendered the
  > real `<PinScope/>`, stubbed `fetch`, submitted `e_7.bg → red` then
  > `e_7.padding → 8px` via the CommandBar, captured every `/__pinscope/history`
  > POST body → `historyPosts=2 lastPersistedEntries=3 kinds=[null,op:sent,null]`
  > (temp file deleted after the run; a single-submit trace gave
  > `historyPosts=1 finalEntryCount=1 parsedKinds=[null]`).
  > Static cross-check: `grep -n 'persistHistory' src/runtime/components/CommandBar.tsx`
  > → defined L44, called ONLY at L121 (CommandBar Enter handler);
  > `grep -rn 'persistHistory' src` → no call site outside `CommandBar.tsx`.
  > `grep -n 'history.append' src/runtime/managers/ClaudeBridge.ts` → L35
  > (`parsed: operation, result: 'sent'`) and L43 (`result: 'failed'`);
  > `ClaudeBridge` has no `fetch`/`persistHistory`, and `PinScope.tsx` `onSubmit`
  > (L172-217) never re-POSTs history after `bridge.send`. `CommandBar.tsx:114-120`
  > builds the placeholder entry with `parsed: null`.

---

## BLOCKED (environment-limited — not findings)

| AC | Phase | Sev | Reason |
|---|---|---|---|
| AC-023 | P1 | P0 | `browser` unavailable — Playwright `::before` content read needs a browser engine. |
| AC-030 | P1 | P1 | `browser` unavailable — Playwright hover/InfoPanel assertion needs a browser engine. |
| AC-061 | P4 | P3 | `browser` unavailable — cross-origin iframe needs two real origins (matrix `kind=manual`). |
| AC-063 | P4 | P3 | `browser` unavailable — `@media print` rendering needs a browser print engine (`kind=manual`). |
| AC-082 | P2 | P1 | `browser` unavailable — Playwright integration suite needs a browser binary (`kind=manual`). |
| AC-083 | P4 | P3 | `browser` unavailable — visual-regression screenshots need a browser (`kind=manual`). |
| AC-106 | P5 | P2 | `apex-install` unavailable — `/apex:health-check` needs APEX synced to `~/.claude/` (`kind=manual`). |

These 7 are closeable only on a capable CI; recorded `BLOCKED`, never `OPEN`.

---

## Carry-over investigated — VERIFY-R17 mutation survivor M1

**Subject:** `or-to-and` mutant at `src/runtime/hooks/useSelectedElement.ts:24`
— `if (!pinId || typeof document === 'undefined') return null;` inside
`resolveSelected`.

**Verdict: BENIGN coverage margin — NOT an off-matrix finding.**

`resolveSelected(pinId)` returns a `HoveredElement | null` view of the pin id
the `SelectionManager` holds. The original `||` guard is correct — bail out
(return `null`) if **either** the pin id is falsy **or** there is no `document`.
The mutant `&&` only diverges from `||` when exactly one operand is true. Under
jsdom/happy-dom `typeof document` is never `'undefined'`, so the second operand
is always false and the predicate reduces to `!pinId` (original) vs
constant-false (mutant). When the split matters — a `null` `pinId` in a
defined-document env, which **is** reachable (the lazy `useState` initializer at
`useSelectedElement.ts:46` calls `resolveSelected(manager.selectedPin)`, and
`selectedPin` is `null` on a fresh mount with no `#select=` hash) — the original
returns `null` at L24, while the mutant falls through to
`document.querySelector('[data-pin="null"]')` at L25, which matches no element,
so the `!(el instanceof HTMLElement)` guard at L26 returns `null` anyway. **Both
paths produce an identical `null` for every reachable input** — the mutant is
behaviorally equivalent on this tree. No behavioral gap, no dead path, no
swallowed failure; consistent with the VERIFY-R17 "non-blocking coverage
finding" adjudication. The advised `resolveSelected(null)`-returns-null test
would kill the mutant, but it closes a coverage hole only — not a defect.

---

## Coverage ledger

**Axes swept this round (12 / 12):**

1. Build pipeline — AST `data-pin` injection, `getElementName` across 3 JSX
   name kinds, `excludeTags`/`filePattern`/`excludePattern` gates.
2. Pin-ID stability — `file:line:column` `stableKey`, `getOrAssign` monotonic +
   never-reused, `reconcile` soft-delete.
3. Production-zero — `vite-react` dist grep = 0 PinScope bytes; `transformIndexHtml`
   strip; AC-010/074 PASS.
4. Runtime isolation — `createPortal` to `document.body`, `data-pinscope-ui=root`
   wrapper, z-index, prod `NODE_ENV` null guard.
5. Inspection layer — `useHoveredElement` HUD-escape walk, InfoPanel, PinBadges,
   TopBar live state-override.
6. Measurement / snapshot — `MeasurementTool` render, `SnapshotManager` /
   `EndpointSnapshotStore` persist + `flush()` error surfacing.
7. Operation protocol — `operation-parser` grammar (all §11 forms + typed
   errors), `select`-command canonical-manager routing.
8. Data schemas — PinMap §9.1 / Snapshot §9.2 / Operation §9.3 / History §9.4;
   **History persist path traced end-to-end → F-18-01.**
9. Edge cases — §12 set; `catch`-block swallowed-error hunt.
10. Performance budgets — §13; machine AC-070..076 PASS.
11. Integration surface — `src/index.ts` public API, Vite/Next/Webpack entry
    points, §10 flow seams B/C/D.
12. Phase DoD — §16 DoD items P1–P5; §17 APEX integration.

**Spec sections reviewed:** §6, §7, §8, §9, §10, §11, §12, §13, §14, §15, §16,
§17, Appendix A (69 ACs), Appendix B.

**Blind spots:** the 7 `BLOCKED` ACs (browser / apex-install) are unverifiable
in this environment — visual rendering, cross-origin iframes, `@media print`,
the Playwright integration suite, and `/apex:health-check` were reviewed by code
read only, not exercised.

---

## Round summary

PS-R18 is the fourth round of the R15–R17 remediation arc. STEP 1–4 are clean
(62 PASS, 0 FAIL, 0 regressions; 7 BLOCKED). The expectation entering the round
was zero confirmed findings and convergence. That expectation was **not
rubber-stamped**: the full 12-axis STEP 5 sweep ran against the re-read tree and
found **one genuine, previously off-matrix defect** — `F-18-01`, a P2 in the
§10-C history persist path. `.pinscope/history.json` is both **duplicated** (a
`parsed:null` CommandBar placeholder plus the `parsed:<Operation>` ClaudeBridge
entry per operation) and **lossy** (the ClaudeBridge entry is persisted only
when a later submit re-POSTs, so the final operation of a session never reaches
disk). It is invisible to the matrix because AC-053 tests `ClaudeBridge.send` in
isolation and AC-054 only measures latency. The carry-over R17 mutation survivor
(M1, `useSelectedElement.ts:24`) was investigated directly and adjudicated a
**benign, behaviorally-equivalent coverage margin** — not a finding. The loop
**must not converge** this round: one open P2 (`F-18-01`) goes to the
remediation planner.
