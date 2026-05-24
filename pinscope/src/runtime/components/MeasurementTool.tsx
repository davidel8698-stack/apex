/** Two-click measurement tool — see SPEC §8.7. */

import { useEffect, useState } from 'react';
import type { CSSProperties, ReactElement } from 'react';
import { Z_SELECTED } from '../constants.js';

export interface Point {
  x: number;
  y: number;
}

export interface Measurement {
  dx: number;
  dy: number;
  diagonal: number;
  gap: number;
}

/** Δx / Δy / diagonal / gap between two points. */
export function measure(a: Point, b: Point): Measurement {
  const dx = Math.abs(b.x - a.x);
  const dy = Math.abs(b.y - a.y);
  return {
    dx,
    dy,
    diagonal: Math.round(Math.hypot(dx, dy)),
    gap: Math.min(dx, dy),
  };
}

export function MeasurementTool(): ReactElement | null {
  const [points, setPoints] = useState<Point[]>([]);

  useEffect(() => {
    const onClick = (e: MouseEvent): void => {
      const point = { x: e.clientX, y: e.clientY };
      setPoints((prev) => (prev.length >= 2 ? [point] : [...prev, point]));
    };
    document.addEventListener('click', onClick);
    return () => document.removeEventListener('click', onClick);
  }, []);

  const [a, b] = points;
  if (!a || !b) return null;
  const m = measure(a, b);

  const box: CSSProperties = {
    position: 'fixed',
    top: 56,
    left: 16,
    background: '#111827',
    color: '#e5e7eb',
    font: "12px ui-monospace, monospace",
    padding: 8,
    borderRadius: 6,
    zIndex: Z_SELECTED,
  };
  return (
    <div data-pinscope-measure="" style={box}>
      <span data-measure="dx">Δx {m.dx}</span>{' '}
      <span data-measure="dy">Δy {m.dy}</span>{' '}
      <span data-measure="diagonal">↘ {m.diagonal}</span>{' '}
      <span data-measure="gap">gap {m.gap}</span>
    </div>
  );
}
