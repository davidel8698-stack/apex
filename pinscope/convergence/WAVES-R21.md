# Wave Map — PS-R21

## Plan validation

`ACCEPTED`

Gate result for `REMEDIATION-PLAN-R21.md` (4 R-items, R-21-01 … R-21-04):

- **Mandatory sections.** All four R-items carry the six mandatory sections —
  Ecosystem analysis, Execution plan, Acceptance criteria, Definition of Done,
  Dependencies, Risk assessment. R-21-04 additionally carries a `### Resolution`
  block; that is an extra (authorized for the SUSPECTED STEP-1-eligible
  investigation item), not a substitute, so no section is missing.
- **Root cause, not symptom.** R-21-01/02/03/04 all trace to one shared root
  cause the plan calls out explicitly: `PinScopeHud` in
  `pinscope/src/runtime/PinScope.tsx` never wires the imperative HUD mechanisms
  (`long-press.ts`, `shadow-dom.ts`, `throttle.ts`, `iframe-overlay.ts`) that
  the dormant-mechanism findings expose — same false-PASS class R-20-01/02/03
  began closing last round. Each fix mounts/wires the missing mechanism, not a
  symptom patch (e.g. R-21-01 adds the touch `useEffect` + compact-viewport
  branch; R-21-02 adds the `markShadowHosts` sweep + `MutationObserver` +
  `InfoPanel` limited-inspection row; R-21-03 adds the `isHeavyPage` gate in
  `useHoveredElement` + skip-small-badge sweep; R-21-04 is a SUSPECTED
  investigation R-item with an explicit STEP-1 confirm-or-refute branch,
  appropriate for a SUSPECTED finding, not a symptom fix).
- **Definition of Done.** Every DoD is mechanically checkable by a reader who
  never saw the change: named RTL describe blocks with required red→green
  named tests (R-21-01 three tests; R-21-02 two tests; R-21-03 two tests;
  R-21-04 one test on the confirmed branch, `git diff --stat 0 files` on the
  refuted branch), grep predicates over `pinscope/src/`, and `npm test` /
  `npm run typecheck` exit codes. None merely restates the finding; none says
  "looks right".
- **No silent scope reduction.** `audit-findings-R21.json` carries
  `findings: []`, `investigation_findings` = F-21-01..04, `open: 0`,
  `regressions: 0`, `confirmed: 3`, `suspected: 1`. The plan maps exactly one
  R-item to each investigation finding (R-21-01↔F-21-01, R-21-02↔F-21-02,
  R-21-03↔F-21-03, R-21-04↔F-21-04). No AC findings or narrative blocking
  findings exist this round; nothing owed there. No finding dropped.
- **No line-number anchors.** A scan of the plan body for `\.(tsx|ts|md|sh|json):[0-9]+`
  and for `lines?\s*[0-9]+` patterns returns zero hits. The plan body uses
  content anchors only (`PinScopeHud`, `createPortal`, `useEffect` (empty deps),
  `useSelectedElement`, `LongPressDetector`, `isCompactViewport`,
  `MOBILE_BREAKPOINT=768`, `markShadowHosts`, `SHADOW_ATTR`, `isShadowLimited`,
  `MutationObserver`, `useHoveredElement`, `isHeavyPage`,
  `HEAVY_PAGE_INTERVAL_MS=33`, `shouldSkipBadge`, `data-pin-skipbadge`,
  `markCrossOriginFrames`, `IFRAME_ATTR`, the `<div data-pinscope-ui="root">`
  block, the `!hudVisible` branch, etc.). Line numbers appear only inside the
  cited audit findings (`PinScope.tsx (353 lines)`, `useHoveredElement.ts
  (54 lines)`, `edge-cases.test.ts (line 48,57)`, `operation-builder.ts:52`,
  `:93`, etc.), which is permitted by REMEDIATION-STYLE.md (audit findings are
  frozen snapshots).

The plan is scheduled below.

## Dependency analysis

Files touched, by R-item (derived from each plan's Execution plan section):

- **R-21-01** — `pinscope/src/runtime/PinScope.tsx` (add `LongPressDetector` +
  `isCompactViewport` imports; add a touch-listener `useEffect` registering
  `touchstart`/`touchend` on `document` that routes tap/long-press through
  `selectPin`; add an early-return compact-viewport branch in the visible-HUD
  `createPortal` tree adjacent to the existing `!hudVisible` branch).
- **R-21-02** — `pinscope/src/runtime/PinScope.tsx` (add `markShadowHosts`
  import; add a new `useEffect` performing an initial sweep + installing a
  `MutationObserver` on `document.body` whose callback re-sweeps; cleanup
  disconnects),
  `pinscope/src/runtime/components/InfoPanel.tsx` (add `isShadowLimited`
  import; render an additive `<div data-pinscope-shadow-limited>limited
  inspection</div>` row when `isShadowLimited(hovered.element)` is true).
- **R-21-03** — `pinscope/src/runtime/hooks/useHoveredElement.ts` (add
  `isHeavyPage`, `HEAVY_PAGE_INTERVAL_MS`, `throttle` imports; gate the hover
  resolution on `isHeavyPage(documentPinCount)` and route the heavy branch
  through a `throttle(resolve, HEAVY_PAGE_INTERVAL_MS)`-wrapped callback while
  preserving the existing rAF path on the non-heavy branch),
  `pinscope/src/runtime/PinScope.tsx` (add a `useEffect` that on a heavy page
  sweeps `[data-pin]` and stamps `data-pin-skipbadge` on pins whose
  `getBoundingClientRect()` satisfies `shouldSkipBadge`, plus an additive
  `<style data-pinscope-skip-badge>` block injected inside the visible-HUD
  `createPortal` tree hiding `[data-pin-skipbadge]::before`).
- **R-21-04** — no `src/` file in the STEP-1 phase. STEP-2 branch lands in
  `pinscope/src/runtime/PinScope.tsx` only if STEP-1 confirms in-scope; if
  refuted, `### Resolution` closes the R-item with `git diff --stat` showing
  zero `pinscope/src/` files changed.

Blocking relationships:

- **No true logical dependency exists between any two R-items.** None reads
  another's *output* in its final form; each adds an independent, additive
  piece to `PinScopeHud` (or to `InfoPanel.tsx` / `useHoveredElement.ts`).
  All four DoDs are mechanically checkable in isolation against their own
  named tests.
- **One sequencing-only dependency: R-21-04 → R-21-02.** R-21-04's STEP-2
  branch is described in the plan as "wire `markCrossOriginFrames(document)`
  into the same `useEffect` block R-21-02 installs in `PinScopeHud` — one
  observer, two sweeps". For that fold-in to be possible, R-21-02's
  `useEffect` body must already exist. This makes R-21-04 schedulable only
  after R-21-02 has landed. (If R-21-04's STEP-1 refutes and the Resolution
  branch is taken, no code is edited and the sequencing constraint becomes
  vacuous; the scheduler still places R-21-04 after R-21-02 to keep the
  STEP-2 branch always-reachable.)
- **Soft co-mount hint: R-21-03's `MutationObserver` may share R-21-02's.**
  The plan calls this out as a wave-executor coalescing decision (R-21-02
  ecosystem note 8; R-21-03 Execution plan order-of-operations). It is not a
  scheduler-level dependency — R-21-03's DoD passes whether it installs its
  own observer or piggybacks on R-21-02's. The scheduler still places R-21-03
  after R-21-02 for the same reason as R-21-04 (the optional fold-in must be
  reachable).
- **Write-serial coupling (the binding constraint).** R-21-01, R-21-02,
  R-21-03 (and conditionally R-21-04 STEP-2) all modify
  `pinscope/src/runtime/PinScope.tsx`. STEP 3's one-file-one-owner-per-wave
  rule forbids two of them sharing a wave. The plan prose suggests they
  "share the wave and serialize on the `PinScopeHud` body"; STEP 3 governs
  and overrides that — they must be split across waves. This is a
  write-serialization ordering, not a logical dependency: the scheduler
  imposes the order to keep `PinScope.tsx` single-owner per wave.
- **Chosen serialization order: R-21-02 → R-21-03 → R-21-01 → R-21-04.**
  R-21-02 first so its `useEffect` + `MutationObserver` lands as the shared
  host (R-21-03's skip-small-badge sweep and R-21-04's STEP-2 cross-origin
  sweep both want to fold into it). R-21-03 second so its skip-small-badge
  `useEffect` lands while the host observer is fresh. R-21-01 third — order-
  neutral; its touch-listener `useEffect` and compact-viewport branch are
  additive and independent. R-21-04 last so its STEP-1 verdict can observe
  the final shape of R-21-02's `useEffect` (and, if STEP-2 fires, fold into
  it without contention).
- **Layering (`pinscope/SPEC.md` §1–§17).** All four R-items are §7 runtime
  fixes (R-21-02 also touches §8 `InfoPanel.tsx`; R-21-03 also touches §7
  `useHoveredElement.ts`). No build-module → runtime → APEX-integration
  cross-layer ordering is triggered this round.

## Waves

Four waves. Each wave carries exactly one `PinScope.tsx` owner; sibling files
(`InfoPanel.tsx` in W1, `useHoveredElement.ts` in W2) ride along with their
owning R-item because they have no other R-21 contender. Wave sizes are below
the 5–8 target only because the dominant constraint this round is write-
serialization on a single file — three confirmed R-items contend for
`PinScope.tsx` and cannot be parallelized, and R-21-04's STEP-2 branch may
contend for it too.

### Wave 1 — R-21-02

- **R-21-02** — files: `pinscope/src/runtime/PinScope.tsx`,
  `pinscope/src/runtime/components/InfoPanel.tsx`.
- One-owner check: sole R-item in the wave. Both files are single-owner;
  no collision.
- Dependency check: R-21-02 has no upstream R-item dependency. Placed first
  so its `useEffect` + `MutationObserver` becomes the host for the optional
  R-21-03 / R-21-04 fold-ins in later waves.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0 and
  `cd pinscope && npm test` is green (309+ tests, 0 fail); R-21-02's named
  RTL describe block `R-21-02 — Shadow-DOM marking + InfoPanel limited-
  inspection report` is green with both named tests transitioned red→green
  (initial-sweep + post-mount MutationObserver re-sweep + observer-
  disconnected-after-unmount; `[data-pinscope-shadow-limited]` row present
  over a shadow host and absent over a non-shadow pin); no "observer leaked
  after unmount" React warning. Wave 2 does not start until this gate passes.

### Wave 2 — R-21-03

- **R-21-03** — files: `pinscope/src/runtime/PinScope.tsx`,
  `pinscope/src/runtime/hooks/useHoveredElement.ts`.
- One-owner check: sole R-item in the wave — each of the two files has
  exactly one owner. `PinScope.tsx` was owned by R-21-02 in W1 and is
  single-owner here in W2.
- Dependency check: R-21-03 has no upstream R-item dependency; placed after
  R-21-02 purely to keep `PinScope.tsx` single-owner per wave (and to let
  the skip-small-badge sweep optionally fold into R-21-02's
  `MutationObserver` callback per the plan's coalescing hint).
- **Gate check:** `cd pinscope && npm run typecheck` exits 0 and
  `cd pinscope && npm test` is green (309+ tests, 0 fail); R-21-03's named
  RTL describe block `R-21-03 — heavy-page degrade` is green with both
  named tests transitioned red→green (heavy-page resolution-count ≤ 6 over
  150 ms with 600 pins AND > 6 with 100 pins, proving the gate switches;
  `e_small_{i}` pins carry `data-pin-skipbadge=""` on the heavy page and the
  injected `style[data-pinscope-skip-badge]` block is present); existing
  AC-026 / AC-027 / AC-070 / AC-071 perf-budget tests still pass within
  budget. Wave 3 does not start until this gate passes.

### Wave 3 — R-21-01

- **R-21-01** — files: `pinscope/src/runtime/PinScope.tsx`.
- One-owner check: sole R-item in the wave — `PinScope.tsx` has exactly one
  owner. Placed after R-21-02/R-21-03 only to keep `PinScope.tsx` single-
  owner per wave; functionally order-neutral.
- Dependency check: R-21-01 has no upstream R-item dependency. The touch
  `useEffect` and compact-viewport branch are additive to the
  `PinScopeHud` body left by W1 + W2 and do not read either's outputs.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0 and
  `cd pinscope && npm test` is green (309+ tests, 0 fail); R-21-01's named
  RTL describe block `R-21-01 — touch + responsive collapse` is green with
  all three named tests transitioned red→green (tap selects via real
  `TouchEvent('touchstart')`/`touchend` < 500 ms; long-press locks at
  ≥ 500 ms and survives subsequent `mouseleave`; compact viewport at
  `innerWidth=600` collapses the visible-HUD subtree and exposes the
  `FloatingToggle`, restoring at `innerWidth=1280` returns the HUD); the
  existing `tests/unit/runtime/selection.test.tsx` /
  `controls.test.tsx` click-to-select cases do not regress; AC-070
  mount-time perf test stays within budget. Wave 4 does not start until
  this gate passes.

### Wave 4 — R-21-04

- **R-21-04** — files: none in the STEP-1 phase. STEP-2 branch (only if
  STEP-1 confirms in-scope): `pinscope/src/runtime/PinScope.tsx` (add
  `markCrossOriginFrames` import + sweep call inside R-21-02's
  `useEffect`).
- One-owner check: sole R-item in the wave — `PinScope.tsx` (if STEP-2
  fires) is single-owner here. R-21-02 owned it in W1; R-21-03 owned it in
  W2; R-21-01 owned it in W3 — in W4 R-21-04 is the only contender.
- Dependency check: R-21-04 is placed last so its STEP-1 verdict can
  observe the final shape of R-21-02's `useEffect` (the fold-in host) after
  R-21-01 / R-21-03 have landed their own additive pieces.
- **Gate check:** `cd pinscope && npm run typecheck` exits 0 and
  `cd pinscope && npm test` is green (309+ tests, 0 fail). STEP-1 verdict
  is recorded in the execution log (verbatim SPEC §12 + AC-061 re-read +
  the `grep -rn 'markCrossOriginFrames' pinscope/src/` evidence). **Then
  one of the two DoD branches holds**:
  - *(confirmed → wiring lands)* R-21-04's named RTL test `R-21-04 — cross-
    origin iframe outline overlay` in `tests/unit/runtime/pinscope.test.tsx`
    is green (the iframe carries `data-pin-iframe` after the initial
    microtask flush AND `[data-pinscope-iframe-overlay]` is present in
    `document.body`), transitioned red→green across the STEP-2 wiring;
    `git diff --stat` for this R-item shows `PinScope.tsx` and
    `tests/unit/runtime/pinscope.test.tsx` modified, no other source-tree
    file changed; existing `tests/unit/runtime/iframe-overlay.test.ts`
    cases do not regress.
  - *(refuted → no code change)* `git diff --stat` for this R-item shows
    **0** files changed under `pinscope/src/`; the `### Resolution`
    block in the plan is the authoritative closing record; the
    strengthen-proposal recommendation for AC-061 is forwarded to the loop
    owner.

## Conflict matrix

File → R-items that touch it, and the wave each is in. No file is touched by
two R-items inside the same wave.

| File | R-21-01 | R-21-02 | R-21-03 | R-21-04 |
|---|---|---|---|---|
| `pinscope/src/runtime/PinScope.tsx` | W3 | W1 | W2 | W4 (only if STEP-2 confirms) |
| `pinscope/src/runtime/components/InfoPanel.tsx` | — | W1 | — | — |
| `pinscope/src/runtime/hooks/useHoveredElement.ts` | — | — | W2 | — |
| (no file — investigation STEP-1 / Resolution branch) | — | — | — | W4 (only if STEP-2 refutes) |

Intra-wave collision check:

- **Wave 1:** R-21-02 alone — single owner of `PinScope.tsx` and
  `InfoPanel.tsx`.
- **Wave 2:** R-21-03 alone — single owner of `PinScope.tsx` and
  `useHoveredElement.ts`.
- **Wave 3:** R-21-01 alone — single owner of `PinScope.tsx`.
- **Wave 4:** R-21-04 alone — single owner of `PinScope.tsx` if STEP-2
  fires, otherwise zero files touched.

`PinScope.tsx` is contended by R-21-02 / R-21-03 / R-21-01 (and conditionally
R-21-04 STEP-2); the four appear in four different waves (W1 / W2 / W3 / W4),
so the one-file-one-owner-per-wave rule holds. No other file is multiply
owned.
