/** PinScope root component — see SPEC §7.1, §10 flows B/C/D. */

import { useCallback, useMemo, useState } from 'react';
import type { ReactElement } from 'react';
import { createPortal } from 'react-dom';
import { PinBadges } from './components/PinBadges.js';
import { InfoPanel } from './components/InfoPanel.js';
import { Rulers } from './components/Rulers.js';
import { Crosshair } from './components/Crosshair.js';
import { GridOverlay, nextGridMode } from './components/GridOverlay.js';
import type { GridMode } from './components/GridOverlay.js';
import { TopBar } from './components/TopBar.js';
import { CommandBar } from './components/CommandBar.js';
import { MeasurementTool } from './components/MeasurementTool.js';
import { StatePanel } from './components/StatePanel.js';
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
  // §10 flow B — the locked selection survives mouse-out (§8.1). `selectPin`
  // is the §10-B/§11 programmatic lock the `select e_N` command routes through.
  const { selected, select: selectPin } = useSelectedElement(measuring);

  // §10-C / §10-D flow primitives — instantiated once per HUD mount.
  const command = useMemo(() => {
    const history = new HistoryManager(new MemoryHistoryStore());
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
      <PinBadges />
      <Rulers />
      <Crosshair measuring={measuring} hudHidden={!hudVisible} />
      <GridOverlay mode={gridMode} />
      {/* §10-B — a locked selection takes precedence over the live hover. */}
      <InfoPanel hovered={selected ?? hovered} position={hudPosition} />
      <TopBar
        viewport={viewport}
        gridMode={gridMode}
        stateOverride={null}
        onSnapshot={() => onSnapshot()}
      />
      <StatePanel />
      {measuring && <MeasurementTool />}
      <CommandBar onSubmit={onSubmit} history={command.history} />
    </div>,
    document.body,
  );
}
