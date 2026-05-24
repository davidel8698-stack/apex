/** PinScope root component — see SPEC §7.1, §10 flows B/C/D. */

import { useCallback, useEffect, useMemo, useState } from 'react';
import type { ReactElement } from 'react';
import { createPortal } from 'react-dom';
import { PinBadges } from './components/PinBadges.js';
import { VoidBadges } from './components/VoidBadges.js';
import { InfoPanel } from './components/InfoPanel.js';
import { Rulers } from './components/Rulers.js';
import { Crosshair } from './components/Crosshair.js';
import { GridOverlay, nextGridMode } from './components/GridOverlay.js';
import type { GridMode } from './components/GridOverlay.js';
import { TopBar } from './components/TopBar.js';
import { CommandBar } from './components/CommandBar.js';
import { MeasurementTool } from './components/MeasurementTool.js';
import { StatePanel } from './components/StatePanel.js';
import type { StateOverride } from './components/StatePanel.js';
import { FloatingToggle } from './components/FloatingToggle.js';
import { useHoveredElement } from './hooks/useHoveredElement.js';
import { useViewportSize } from './hooks/useViewportSize.js';
import { useKeyboardShortcuts } from './hooks/useKeyboardShortcuts.js';
import { useSelectedElement } from './hooks/useSelectedElement.js';
import { PIN_ATTR } from './constants.js';
import { parseCommand } from './parsers/operation-parser.js';
import { buildOperation } from './parsers/operation-builder.js';
import type { BuildContext } from './parsers/operation-builder.js';
import { ClaudeBridge } from './managers/ClaudeBridge.js';
import { SnapshotManager } from './managers/SnapshotManager.js';
import { EndpointSnapshotStore } from './managers/EndpointSnapshotStore.js';
import { HistoryManager, MemoryHistoryStore } from './managers/HistoryManager.js';
import type { HistoryData } from './managers/HistoryManager.js';
import { RuntimePinObserver } from './managers/RuntimePinObserver.js';
import { markShadowHosts } from './utils/shadow-dom.js';
import { isHeavyPage, shouldSkipBadge } from './utils/throttle.js';

export interface PinScopeProps {
  /** Runtime kill-switch. */
  enabled?: boolean;
  /** Which side the InfoPanel docks to. */
  hudPosition?: 'left' | 'right';
  /** Grid mode the HUD opens with — defaults to `'off'`. */
  defaultGridMode?: GridMode;
  /** Whether the §8.11 keyboard shortcuts are live — defaults to `true`. */
  shortcutsEnabled?: boolean;
}

/**
 * Portal-renders the full §7.1 HUD tree (`PinBadges`, `Rulers`, `Crosshair`,
 * `GridOverlay`, `InfoPanel`, `TopBar`, `CommandBar`) into `document.body`.
 * When the HUD is hidden it renders only a `FloatingToggle`.
 */
export function PinScope(props: PinScopeProps = {}): ReactElement | null {
  // Guard production: PinScope never ships to a production build.
  if (process.env.NODE_ENV === 'production') return null;
  if (props.enabled === false) return null;
  return (
    <PinScopeHud
      hudPosition={props.hudPosition ?? 'right'}
      defaultGridMode={props.defaultGridMode ?? 'off'}
      shortcutsEnabled={props.shortcutsEnabled !== false}
    />
  );
}

/**
 * Fallback context for a `query` command (`? topic`) — it carries no DOM
 * target, so only the live viewport is meaningful (§10-C / §9.3 diagnostic).
 */
const EMPTY_BUILD_CONTEXT: BuildContext = {
  tag: '',
  selector: '',
  rect: { x: 0, y: 0, w: 0, h: 0 },
  currentStyles: {},
  childrenPins: [],
  viewport:
    typeof window !== 'undefined'
      ? `${window.innerWidth}x${window.innerHeight}`
      : '0x0',
};

/**
 * Resolve the §10-C `BuildContext` for a pin from the live DOM — the same
 * `getComputedStyle`/`getBoundingClientRect` reads the InfoPanel performs.
 * Returns `null` when the pin is not present (a build cannot proceed).
 */
function buildContextFor(pin: string): BuildContext | null {
  if (typeof document === 'undefined') return null;
  const el = document.querySelector(`[${PIN_ATTR}="${pin}"]`);
  if (!(el instanceof HTMLElement)) return null;
  const rect = el.getBoundingClientRect();
  const cs =
    typeof getComputedStyle === 'function' ? getComputedStyle(el) : null;
  const currentStyles: Record<string, string> = {};
  if (cs) {
    for (const prop of ['background-color', 'color', 'padding', 'margin']) {
      currentStyles[prop] = cs.getPropertyValue(prop).trim();
    }
  }
  const parent = el.parentElement
    ?.closest(`[${PIN_ATTR}]`)
    ?.getAttribute(PIN_ATTR);
  const childrenPins = Array.from(el.querySelectorAll(`[${PIN_ATTR}]`))
    .map((c) => c.getAttribute(PIN_ATTR) ?? '')
    .filter((id) => id !== '');
  const vw = typeof window !== 'undefined' ? window.innerWidth : 0;
  const vh = typeof window !== 'undefined' ? window.innerHeight : 0;
  return {
    tag: el.tagName.toLowerCase(),
    selector: `[${PIN_ATTR}="${pin}"]`,
    rect: { x: rect.x, y: rect.y, w: rect.width, h: rect.height },
    currentStyles,
    textContent: el.textContent?.trim().slice(0, 120) || undefined,
    parentPin: parent ?? undefined,
    childrenPins,
    viewport: `${vw}x${vh}`,
  };
}

/** Dev-server route the command history is persisted through (§8.6). */
const HISTORY_ENDPOINT = '/__pinscope/history';

/**
 * R-18-01 — the single command-history persist owner. POSTs the full capped
 * history to the dev-server route so it lands in `.pinscope/history.json`
 * (§8.6); the browser runtime stays `fs`-free, the file write is server-side.
 * Wired as the `HistoryManager` persist hook so every append — the CommandBar's
 * and `ClaudeBridge.send`'s alike — persists through exactly this one site. A
 * failed persist is surfaced on the console, never silently swallowed; the
 * in-memory history is unaffected.
 */
function persistHistory(data: HistoryData): void {
  if (typeof fetch !== 'function') return;
  try {
    void fetch(HISTORY_ENDPOINT, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ version: data.version, entries: data.entries }),
    }).catch((cause: unknown) => {
      // Dev-only endpoint — log instead of failing the command flow.
      console.warn('[pinscope] history persist failed', cause);
    });
  } catch (cause) {
    // Some environments throw synchronously (e.g. an unsupported relative
    // URL outside a dev server) — never let it break the command flow.
    console.warn('[pinscope] history persist failed', cause);
  }
}

function PinScopeHud({
  hudPosition,
  defaultGridMode,
  shortcutsEnabled,
}: {
  hudPosition: 'left' | 'right';
  defaultGridMode: GridMode;
  shortcutsEnabled: boolean;
}): ReactElement | null {
  const hovered = useHoveredElement();
  const viewport = useViewportSize();
  const [hudVisible, setHudVisible] = useState(true);
  const [gridMode, setGridMode] = useState<GridMode>(defaultGridMode);
  const [measuring, setMeasuring] = useState(false);
  // R-20-03 — §8.11 Shift+P (`toggle-pins`) and Shift+C (`crosshair`) flip
  // these visibility cells. Default `true` so the HUD opens with pins and
  // crosshair visible (no behavioral change vs. PS-R19).
  const [pinsVisible, setPinsVisible] = useState(true);
  const [crosshairEnabled, setCrosshairEnabled] = useState(true);
  // §8.5/§8.8 — the live state-override is owned by `PinScopeHud`, the common
  // parent of `StatePanel` (which chooses it) and `TopBar` (which reports it).
  const [stateOverride, setStateOverride] = useState<StateOverride>('none');

  // R-20-02 — §12 runtime-added-DOM observer. A `RuntimePinObserver` is a
  // lifecycle-bound MutationObserver: `.start()` on mount, `.stop()` on
  // unmount. Guarded for non-DOM test envs (e.g. node `vitest` without
  // happy-dom). The default observe root is `document.body`.
  // Deferred via `queueMicrotask` so the observer setup does NOT enter the
  // synchronous mount path (AC-070 <50ms budget). Cleanup uses a ref-style
  // closure that observes the post-microtask observer instance.
  useEffect(() => {
    if (typeof MutationObserver === 'undefined') return undefined;
    if (typeof document === 'undefined') return undefined;
    let observer: RuntimePinObserver | null = null;
    let disposed = false;
    queueMicrotask(() => {
      if (disposed) return;
      observer = new RuntimePinObserver();
      observer.start();
    });
    return () => {
      disposed = true;
      if (observer) observer.stop();
    };
  }, []);

  // R-21-02 — §12 Shadow-DOM host marking. The `markShadowHosts(document)`
  // sweep stamps `data-pin-shadow` on every Shadow-DOM host so the InfoPanel
  // can report "limited inspection" (AC-060). One initial sweep on mount, then
  // a `MutationObserver` on `document.body` (subtree: true, childList: true)
  // re-runs the sweep when new nodes are added. Cleanup disconnects the
  // observer to avoid leaking across test renders. Guarded for non-DOM envs.
  useEffect(() => {
    if (typeof document === 'undefined') return undefined;
    if (typeof MutationObserver === 'undefined') {
      // Best-effort initial sweep even without an observer.
      markShadowHosts(document);
      return undefined;
    }
    // Initial sweep covers any Shadow-DOM hosts present at mount time.
    markShadowHosts(document);
    const observer = new MutationObserver(() => {
      // Re-sweep on any DOM mutation under body — new shadow hosts get marked.
      markShadowHosts(document);
    });
    observer.observe(document.body, { subtree: true, childList: true });
    return () => {
      observer.disconnect();
    };
  }, []);

  // R-21-03 — §12 / AC-065 skip-small-badge sweep. On heavy pages (> 500
  // pinned elements), iterate `[data-pin]` and stamp `data-pin-skipbadge` on
  // every pin whose rect satisfies `shouldSkipBadge(w, h)` (width or height
  // < 16 px). The complementary `<style data-pinscope-skip-badge>` block
  // rendered inside the visible-HUD portal hides their `::before` badges.
  // The sweep runs once on mount and again on each `MutationObserver` tick;
  // on non-heavy pages it is a no-op (a single `querySelectorAll` count,
  // sub-millisecond — AC-070 / AC-071 unaffected). Cleanup disconnects the
  // observer to avoid leaking across test renders.
  useEffect(() => {
    if (typeof document === 'undefined') return undefined;
    const sweep = (): void => {
      const pins = document.querySelectorAll(`[${PIN_ATTR}]`);
      if (!isHeavyPage(pins.length)) return;
      pins.forEach((el) => {
        if (!(el instanceof HTMLElement)) return;
        const rect = el.getBoundingClientRect();
        if (shouldSkipBadge(rect.width, rect.height)) {
          el.setAttribute('data-pin-skipbadge', '');
        }
      });
    };
    if (typeof MutationObserver === 'undefined') {
      // Best-effort one-shot sweep when MutationObserver is unavailable.
      sweep();
      return undefined;
    }
    sweep();
    const observer = new MutationObserver(() => {
      sweep();
    });
    observer.observe(document.body, { subtree: true, childList: true });
    return () => {
      observer.disconnect();
    };
  }, []);
  // §10 flow B — the locked selection survives mouse-out (§8.1). `selectPin`
  // is the §10-B/§11 programmatic lock the `select e_N` command routes through.
  const { selected, select: selectPin } = useSelectedElement(measuring);

  // §10-C / §10-D flow primitives — instantiated once per HUD mount.
  const command = useMemo(() => {
    // R-18-01 — `persistHistory` is the single history persist owner; wiring
    // it as the manager's persist hook makes every append (CommandBar's and
    // `ClaudeBridge.send`'s) persist through exactly one site.
    const history = new HistoryManager(
      new MemoryHistoryStore(),
      persistHistory,
    );
    // §10-D — the store is held alongside `snapshots` so `onSnapshot` can
    // `flush()` it: `EndpointSnapshotStore.write` is synchronous, so a failed
    // persist is only observable via `flush()`'s rejectable promise.
    const snapshotStore = new EndpointSnapshotStore();
    return {
      history,
      bridge: new ClaudeBridge(history),
      snapshots: new SnapshotManager(snapshotStore),
      snapshotStore,
    };
  }, []);

  /** §10-D — walk all pins → build Snapshot → persist via dev-server route. */
  const onSnapshot = useCallback(
    (name?: string): void => {
      command.snapshots.capture(name);
      // Flow D — observe the persist exactly as flow C observes `bridge.send`:
      // `flush()` resolves the in-flight POST and rejects with a typed
      // `SnapshotPersistError`. Surface a failure on the console, never swallow
      // it (a dropped rejection would otherwise be an unhandled rejection).
      void command.snapshotStore.flush().catch((err: unknown) => {
        console.warn('[pinscope] snapshot persist failed', err);
      });
    },
    [command],
  );

  /**
   * §10-C — parse the CommandBar input, then branch on kind:
   * `operation`/`class`/`query` build a §9.3 `Operation` and go to
   * `ClaudeBridge` (clipboard + history); `select`/`measure`/`snapshot` are
   * local actions. A parse error is surfaced on the console — never swallowed
   * silently and never allowed to break the command flow.
   */
  const onSubmit = useCallback(
    (raw: string): void => {
      let parsed;
      try {
        parsed = parseCommand(raw);
      } catch (err) {
        console.warn('[pinscope] command parse failed', err);
        return;
      }
      if (parsed.kind === 'select') {
        // §10-B / §11 — route through the hook's canonical SelectionManager so
        // the InfoPanel locks (the orphan manager instance was removed).
        selectPin(parsed.pin);
        return;
      }
      if (parsed.kind === 'measure') {
        setMeasuring(true);
        return;
      }
      if (parsed.kind === 'snapshot') {
        onSnapshot(parsed.name);
        return;
      }
      // operation / class / query → §9.3 Operation → ClaudeBridge (flow C).
      // A `query` carries no target pin; `operation`/`class` do.
      const pin = parsed.kind === 'query' ? '' : parsed.pin;
      const context = buildContextFor(pin);
      if (parsed.kind !== 'query' && !context) {
        console.warn(`[pinscope] command target "${pin}" not found`);
        return;
      }
      try {
        const operation = buildOperation(
          parsed,
          context ?? EMPTY_BUILD_CONTEXT,
        );
        void command.bridge.send(operation, raw).catch((err: unknown) => {
          // Dev-only — surface a failed clipboard/history write, never swallow.
          console.warn('[pinscope] operation send failed', err);
        });
      } catch (err) {
        console.warn('[pinscope] operation build failed', err);
      }
    },
    [command, onSnapshot, selectPin],
  );

  // §8.11 keyboard shortcuts drive the root-owned HUD state. Gated on the
  // `shortcutsEnabled` prop so a host can opt out.
  useKeyboardShortcuts(
    shortcutsEnabled
      ? {
          'toggle-hud': () => setHudVisible((v) => !v),
          'grid-cycle': () => setGridMode((m) => nextGridMode(m)),
          'grid-0': () => setGridMode('off'),
          'grid-1': () => setGridMode('pixel'),
          'grid-2': () => setGridMode('baseline'),
          'grid-3': () => setGridMode('column'),
          'grid-4': () => setGridMode('spacing'),
          measure: () => setMeasuring((m) => !m),
          // §10-D — Shift+S captures a snapshot through the dev-server route.
          snapshot: () => onSnapshot(),
          // R-20-03 — §8.11 Shift+P toggles BOTH the CSS-`::before` badge
          // layer (`PinBadges`) AND the JS-overlay layer for void elements
          // (`VoidBadges`, mounted by R-20-01). Driven by `pinsVisible`.
          'toggle-pins': () => setPinsVisible((v) => !v),
          // R-20-03 — §8.11 Shift+C toggles the crosshair via the new
          // `enabled` prop on `<Crosshair/>`.
          crosshair: () => setCrosshairEnabled((v) => !v),
        }
      : {},
  );

  if (typeof document === 'undefined') return null;

  // HUD-hidden branch: only the FloatingToggle is rendered (§7.1).
  if (!hudVisible) {
    return createPortal(
      <div data-pinscope-ui="root">
        <FloatingToggle onShow={() => setHudVisible(true)} />
      </div>,
      document.body,
    );
  }

  return createPortal(
    <div data-pinscope-ui="root">
      {/* R-20-03 — Shift+P toggles BOTH badge layers; R-20-01 mounts VoidBadges
          (JS-overlay for void elements like img/input/br/hr where ::before
          cannot render). The CSS-`::before` layer is `PinBadges`. */}
      {pinsVisible && <PinBadges />}
      {pinsVisible && <VoidBadges />}
      {/* R-21-03 — complementary AC-065 style: hides the CSS-`::before`
          badge for any pin the heavy-page sweep stamped with
          `data-pin-skipbadge`. On non-heavy pages the attribute is never
          set, so this selector matches nothing and is a no-op. */}
      <style data-pinscope-skip-badge="">
        {`[data-pin][data-pin-skipbadge]::before { display: none !important; }`}
      </style>
      <Rulers />
      <Crosshair
        measuring={measuring}
        hudHidden={!hudVisible}
        enabled={crosshairEnabled}
      />
      <GridOverlay mode={gridMode} />
      {/* §10-B — a locked selection takes precedence over the live hover. */}
      <InfoPanel hovered={selected ?? hovered} position={hudPosition} />
      <TopBar
        viewport={viewport}
        gridMode={gridMode}
        stateOverride={stateOverride}
        onSnapshot={() => onSnapshot()}
      />
      <StatePanel onStateChange={setStateOverride} />
      {measuring && <MeasurementTool />}
      <CommandBar onSubmit={onSubmit} history={command.history} />
    </div>,
    document.body,
  );
}
