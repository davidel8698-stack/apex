/** Hover detection hook — see SPEC §7.3. */

import { useEffect, useRef, useState } from 'react';
import type { HoveredElement } from '../../types/element-info.js';
import { PIN_ATTR } from '../constants.js';
import { escapeHud, findPinnedAncestor } from '../utils/element-walker.js';

/**
 * Track the pinned element currently under the cursor. `mousemove` is
 * throttled through `requestAnimationFrame` (one resolve per frame).
 */
export function useHoveredElement(): HoveredElement | null {
  const [hovered, setHovered] = useState<HoveredElement | null>(null);
  const rafRef = useRef<number | null>(null);
  const lastPos = useRef<{ x: number; y: number } | null>(null);

  useEffect(() => {
    const handleMove = (e: MouseEvent): void => {
      lastPos.current = { x: e.clientX, y: e.clientY };
      if (rafRef.current !== null) return;
      rafRef.current = requestAnimationFrame(() => {
        rafRef.current = null;
        const pos = lastPos.current;
        if (!pos) return;
        const atPoint = document.elementFromPoint(pos.x, pos.y);
        const outside = escapeHud(
          atPoint instanceof HTMLElement ? atPoint : null,
        );
        const pinned = findPinnedAncestor(outside);
        const pinId = pinned?.getAttribute(PIN_ATTR) ?? null;
        if (!pinned || !pinId) {
          setHovered(null);
          return;
        }
        setHovered({
          element: pinned,
          pinId,
          rect: pinned.getBoundingClientRect(),
        });
      });
    };
    const handleLeave = (): void => setHovered(null);

    document.addEventListener('mousemove', handleMove, { passive: true });
    document.addEventListener('mouseleave', handleLeave);
    return () => {
      document.removeEventListener('mousemove', handleMove);
      document.removeEventListener('mouseleave', handleLeave);
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    };
  }, []);

  return hovered;
}
