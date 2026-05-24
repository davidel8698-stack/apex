/** Mouse crosshair lines — see SPEC §8.3. */

import { useEffect, useState } from 'react';
import type { CSSProperties, ReactElement } from 'react';
import { HUD_ROOT_ATTR, Z_HOVER } from '../constants.js';

export interface CrosshairProps {
  /** Disabled while the MeasurementTool owns the pointer (§8.3). */
  measuring?: boolean;
  /** Disabled while the HUD is hidden (§8.3). */
  hudHidden?: boolean;
  /**
   * R-20-03 — §8.11 Shift+C toggle. When `false`, the crosshair is hidden.
   * Defaults to `true` so the HUD opens with the crosshair on (no behavioral
   * change vs. PS-R19).
   */
  enabled?: boolean;
}

export function Crosshair({
  measuring = false,
  hudHidden = false,
  enabled = true,
}: CrosshairProps = {}): ReactElement | null {
  const [pos, setPos] = useState<{ x: number; y: number } | null>(null);

  useEffect(() => {
    const onMove = (e: MouseEvent): void => {
      const target = e.target;
      if (target instanceof Element && target.closest(`[${HUD_ROOT_ATTR}]`)) {
        setPos(null);
        return;
      }
      setPos({ x: e.clientX, y: e.clientY });
    };
    document.addEventListener('mousemove', onMove, { passive: true });
    return () => document.removeEventListener('mousemove', onMove);
  }, []);

  // §8.3 — disabled over HUD (handled in onMove), in measurement mode, or
  // when the HUD is hidden. R-20-03 — also disabled when `enabled === false`
  // (Shift+C toggle).
  if (measuring || hudHidden || !enabled) return null;
  if (!pos) return null;

  const line: CSSProperties = {
    position: 'fixed',
    background: 'rgba(239, 68, 68, 0.6)',
    zIndex: Z_HOVER,
    pointerEvents: 'none',
  };
  return (
    <div data-pinscope-crosshair="">
      <div
        data-crosshair="v"
        style={{ ...line, left: pos.x, top: 0, width: 1, height: '100%' }}
      />
      <div
        data-crosshair="h"
        style={{ ...line, top: pos.y, left: 0, height: 1, width: '100%' }}
      />
    </div>
  );
}
