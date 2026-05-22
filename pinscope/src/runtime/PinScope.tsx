/** PinScope root component — see SPEC §7.1. */

import { useState } from 'react';
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
import { FloatingToggle } from './components/FloatingToggle.js';
import { useHoveredElement } from './hooks/useHoveredElement.js';
import { useViewportSize } from './hooks/useViewportSize.js';
import { useKeyboardShortcuts } from './hooks/useKeyboardShortcuts.js';

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
      <InfoPanel hovered={hovered} position={hudPosition} />
      <TopBar viewport={viewport} gridMode={gridMode} stateOverride={null} />
      <CommandBar />
    </div>,
    document.body,
  );
}
