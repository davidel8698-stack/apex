/** Horizontal + vertical rulers — see SPEC §8.2. */

import type { CSSProperties, ReactElement } from 'react';
import { useViewportSize } from '../hooks/useViewportSize.js';
import { Z_BADGE } from '../constants.js';

const MONO = "ui-monospace, 'SF Mono', Consolas, monospace";

export interface RulersProps {
  width?: number;
  height?: number;
  /** Tick spacing in px. */
  interval?: number;
}

function ticks(extent: number, interval: number): number[] {
  const out: number[] = [];
  for (let v = 0; v <= extent; v += interval) out.push(v);
  return out;
}

export function Rulers({
  width,
  height,
  interval = 100,
}: RulersProps): ReactElement {
  const vp = useViewportSize();
  const w = width ?? vp.width;
  const h = height ?? vp.height;

  const bar: CSSProperties = {
    position: 'fixed',
    background: '#1f2937',
    color: '#9ca3af',
    font: `10px/1 ${MONO}`,
    zIndex: Z_BADGE,
    pointerEvents: 'none',
  };

  return (
    <div data-pinscope-rulers="">
      <div style={{ ...bar, top: 0, left: 0, height: 24, width: '100%' }}>
        {ticks(w, interval).map((x) => (
          <span
            key={`x${x}`}
            data-ruler-tick="x"
            style={{ position: 'absolute', left: x, top: 6 }}
          >
            {x}
          </span>
        ))}
      </div>
      <div style={{ ...bar, top: 0, left: 0, width: 24, height: '100%' }}>
        {ticks(h, interval).map((y) => (
          <span
            key={`y${y}`}
            data-ruler-tick="y"
            style={{ position: 'absolute', top: y, left: 4 }}
          >
            {y}
          </span>
        ))}
      </div>
    </div>
  );
}
