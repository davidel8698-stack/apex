/** Grid overlay — see SPEC §8.4. */

import type { ReactElement } from 'react';
import { Z_BADGE } from '../constants.js';

export type GridMode = 'off' | 'pixel' | 'baseline' | 'column' | 'spacing';

/** Toggle order: off -> pixel -> baseline -> column -> spacing -> off. */
const ORDER: readonly GridMode[] = [
  'off',
  'pixel',
  'baseline',
  'column',
  'spacing',
];

/** The next grid mode in the SPEC §8.4 cycle. */
export function nextGridMode(mode: GridMode): GridMode {
  const index = ORDER.indexOf(mode);
  return ORDER[(index + 1) % ORDER.length] as GridMode;
}

const CELL: Record<GridMode, number> = {
  off: 0,
  pixel: 8,
  baseline: 4,
  column: 96,
  spacing: 8,
};

export function GridOverlay({ mode }: { mode: GridMode }): ReactElement | null {
  if (mode === 'off') return null;
  const cell = CELL[mode];
  const patternId = `pinscope-grid-${mode}`;
  return (
    <svg
      data-pinscope-grid={mode}
      width="100%"
      height="100%"
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: Z_BADGE,
        pointerEvents: 'none',
      }}
    >
      <defs>
        <pattern
          id={patternId}
          data-grid-pattern={mode}
          width={cell}
          height={cell}
          patternUnits="userSpaceOnUse"
        >
          <path
            d={`M ${cell} 0 L 0 0 0 ${cell}`}
            fill="none"
            stroke="rgba(59, 130, 246, 0.3)"
            strokeWidth="1"
          />
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill={`url(#${patternId})`} />
    </svg>
  );
}
