# PinScope Remediation Plan — PS-R10

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: two P3 findings where an
> AC is marked `BLOCKED` but its implementation / test artifact is genuinely
> absent rather than environment-gated. The goal is **correctly BLOCKED** —
> implementation present + test authored — so a browser-capable CI (or a
> future `manual-attest`) can verify, and the next audit finds an env-only
> block instead of an absent deliverable.

---

## Remediation R-061 — Cross-origin iframe outline + label overlay

**Linked finding:** F-10-01 (R10-F-AC-061)
**Severity:** P3
**Spec anchor:** Appendix A.5 — `"cross-origin iframes render an outline + label only (no injection)"`; SPEC §12 Edge Cases — `"iframes (same-origin inject, cross-origin outline only)"`.

### Ecosystem analysis

1. **Why does AC-061 need a runtime behavior, not an absence?** The spec says
   cross-origin iframes "render an outline + label". That is an active draw,
   not merely "skip injection". Audit F-10-01 confirms `grep -rEin 'iframe'`
   over `src/` and `tests/` is empty — nothing detects iframes today.
2. **What is the sibling pattern?** AC-060 (Shadow DOM) is the direct sibling
   edge case. Its implementation is `src/runtime/utils/shadow-dom.ts` — a
   standalone util exporting `markShadowHosts()` / `isShadowLimited()`,
   unit-tested in `tests/unit/runtime/edge-cases.test.ts` under
   `describe('Shadow DOM marking (AC-060)')`. R-061 mirrors that structure:
   a new `src/runtime/utils/` file + a new `describe` block carrying the
   `AC-061` tag.
3. **How is "cross-origin" detected at runtime?** Reading
   `iframe.contentDocument` (or `iframe.contentWindow.document`) on a
   cross-origin frame throws a `SecurityError` (a `DOMException`) or yields
   `null`. Same-origin frames return a live `Document`. The detection signal
   is therefore: *attempt the property access inside `try/catch`; treat a
   thrown exception OR a `null`/`undefined` document as cross-origin.* This
   logic is pure DOM-API branching and is fully exercisable in jsdom.
4. **Which part is headlessly verifiable vs. browser-only?** jsdom can
   construct `<iframe>` elements, can be made to throw on `contentDocument`
   access via a stubbed property descriptor, and renders DOM nodes — so the
   **iframe-detection decision** (`isCrossOriginFrame`) and the
   **outline+label overlay DOM construction** (`markCrossOriginFrames`
   producing the correct overlay nodes/attributes/inline styles) are
   unit-testable headlessly. What is genuinely browser-only is the *visual
   correctness* of the rendered outline against a real second origin — that
   residual stays AC-061's `manual` / `browser` block.
5. **Where does this wire into the runtime?** The element-walker / observer
   path is the runtime's edge-case marking surface. `shadow-dom.ts`'s
   `markShadowHosts()` is the precedent: a sweep over `document` that stamps
   attributes. R-061 follows it — `markCrossOriginFrames(root)` sweeps for
   `iframe` elements and stamps an overlay. No existing runtime file needs
   to *call* it for the util + unit test to exist and be verified (the
   sibling `shadow-dom.ts` is itself not invoked from `PinScope.tsx`), so
   R-061 stays a self-contained util + test, matching AC-060 exactly.
6. **What styling does the overlay use?** SPEC §12 reserves z-index
   `2147483647` for PinScope and uses `!important` against hostile CSS. The
   overlay is an absolutely-positioned `<div>` with a high z-index, a dashed
   outline, and a small label box (the frame's `data-pin` id or `iframe`
   src host). It is `pointer-events: none` so it never intercepts clicks.
7. **What attribute marks a handled cross-origin frame?** Mirroring
   `data-pin-shadow`, use `data-pin-iframe` on the `<iframe>` element, and
   `data-pinscope-iframe-overlay` on the generated overlay `<div>` so the
   HUD-exclusion rule (`[data-pinscope-ui]`) and tests can target it.
8. **Does this collide with R-083?** No. R-061 touches only
   `src/runtime/utils/iframe-overlay.ts` and a `tests/unit/runtime/` file.
   R-083 touches only `tests/integration/`. Disjoint files; safe to share or
   split waves — see WAVES-R10.md.

### Execution plan

**Files to create:**
- `src/runtime/utils/iframe-overlay.ts` — the iframe edge-case util.
- `tests/unit/runtime/iframe-overlay.test.ts` — headless jsdom/Vitest unit
  test carrying the `AC-061` tag.

**Files to modify:** none. (Mirrors `shadow-dom.ts`, which is a standalone
util with its own unit test and is not invoked from a runtime component.)

**Files that MUST remain untouched:**
- `src/runtime/utils/shadow-dom.ts` — the sibling util; its
  `markShadowHosts` / `isShadowLimited` exports and `data-pin-shadow`
  attribute name must not change. R-061 only *imitates* it.
- `tests/unit/runtime/edge-cases.test.ts` — the existing
  `describe('Shadow DOM marking (AC-060)')` and `describe('RuntimePinObserver
  (AC-025)')` blocks must keep passing untouched; R-061 authors a *new*
  separate file rather than appending here, to avoid two R-items ever
  needing the same file.
- `src/runtime/constants.ts` — the reserved z-index exports
  (`Z_BADGE` / `Z_HOVER` / `Z_SELECTED`) and `HUD_ROOT_ATTR` keep their
  current values; R-061 may *import and reuse* `Z_SELECTED` but must not
  redefine it.

**Order of operations:**
1. Create `iframe-overlay.ts`. Define the documented API:
   - `const IFRAME_ATTR = 'data-pin-iframe'` and
     `const IFRAME_OVERLAY_ATTR = 'data-pinscope-iframe-overlay'`.
   - `isCrossOriginFrame(frame: HTMLIFrameElement): boolean` — wraps the
     `frame.contentDocument` access in `try/catch`; returns `true` when the
     access throws OR returns a non-`Document` (`null`/`undefined`); returns
     `false` when a live same-origin `Document` is obtained.
   - `markCrossOriginFrames(root: ParentNode = document): number` — sweeps
     `root.querySelectorAll('iframe')`; for each cross-origin frame, stamps
     `IFRAME_ATTR` on the `<iframe>`, builds an overlay `<div>` carrying
     `IFRAME_OVERLAY_ATTR`, positions it over the frame's bounding rect
     (absolute positioning, dashed `outline`/`border`, reserved high
     z-index reused from `constants.ts`, `pointer-events: none`), gives it
     a label child showing the frame's `data-pin` id (fallback: the frame
     `src` host), appends it to `document.body`, and returns the count of
     cross-origin frames marked. Same-origin frames are left untouched (the
     "same-origin inject" branch is out of scope for this finding — only the
     cross-origin outline path is required by AC-061).
   - `isIframeLimited(el: Element): boolean` — mirrors `isShadowLimited`;
     returns `el.hasAttribute(IFRAME_ATTR)`.
2. Create `tests/unit/runtime/iframe-overlay.test.ts`. Add a `describe`
   block titled exactly `'Cross-origin iframe overlay (AC-061)'` (the
   `(AC-###)` convention `ac-verify.mjs` scans for). Tests, all jsdom-only:
   - a same-origin iframe (jsdom default, `contentDocument` accessible) is
     reported `false` by `isCrossOriginFrame` and is NOT marked.
   - a cross-origin iframe — simulated by `Object.defineProperty` on the
     iframe instance making `contentDocument` a getter that `throw`s a
     `DOMException`, plus a `null`-returning variant — is reported `true`.
   - `markCrossOriginFrames(document)` returns the correct count, stamps
     `data-pin-iframe` on the cross-origin frame, and appends exactly one
     `[data-pinscope-iframe-overlay]` div whose label text contains the
     frame's `data-pin` id (or src host fallback).
   - `isIframeLimited` returns `true` for a marked frame, `false` for a
     plain element.
   - `afterEach` clears `document.body.innerHTML` (matches
     `edge-cases.test.ts`).
3. Run `npm run typecheck` then `npx vitest run tests/unit/runtime/iframe-overlay.test.ts`.

**Rollback trigger:** `iframe-overlay.test.ts` fails under jsdom, OR
`tsc --noEmit` reports an error in `src/runtime/`, OR any pre-existing test
in `edge-cases.test.ts` regresses.

### Acceptance criteria

- [ ] `grep -rEin 'iframe' src/runtime/utils/iframe-overlay.ts` is non-empty
      (implementation now exists — directly negates F-10-01's evidence).
- [ ] `iframe-overlay.ts` exports `isCrossOriginFrame`,
      `markCrossOriginFrames`, and `isIframeLimited`
      (`grep -E 'export (function|const) (isCrossOriginFrame|markCrossOriginFrames|isIframeLimited)'`).
- [ ] Cross-origin detection branches on a `try/catch` around
      `contentDocument` (`grep -E 'contentDocument' src/runtime/utils/iframe-overlay.ts`
      and a `catch` clause present).
- [ ] The overlay uses an absolute-positioned div with `pointer-events: none`
      and a reserved high z-index
      (`grep -E "pointer-events|z-index|2147483647|Z_SELECTED" src/runtime/utils/iframe-overlay.ts`).
- [ ] `tests/unit/runtime/iframe-overlay.test.ts` contains a `describe` block
      tagged `(AC-061)` (`grep -E 'AC-061' tests/unit/runtime/iframe-overlay.test.ts`).
- [ ] `npx vitest run tests/unit/runtime/iframe-overlay.test.ts` is green in
      this headless environment (the detection + DOM-construction logic is
      jsdom-verifiable).
- [ ] `npm run typecheck` stays clean.
- [ ] No file other than the two new files is changed
      (`git status --porcelain src/runtime/utils/shadow-dom.ts tests/unit/runtime/edge-cases.test.ts src/runtime/constants.ts` empty).

### Dependencies

None. R-061 is self-contained (new util + new test). It does not depend on
R-083 and shares no file with it.

### Risk assessment

**Low.** The detection logic is a `try/catch` over a single DOM property —
the precise jsdom-stub technique (`Object.defineProperty` to throw) is a
well-known pattern. Residual browser-only risk: jsdom cannot reproduce a
*real* `SecurityError` from an actual cross-origin frame, only a simulated
throw — so AC-061 remains correctly `BLOCKED` on `env: browser` for full
visual verification, but its core decision logic and overlay DOM are now
present and headlessly proven. No production code path changes, so no
regression surface beyond the two new files.

---

## Remediation R-083 — Playwright visual-regression suite across the §14 matrix

**Linked finding:** F-10-02 (R10-F-AC-083)
**Severity:** P3
**Spec anchor:** Appendix A.7 — `"visual-regression suite runs across the §14 matrix"`; SPEC §14 — `"Visual regression: HUD across Chrome/Firefox/Safari, 4 viewports, light/dark, with/without host CSS framework"`.

### Ecosystem analysis

1. **What is missing?** F-10-02: `tests/integration/` holds only the
   functional `pinscope.spec.ts` — no `toHaveScreenshot`, no snapshot diff.
   AC-083 requires an authored visual-regression suite. The browser env is
   genuinely unavailable here, but the *test artifact* must still exist so a
   browser CI can run it and a future audit finds an env-only block.
2. **What does the §14 matrix require?** "HUD across Chrome/Firefox/Safari,
   4 viewports, light/dark, with/without host CSS framework." Browser
   coverage is a Playwright `projects` concern; viewports + theme + host-CSS
   are per-test parameterization within the spec.
3. **How is the existing suite configured?** `playwright.config.ts` sets
   `testDir: './tests/integration'`, `baseURL: 'http://localhost:5173'`, and
   a `webServer` running `examples/vite-react`. It currently has **no
   `projects` array** — so it runs one default (Chromium) browser. To honor
   "Chrome/Firefox/Safari" the config needs a `projects` array with
   `chromium`, `firefox`, and `webkit` devices.
4. **Do screenshots need config?** Playwright's `toHaveScreenshot` works
   without extra config but benefits from a deterministic `expect.toHaveScreenshot`
   block (`maxDiffPixelRatio`, `animations: 'disabled'`) so CI diffs are
   stable. That tuning lives in `playwright.config.ts` — the second file in
   R-083. Only R-083 touches `playwright.config.ts`, so it is wave-safe.
5. **What HUD states should be captured?** The HUD's visible surfaces today
   (per `src/runtime/PinScope.tsx` → `PinBadges` + `InfoPanel`): the baseline
   HUD on load, and the InfoPanel-open state on hover. The §14 axes —
   4 viewports, light/dark, with/without host CSS framework — are iterated
   in the spec so the screenshot set spans the matrix.
6. **How are viewports / theme / host-CSS driven?** Viewports via
   `page.setViewportSize`. Light/dark via Playwright's
   `page.emulateMedia({ colorScheme })`. "With/without host CSS framework"
   via a query param or `addStyleTag` toggling a framework reset on the
   `examples/vite-react` page — the spec documents this with a clear flag so
   a CI reviewer understands the two arms.
7. **What tag convention?** `ac-verify.mjs` scans `describe`/`it`/`test`
   titles for `(AC-###)`. The suite's `test.describe` is titled
   `'PinScope visual regression (AC-083)'`, matching `pinscope.spec.ts`'s
   `'... (AC-023)'` style.
8. **Will it run here?** No — `env: browser`, no browser binary. The
   deliverable is an authored, well-formed spec a browser CI executes; AC-083
   stays correctly `BLOCKED` afterward (implementation/test now *present*).
9. **Does it collide with R-061?** No. R-083 touches only
   `tests/integration/visual-regression.spec.ts` and `playwright.config.ts`.
   R-061 touches `src/runtime/utils/` and `tests/unit/`. Disjoint.

### Execution plan

**Files to create:**
- `tests/integration/visual-regression.spec.ts` — the §14 visual-regression
  Playwright suite, tagged `AC-083`.

**Files to modify:**
- `playwright.config.ts` — add a `projects` array (`chromium`, `firefox`,
  `webkit`) and an `expect.toHaveScreenshot` tuning block. Anchor: the
  `defineConfig({ ... })` call — insert `projects` and `expect` keys
  alongside the existing `testDir` / `use` / `webServer` keys.

**Files that MUST remain untouched:**
- `tests/integration/pinscope.spec.ts` — the existing functional suite and
  its `(AC-0xx)` tags must keep passing on a browser CI; R-083 authors a
  *separate* spec file and never edits this one.
- The `playwright.config.ts` `webServer` block (the
  `npm --prefix examples/vite-react run dev` command, its `url`,
  `reuseExistingServer`, `timeout`) and the `baseURL` under `use` —
  preserve verbatim; R-083 only *adds* `projects` and `expect`, never
  alters `webServer` or `baseURL`.
- `vitest.config.ts` — unit-test config is unrelated; do not touch.

**Order of operations:**
1. Modify `playwright.config.ts`: inside `defineConfig({ ... })`, add
   `projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } },
   { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
   { name: 'webkit', use: { ...devices['Desktop Safari'] } }]` (importing
   `devices` from `@playwright/test`), and an
   `expect: { toHaveScreenshot: { maxDiffPixelRatio: 0.02, animations: 'disabled' } }`
   block. Keep `testDir`, `use.baseURL`, `webServer` exactly as-is.
2. Create `tests/integration/visual-regression.spec.ts`:
   - `test.describe('PinScope visual regression (AC-083)', () => { ... })`.
   - Define the §14 matrix in-spec: a `viewports` array of 4 entries
     (e.g. mobile 375×667, tablet 768×1024, laptop 1280×800, desktop
     1920×1080), a `themes` array `['light', 'dark']`, and a
     `hostCss` array `[true, false]`.
   - Nest `for` loops over viewport × theme × hostCss generating one
     `test()` per cell. Each test: `page.setViewportSize(viewport)`,
     `page.emulateMedia({ colorScheme: theme })`, navigate to `/` (with the
     host-CSS-framework flag when `hostCss` is true), then
     `await expect(page).toHaveScreenshot([...descriptive name parts])` for
     the baseline HUD, and a second `toHaveScreenshot` after
     `page.locator('button').first().hover()` for the InfoPanel-open state.
   - Header comment: this suite needs a browser binary; on a browser-less
     env AC-083 is tracked `BLOCKED` (mirror `pinscope.spec.ts`'s header).
3. Run `npx tsc --noEmit` (or `npm run typecheck`) to confirm the new spec
   and the config edit type-check. (The suite itself cannot *run* here —
   no browser — that is expected and is the env-only block.)

**Rollback trigger:** `playwright.config.ts` fails to type-check after the
`projects`/`expect` edit, OR `visual-regression.spec.ts` fails type-check,
OR the `webServer`/`baseURL` keys are found altered.

### Acceptance criteria

- [ ] `tests/integration/visual-regression.spec.ts` exists and uses
      `toHaveScreenshot`
      (`grep -E 'toHaveScreenshot' tests/integration/visual-regression.spec.ts`).
- [ ] The suite is tagged `AC-083`
      (`grep -E 'AC-083' tests/integration/visual-regression.spec.ts`).
- [ ] The §14 matrix axes are present: 4 viewports, light+dark, host-CSS
      on/off (`grep -Ei 'viewport|colorScheme|dark|light|hostCss|framework' tests/integration/visual-regression.spec.ts`
      shows all axes).
- [ ] `playwright.config.ts` declares a `projects` array covering
      `chromium`, `firefox`, and `webkit`
      (`grep -E 'chromium|firefox|webkit' playwright.config.ts`).
- [ ] `playwright.config.ts` declares an `expect.toHaveScreenshot` tuning
      block (`grep -E 'toHaveScreenshot' playwright.config.ts`).
- [ ] `playwright.config.ts` still contains the unaltered `webServer` command
      `npm --prefix examples/vite-react run dev` and `baseURL`
      `http://localhost:5173`.
- [ ] `npm run typecheck` stays clean.
- [ ] `tests/integration/pinscope.spec.ts` is byte-unchanged
      (`git status --porcelain tests/integration/pinscope.spec.ts` empty).

### Dependencies

None. R-083 is self-contained (one new spec + one config edit). It does not
depend on R-061 and shares no file with it.

### Risk assessment

**Low.** The change is additive: a new spec file plus two new keys in
`defineConfig`. No production runtime code is touched. The only risk is
type-check breakage from the `devices` import or the `projects` shape —
caught immediately by `npm run typecheck`. The suite cannot execute in this
browser-less environment by design; that residual keeps AC-083 correctly
`BLOCKED` on `env: browser` — but the artifact now *exists*, negating
F-10-02's "test artifact is absent" evidence. First-run screenshot baselines
are generated on the first browser-CI run (Playwright's standard behavior);
no baseline PNGs are committed here.

---

## Post-remediation status note

After R-061 and R-083 land, AC-061 and AC-083 remain `BLOCKED` — but
**correctly** so: implementation present + test authored, blocked only by
`env: browser` in this environment. `convergence/STATUS.md`'s "7 BLOCKED
criteria" section should be updated by the executor to reclassify AC-061 and
AC-083 from "masks an absent implementation/artifact" to env-only blocks,
joining AC-023 / AC-030 / AC-063 / AC-082 / AC-106. That STATUS.md edit is
owned by the verification step (see WAVES-R10.md W2) so it never collides
with the two implementation R-items.
