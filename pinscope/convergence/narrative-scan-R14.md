# Narrative Coverage Scan — PS-R14

- **Round:** 14 (first narrative deep-scan; fresh `claim_id`s, no carry-over)
- **Spec:** PinScope North-Star v2.0.0, `sha256:1779526021db1f5bc7ffe36647e6deb08ba3f8234e82cee31dc0bca5357c7a45`
- **Generated:** 2026-05-21T23:07:18Z
- **Scope:** §1–§17 narrative vs. Appendix A AC ledger vs. `pinscope/` + `framework/` reality.

## Coverage summary

52 normative narrative claims were enumerated across §1–§17 (2 borderline
motivation/context items — NC-03-01, NC-16-01 — marked `normative: false` and
excluded from counts). **34 are AC-covered, 18 are not.** Of the 18 uncovered,
10 are satisfied by the code anyway (the spec asserts a concrete behavior the
loop simply never contracted into an AC) and **8 are `uncovered_unsatisfied` —
normative behavior with neither an AC nor a working implementation.** 18
candidate ACs are proposed (exactly one per uncovered claim) and 5 strengthen
proposals target covering ACs whose `verify:` under-checks an exact value,
ordering, or full behavior the prose asserts. This scan is a SECONDARY signal:
it does not block AC convergence; it tells the user which ACs Appendix A is
missing.

## UNCOVERED + UNSATISFIED — most urgent (8)

These are real code gaps invisible to the loop because no AC exists.

- **NC-07-01 (§7.1)** — `<PinScope/>` mounts only `PinBadges` + `InfoPanel`.
  The §7.1 HUD tree also requires `Rulers`, `Crosshair`, `GridOverlay`,
  `TopBar`, `CommandBar`. All five components exist but are never rendered by
  the root. `re_read:` Read `src/runtime/PinScope.tsx` — `PinScopeHud` returns
  a portal containing only `<PinBadges/>` and `<InfoPanel/>`.
- **NC-07-02 (§7.1)** — `<PinScope/>` props missing `defaultGridMode` and
  `shortcutsEnabled`. `re_read:` `PinScopeProps` declares only `enabled` and
  `hudPosition`.
- **NC-07-03 (§7.1)** — no `FloatingToggle`; the HUD-hidden render branch does
  not exist. `re_read:` `grep -rln 'FloatingToggle' pinscope/src` → no matches.
- **NC-08-07 (§8.6)** — `CommandBar` does not expand to 120px on focus.
  `re_read:` `src/runtime/components/CommandBar.tsx` style is a fixed `height:40`.
- **NC-08-09 (§8.6)** — `CommandBar` has no `Tab` autocomplete; `onInputKey`
  handles only Escape/Enter/Arrow keys and never uses `parsers/autocomplete.ts`.
  `re_read:` Read `CommandBar.tsx` `onInputKey`.
- **NC-08-11 (§8.8)** — `StatePanel` does not auto-generate override rules from
  host stylesheets; it only toggles `<html data-state-override>`. `re_read:`
  `grep 'styleSheets|cssRules' src/runtime` → no matches.
- **NC-10-01 (§10-D)** — no `/__pinscope/snapshot` dev-server endpoint;
  `SnapshotManager` writes through an injectable in-memory store. `re_read:`
  `grep -rln '__pinscope' pinscope/src` → no matches.
- **NC-12-01 (§12)** — PinScope reserves z-index `2147483647` (OK) but badge
  CSS rules carry no `!important`, so hostile host CSS can override them.
  `re_read:` `grep '!important' src/runtime/styles/badges.css.ts` → only
  `[data-pinscope-ui]{outline:none !important}`.

Note: NC-08-08 (`CommandBar` history → `.pinscope/history.json`, last 1000),
NC-08-10 (Alt-hover sibling distances), NC-08-03 (multi-scale ruler ticks +
corner coords), NC-08-04 (Crosshair measurement-mode/HUD-hidden disable), and
NC-08-12 (snapshot captures exactly 32 styles) are *covered* by an AC, but the
covering AC under-checks them and the missing sub-behavior is genuinely absent
or unverified — see strengthen proposals below.

## Claims by spec section

### §1 Mission
- **NC-01-01** — 95%/≤2-rounds success metric. Covered (AC-107), `code: unknown`
  — AC-107 checks a single scenario, not the population rate.

### §3 Architecture
- **NC-03-01** — 6-layer runtime grouping. `normative: false` (descriptive).

### §4 Stack & budgets
- **NC-04-01** — dev bundle <80 KB / <25 KB gz. Covered (AC-073), satisfied;
  size-limit has no separate gzip entry.
- **NC-04-02** — prod bundle 0 bytes. Covered (AC-010, AC-074), satisfied.
- **NC-04-03** — no Redux/Zustand. **Uncovered**, satisfied → candidate AC-NEW-01.

### §6 Build-time module
- **NC-06-01** — plugin name/`enforce`. Covered (AC-001).
- **NC-06-02** — `PinScopeOptions` defaults. **Uncovered**, satisfied → AC-NEW-02.
- **NC-06-03** — `buildStart`/`buildEnd` lifecycle. **Uncovered**, satisfied → AC-NEW-03.
- **NC-06-04** — babel parser plugin set. **Uncovered**, satisfied → AC-NEW-04.
- **NC-06-05** — skip elements with no `loc`. **Uncovered**, satisfied → AC-NEW-05.
- **NC-06-06** — source map emitted. Covered (AC-011).
- **NC-06-07** — `save()` dirty-gated. **Uncovered**, satisfied → AC-NEW-06.
- **NC-06-08** — re-seen key clears `deleted` / refreshes `last_seen`.
  **Uncovered**, satisfied → AC-NEW-07.
- **NC-06-09** — removed entry `deleted:true`, id never reused. Covered (AC-008).
- **NC-06-10** — moved element → new key → new id. **Uncovered**, satisfied → AC-NEW-08.

### §7 Runtime module
- **NC-07-01** — full §7.1 HUD tree mounted. **UNCOVERED + UNSATISFIED** → AC-NEW-09.
- **NC-07-02** — `defaultGridMode`/`shortcutsEnabled` props. **UNCOVERED + UNSATISFIED** → AC-NEW-10.
- **NC-07-03** — `FloatingToggle` when HUD hidden. **UNCOVERED + UNSATISFIED** → AC-NEW-11.
- **NC-07-04** — badge z-index range + color states. Covered (AC-023) → strengthen.
- **NC-07-05** — void-element JS overlay + MutationObserver. Covered (AC-024/025).
- **NC-07-06** — `useHoveredElement` rAF throttle. **Uncovered**, satisfied →
  AC-NEW-12. No AC asserts the rAF throttle; AC-026/027 cover only
  nearest-ancestor / HUD-skip behavior.

### §8 Components
- **NC-08-01** — InfoPanel geometry. **Uncovered**, satisfied → AC-NEW-13.
- **NC-08-02** — empty values render `—`. Covered (AC-033).
- **NC-08-03** — ruler 10/50/100/200 ticks + corner coords. Covered (AC-034) → strengthen.
- **NC-08-04** — Crosshair disable set. Covered (AC-035) → strengthen.
- **NC-08-05** — GridOverlay 4 modes / cycle / SVG pattern. Covered (AC-036).
- **NC-08-06** — TopBar geometry + fields. Covered (AC-037).
- **NC-08-07** — CommandBar expand-to-120px. **UNCOVERED + UNSATISFIED** → AC-NEW-14.
- **NC-08-08** — CommandBar history → `.pinscope/history.json`. Covered (AC-053)
  → strengthen (covering AC checks ClaudeBridge path, not CommandBar persistence).
- **NC-08-09** — CommandBar Tab autocomplete. **UNCOVERED + UNSATISFIED** → AC-NEW-15.
- **NC-08-10** — MeasurementTool Δ labels (covered AC-039) + Alt-hover siblings
  (absent). Covered (AC-039) for the labels; the sibling behavior is unverified.
- **NC-08-11** — StatePanel stylesheet auto-gen. **UNCOVERED + UNSATISFIED** → AC-NEW-16.
- **NC-08-12** — snapshot captures exactly 32 styles. Covered (AC-042) →
  strengthen. `TRACKED_STYLES` has 32 entries (satisfied), but AC-042 validates
  the §9.2 schema only and never asserts the 32-key count.

### §9 Data schemas
- **NC-09-01** — `.pinmap.json` schema. Covered (AC-006).
- **NC-09-02** — Operation schema + `request_type` enum. Covered (AC-052).

### §10 Behavioral flows
- **NC-10-01** — snapshot via `/__pinscope/snapshot` endpoint. **UNCOVERED +
  UNSATISFIED** → AC-NEW-17. AC-042's `vitest-tag` suite uses an in-memory
  `MemorySnapshotStore` and validates the §9.2 schema; it never exercises the
  flow-D dev-server endpoint, so it would still pass with the endpoint absent —
  the claim is genuinely uncovered.
- **NC-10-02** — hover budget <8 ms. Covered (AC-071).

### §11 Operation protocol
- **NC-11-01** — full grammar. Covered (AC-050).
- **NC-11-02** — shortcut properties. Covered (AC-051).

### §12 Edge cases
- **NC-12-01** — reserved z-index + `!important` hardening. The z-index
  reservation holds via constants, but the `!important` hardening is **UNCOVERED
  + UNSATISFIED** (badge rules carry no `!important`) → AC-NEW-18.
- **NC-12-02** — >500-element 30fps throttle + <16×16 badge skip. Covered (AC-065),
  `code: unknown` (throttle util present; PinBadges wiring unverified this round).

### §13 Performance
- **NC-13-01** — mount <50 ms. Covered (AC-070).
- **NC-13-02** — parse <4 ms. Covered (AC-072).

### §14 Testing
- **NC-14-01** — AST suite ≥50 pairs. Covered (AC-080).
- **NC-14-02** — parser suite ≥30 variants. Covered (AC-081).

### §15 Deployment
- **NC-15-01** — export subpaths. Covered (AC-090).
- **NC-15-02** — `src/index.ts` re-exports incl. `withPinScope`. Covered
  (AC-091), `code: unknown` — AC-091 does not assert the `withPinScope` re-export.

### §16–§17 Phases & APEX integration
- **NC-16-01** — P5 phase definition. `normative: false`.
- **NC-17-01..06** — apex-skill, ui-phase scaffold, ui-review evidence,
  stack_skills, apex-spec registration: all covered (AC-100/102/103/104/105),
  satisfied. **NC-17-06** round-trip avg <2 rounds covered (AC-107), `unknown`.

## Candidate ACs (18) — each quotes its `re_read`

`uncovered_unsatisfied` candidates are flagged **[OPEN-on-birth]**.

- **AC-NEW-01** (NC-04-03) — no Redux/Zustand. `re_read:` `grep 'redux|zustand'
  pinscope/src pinscope/package.json` → no matches.
- **AC-NEW-02** (NC-06-02) — `PinScopeOptions` defaults. `re_read:` Read
  `src/plugin/index.ts` `resolveOptions()` — all six defaults match §6.1.
- **AC-NEW-03** (NC-06-03) — `buildStart`→load / `buildEnd`→reconcile+save.
  `re_read:` Read `src/plugin/index.ts` lifecycle hooks.
- **AC-NEW-04** (NC-06-04) — babel plugins `jsx`,`typescript`,`decorators-legacy`.
  `re_read:` Read `src/plugin/ast-transformer.ts` `parse()`.
- **AC-NEW-05** (NC-06-05) — skip JSX element with no `loc`. `re_read:` Read
  `ast-transformer.ts` — `const loc = node.loc?.start; if (!loc) return;`.
- **AC-NEW-06** (NC-06-07) — `save()` dirty-gated. `re_read:` Read
  `src/plugin/pin-map.ts` `save()` — `if (!this.dirty) return;`.
- **AC-NEW-07** (NC-06-08) — re-seen key clears `deleted`. `re_read:` Read
  `pin-map.ts` `getOrAssign()` — `delete existing.deleted; existing.last_seen=now`.
- **AC-NEW-08** (NC-06-10) — moved element → new id. `re_read:` Read
  `src/plugin/stable-id-generator.ts` — key includes line+column.
- **AC-NEW-09** (NC-07-01) **[OPEN-on-birth]** — full §7.1 HUD tree mounted.
  `re_read:` Read `src/runtime/PinScope.tsx` — only PinBadges + InfoPanel.
- **AC-NEW-10** (NC-07-02) **[OPEN-on-birth]** — `defaultGridMode` /
  `shortcutsEnabled` props. `re_read:` Read `PinScopeProps` in `PinScope.tsx`.
- **AC-NEW-11** (NC-07-03) **[OPEN-on-birth]** — `FloatingToggle` when HUD
  hidden. `re_read:` `grep -rln 'FloatingToggle' pinscope/src` → no matches.
- **AC-NEW-12** (NC-07-06) — `useHoveredElement` rAF throttle. `re_read:` Read
  `src/runtime/hooks/useHoveredElement.ts` — `handleMove` stores `lastPos`,
  returns early if `rafRef` set, resolves inside `requestAnimationFrame`.
- **AC-NEW-13** (NC-08-01) — InfoPanel geometry. `re_read:` Read
  `src/runtime/components/InfoPanel.tsx` `style` — top:56, width:320, right:16.
- **AC-NEW-14** (NC-08-07) **[OPEN-on-birth]** — CommandBar 40→120px on focus.
  `re_read:` Read `src/runtime/components/CommandBar.tsx` `style` — fixed 40.
- **AC-NEW-15** (NC-08-09) **[OPEN-on-birth]** — CommandBar Tab autocomplete.
  `re_read:` Read `CommandBar.tsx` `onInputKey` — no Tab branch.
- **AC-NEW-16** (NC-08-11) **[OPEN-on-birth]** — StatePanel stylesheet auto-gen.
  `re_read:` `grep 'styleSheets|cssRules' src/runtime` → no matches.
- **AC-NEW-17** (NC-10-01) **[OPEN-on-birth]** — `/__pinscope/snapshot`
  endpoint. `re_read:` `grep -rln '__pinscope' pinscope/src` → no matches.
- **AC-NEW-18** (NC-12-01) **[OPEN-on-birth]** — badge CSS `!important`
  hardening. `re_read:` `grep '!important' src/runtime/styles/badges.css.ts` →
  only `[data-pinscope-ui]{outline:none !important}`.

## Strengthen proposals (5) — each quotes its `re_read`/claim

- **AC-023** ← NC-07-04. `claim:` "blue/red/green badge, z-index
  2147483645–2147483647" (§7.2). Current verify only reads `::before` text.
  `re_read:` Read `src/runtime/styles/badges.css.ts` — z-index and color states
  exist but are unverified. Proposed: also assert badge z-index and hover/
  selected colors.
- **AC-034** ← NC-08-03. `claim:` "ticks at 10/50/100/200 px ... corner shows
  live mouse coords" (§8.2). Current verify counts only 100px ticks. `re_read:`
  Read `src/runtime/components/Rulers.tsx` — single `interval`, no corner
  coords. Proposed: assert multi-scale ticks + corner live coords.
- **AC-035** ← NC-08-04. `claim:` "[Crosshair] disabled over HUD, in
  measurement mode, or when HUD hidden" (§8.3). `re_read:` Read `Crosshair.tsx`
  — only the over-HUD case. Proposed: assert measurement-mode and HUD-hidden
  disable too.
- **AC-042** ← NC-08-12. `claim:` "extracts 32 computed-style properties" (§8.10).
  `re_read:` Read `SnapshotManager.ts` `TRACKED_STYLES` — 32 entries. AC-042's
  `vitest-tag` suite validates the §9.2 schema only and never asserts the key
  count. Proposed: assert each element's `computed_styles` has exactly 32 keys.
- **AC-053** ← NC-08-08. `claim:` "History persisted to `.pinscope/history.json`
  (last 1000)" (§8.6). `re_read:` Read `CommandBar.tsx` — history is an
  in-component `useRef`, never persisted; `grep 'history.json' src` → no
  matches. Proposed: assert CommandBar history persists to the file, capped 1000.
