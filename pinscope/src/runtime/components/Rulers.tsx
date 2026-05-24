/** Horizontal + vertical rulers — see SPEC §8.2. */

import { useEffect, useState } from 'react';
import type { CSSProperties, ReactElement } from 'react';
import { useViewportSize } from '../hooks/useViewportSize.js';
import { Z_BADGE } from '../constants.js';

const MONO = "ui-monospace, 'SF Mono', Consolas, monospace";

/**
 * §8.2 tick scales — a major/minor hierarchy. The two minor scales (10, 50)
 * are drawn as repeating-gradient stripes on the bar (one paint, no DOM cost);
 * the two major scales (100, 200) carry individual labelled tick nodes.
 */
const MINOR_SCALES = [10, 50] as const;
const MAJOR_SCALES = [100, 200] as const;
type Scale = 10 | 50 | 100 | 200;

/** Tick mark length in px, keyed by scale — longer for the bigger scales. */
const TICK_LENGTH: Record<Scale, number> = {
  10: 4,
  50: 8,
  100: 14,
  200: 20,
};

/** Stripe colour per minor scale — the 50px stripe is brighter than the 10px. */
const MINOR_COLOR: Record<10 | 50, string> = {
  10: 'rgba(107, 114, 128, 0.35)',
  50: 'rgba(156, 163, 175, 0.6)',
};

// --- static styles, hoisted so jsdom/React parse them once, not per node ---

const BAR_BASE: CSSProperties = {
  position: 'fixed',
  background: '#1f2937',
  color: '#9ca3af',
  font: `10px/1 ${MONO}`,
  zIndex: Z_BADGE,
  pointerEvents: 'none',
};
const BAR_X: CSSProperties = { ...BAR_BASE, top: 0, left: 0, height: 24, width: '100%' };
const BAR_Y: CSSProperties = { ...BAR_BASE, top: 0, left: 0, width: 24, height: '100%' };
const CORNER: CSSProperties = {
  ...BAR_BASE,
  top: 0,
  left: 0,
  width: 24,
  height: 24,
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  justifyContent: 'center',
  fontSize: 7,
  lineHeight: 1.1,
  color: '#e5e7eb',
};
const STRIPE_BASE: CSSProperties = {
  position: 'absolute',
  inset: 0,
  pointerEvents: 'none',
};
/** One static tick base style per major scale + axis (4 objects, parsed once). */
const TICK_X: Record<100 | 200, CSSProperties> = {
  100: {
    position: 'absolute',
    top: 24 - TICK_LENGTH[100] - 4,
    borderLeft: '1px solid #6b7280',
    paddingLeft: 2,
    height: TICK_LENGTH[100],
  },
  200: {
    position: 'absolute',
    top: 24 - TICK_LENGTH[200] - 4,
    borderLeft: '1px solid #6b7280',
    paddingLeft: 2,
    height: TICK_LENGTH[200],
  },
};
const TICK_Y: Record<100 | 200, CSSProperties> = {
  100: {
    position: 'absolute',
    left: 24 - TICK_LENGTH[100] - 4,
    borderTop: '1px solid #6b7280',
    height: TICK_LENGTH[100],
  },
  200: {
    position: 'absolute',
    left: 24 - TICK_LENGTH[200] - 4,
    borderTop: '1px solid #6b7280',
    height: TICK_LENGTH[200],
  },
};
/** Pre-built stripe background images — one per axis + minor scale. */
const STRIPE_BG: Record<'x' | 'y', Record<10 | 50, string>> = {
  x: { 10: stripeGradient('x', 10), 50: stripeGradient('x', 50) },
  y: { 10: stripeGradient('y', 10), 50: stripeGradient('y', 50) },
};

function stripeGradient(axis: 'x' | 'y', scale: 10 | 50): string {
  const dir = axis === 'x' ? 'to right' : 'to bottom';
  const c = MINOR_COLOR[scale];
  return (
    `repeating-linear-gradient(${dir}, ` +
    `${c} 0, ${c} 1px, transparent 1px, transparent ${scale}px)`
  );
}

export interface RulersProps {
  width?: number;
  height?: number;
}

/** The largest major scale (100 first, then 200) that divides `pos`. */
function majorScaleOf(pos: number): 100 | 200 {
  return pos % 200 === 0 ? 200 : 100;
}

/** Positions carrying a labelled major tick: every 100px up to `extent`. */
function majorTicks(extent: number): number[] {
  const out: number[] = [];
  for (let v = 0; v <= extent; v += 100) out.push(v);
  return out;
}

export function Rulers({ width, height }: RulersProps = {}): ReactElement {
  const vp = useViewportSize();
  const w = width ?? vp.width;
  const h = height ?? vp.height;
  const [mouse, setMouse] = useState<{ x: number; y: number }>({ x: 0, y: 0 });

  useEffect(() => {
    const onMove = (e: MouseEvent): void => {
      setMouse({ x: e.clientX, y: e.clientY });
    };
    document.addEventListener('mousemove', onMove, { passive: true });
    return () => document.removeEventListener('mousemove', onMove);
  }, []);

  // Minor ticks (10/50px) — one repeating-gradient stripe element per scale,
  // so a dense tick field costs one paint instead of one DOM node per 10px.
  const stripe = (axis: 'x' | 'y', scale: 10 | 50): ReactElement => (
    <div
      key={`stripe-${axis}-${scale}`}
      data-ruler-stripe={axis}
      data-ruler-scale={String(scale)}
      style={{ ...STRIPE_BASE, backgroundImage: STRIPE_BG[axis][scale] }}
    />
  );

  // The four §8.2 scales are recorded on the rulers root so the multi-scale
  // set is observable: 10/50 via the stripe gradient, 100/200 via tick nodes.
  return (
    <div data-pinscope-rulers="" data-ruler-scales="10,50,100,200">
      <div data-ruler-bar="x" style={BAR_X}>
        {MINOR_SCALES.map((s) => stripe('x', s))}
        {majorTicks(w).map((x) => {
          const scale = majorScaleOf(x);
          return (
            <span
              key={`x${x}`}
              data-ruler-tick="x"
              data-ruler-scale={String(scale)}
              style={{ ...TICK_X[scale], left: x }}
            >
              {x}
            </span>
          );
        })}
      </div>
      <div data-ruler-bar="y" style={BAR_Y}>
        {MINOR_SCALES.map((s) => stripe('y', s))}
        {majorTicks(h).map((y) => {
          const scale = majorScaleOf(y);
          return (
            <span
              key={`y${y}`}
              data-ruler-tick="y"
              data-ruler-scale={String(scale)}
              style={{ ...TICK_Y[scale], top: y }}
            >
              {y}
            </span>
          );
        })}
      </div>
      <div data-pinscope-ruler-corner="" style={CORNER}>
        <span data-ruler-coord="x">{mouse.x}</span>
        <span data-ruler-coord="y">{mouse.y}</span>
      </div>
    </div>
  );
}
