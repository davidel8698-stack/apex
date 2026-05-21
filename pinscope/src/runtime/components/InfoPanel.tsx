/** Hover/selection inspector panel — see SPEC §8.1. */

import type { CSSProperties, ReactElement } from 'react';
import type { HoveredElement } from '../../types/element-info.js';
import { Z_SELECTED } from '../constants.js';

export interface InfoPanelProps {
  hovered: HoveredElement | null;
  position?: 'left' | 'right';
}

/** Format a pixel value: integer when whole, one decimal otherwise. */
function px(n: number): string {
  return Number.isInteger(n) ? `${n}px` : `${n.toFixed(1)}px`;
}

/**
 * PS-R2 scope: the Dimensions / Spacing / Typography sections. Appearance,
 * Layout and Hierarchy sections are deferred to a later round (AC-031).
 */
export function InfoPanel({
  hovered,
  position = 'right',
}: InfoPanelProps): ReactElement | null {
  if (!hovered) return null;
  const { element, pinId, rect } = hovered;
  const cs =
    typeof getComputedStyle === 'function' ? getComputedStyle(element) : null;

  const style: CSSProperties = {
    position: 'fixed',
    top: 56,
    width: 320,
    background: '#111827',
    color: '#e5e7eb',
    font: "12px/1.5 ui-monospace, 'SF Mono', Consolas, monospace",
    padding: 12,
    borderRadius: 8,
    zIndex: Z_SELECTED,
  };
  if (position === 'right') style.right = 16;
  else style.left = 16;

  return (
    <div data-pinscope-panel="" style={style}>
      <div data-testid="pin-id">
        {pinId} · {element.tagName.toLowerCase()}
      </div>
      <section data-testid="dimensions">
        <div>Width {px(rect.width)}</div>
        <div>Height {px(rect.height)}</div>
        <div>
          X / Y {Math.round(rect.x)} / {Math.round(rect.y)}
        </div>
      </section>
      <section data-testid="spacing">
        <div>Padding {cs?.padding || '—'}</div>
        <div>Margin {cs?.margin || '—'}</div>
      </section>
      <section data-testid="typography">
        <div>Family {cs?.fontFamily || '—'}</div>
        <div>Size {cs?.fontSize || '—'}</div>
        <div>Weight {cs?.fontWeight || '—'}</div>
      </section>
    </div>
  );
}
