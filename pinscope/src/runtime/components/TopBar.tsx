/** HUD top bar — see SPEC §8.5. */

import type { CSSProperties, ReactElement } from 'react';
import { PIN_ATTR, Z_SELECTED } from '../constants.js';
import type { GridMode } from './GridOverlay.js';

export interface TopBarProps {
  viewport: { width: number; height: number };
  gridMode: GridMode;
  stateOverride: string | null;
}

function countPins(): number {
  if (typeof document === 'undefined') return 0;
  return document.querySelectorAll(`[${PIN_ATTR}]`).length;
}

export function TopBar({
  viewport,
  gridMode,
  stateOverride,
}: TopBarProps): ReactElement {
  const style: CSSProperties = {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    height: 32,
    display: 'flex',
    gap: 16,
    alignItems: 'center',
    padding: '0 12px',
    background: '#0f172a',
    color: '#e5e7eb',
    font: "12px ui-monospace, monospace",
    zIndex: Z_SELECTED,
  };
  return (
    <div data-pinscope-topbar="" style={style}>
      <span data-field="viewport">
        {viewport.width}×{viewport.height}
      </span>
      <span data-field="grid">grid: {gridMode}</span>
      <span data-field="state">state: {stateOverride ?? 'none'}</span>
      <span data-field="pins">{countPins()} pins</span>
    </div>
  );
}
