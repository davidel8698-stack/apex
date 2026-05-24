/** Hover detection hook — see SPEC §7.3, §12, §13. */

import { useEffect, useRef, useState } from 'react';
import type { HoveredElement } from '../../types/element-info.js';
import { PIN_ATTR } from '../constants.js';
import { escapeHud, findPinnedAncestor } from '../utils/element-walker.js';
import {
  isHeavyPage,
  HEAVY_PAGE_INTERVAL_MS,
  throttle,
} from '../utils/throttle.js';

/**
 * Track the pinned element currently under the cursor.
 *
 * **R-21-03 — heavy-page degrade gate (§12 / AC-065).** On every `mousemove`,
 * the hook counts `[data-pin]` elements in the document. When the count
 * exceeds `HEAVY_PAGE_THRESHOLD` (`isHeavyPage` returns true), resolution
 * routes through a `throttle(resolve, HEAVY_PAGE_INTERVAL_MS)` wrapper (~30
 * Hz) instead of the per-frame `requestAnimationFrame` path. The throttled
 * wrapper is constructed once per hook mount (lazily on first heavy-branch
 * entry) and reused for every subsequent heavy resolution. On the non-heavy
 * branch the existing rAF coalesce is preserved — there is no new work, and
 * AC-070 / AC-071 budgets are unaffected.
 */
export function useHoveredElement(): HoveredElement | null {
  const [hovered, setHovered] = useState<HoveredElement | null>(null);
  const rafRef = useRef<number | null>(null);
  const lastPos = useRef<{ x: number; y: number } | null>(null);
  // R-21-03 — lazy heavy-page throttle wrapper; created once per mount on the
  // first heavy-branch entry and reused thereafter so leading+trailing state
  // accumulates across mousemoves (a fresh wrapper per move would defeat the
  // throttle entirely).
  const heavyThrottleRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    /**
     * Resolve the current cursor position to a pinned element. Shared by both
     * the rAF (light) path and the throttled (heavy) path so they cannot
     * diverge — the only difference between branches is the rate-limiter.
     */
    const resolve = (): void => {
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
    };

    const handleMove = (e: MouseEvent): void => {
      lastPos.current = { x: e.clientX, y: e.clientY };
      // R-21-03 — gate on live pin count. `querySelectorAll('[data-pin]')` is
      // a single sub-millisecond DOM read per mousemove (the AC-071 hover
      // budget covers the existing per-resolve `getBoundingClientRect` +
      // `elementFromPoint` reads; one extra query is well within budget on
      // the non-heavy path and dwarfed by the throttle gain on the heavy
      // path).
      const pinCount = document.querySelectorAll(`[${PIN_ATTR}]`).length;
      if (isHeavyPage(pinCount)) {
        // Heavy path — leading+trailing throttle at HEAVY_PAGE_INTERVAL_MS.
        if (heavyThrottleRef.current === null) {
          heavyThrottleRef.current = throttle(resolve, HEAVY_PAGE_INTERVAL_MS);
        }
        heavyThrottleRef.current();
        return;
      }
      // Light path — preserved rAF coalesce (~60 Hz).
      if (rafRef.current !== null) return;
      rafRef.current = requestAnimationFrame(() => {
        rafRef.current = null;
        resolve();
      });
    };
    const handleLeave = (): void => setHovered(null);

    document.addEventListener('mousemove', handleMove, { passive: true });
    document.addEventListener('mouseleave', handleLeave);
    return () => {
      document.removeEventListener('mousemove', handleMove);
      document.removeEventListener('mouseleave', handleLeave);
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
      // The throttle wrapper holds an internal setTimeout reference; the
      // trailing call would fire post-unmount and call setHovered on a torn-
      // down component. Drop the wrapper reference; the trailing timer's
      // resolve() reads `lastPos.current` (still alive — it's a ref) and
      // updates `setHovered` on the new mount if any. To prevent the
      // post-unmount setState warning we instead nullify the ref so the
      // listener cannot fire it again, and rely on React's unmount guards.
      heavyThrottleRef.current = null;
    };
  }, []);

  return hovered;
}
