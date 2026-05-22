/** Selection hook — §10 flow B; see SPEC §8.1, §8.9. */

import { useEffect, useRef, useState } from 'react';
import type { HoveredElement } from '../../types/element-info.js';
import { PIN_ATTR } from '../constants.js';
import { SelectionManager } from '../managers/SelectionManager.js';
import { escapeHud, findPinnedAncestor } from '../utils/element-walker.js';

export interface SelectedElement {
  /** The pinned element currently locked by `SelectionManager`, or `null`. */
  selected: HoveredElement | null;
  /** Clear the locked selection (§8.9 `SelectionManager.clear`). */
  clear: () => void;
}

/** Build a `HoveredElement` view of the pin id the manager currently holds. */
function resolveSelected(pinId: string | null): HoveredElement | null {
  if (!pinId || typeof document === 'undefined') return null;
  const el = document.querySelector(`[${PIN_ATTR}="${pinId}"]`);
  if (!(el instanceof HTMLElement)) return null;
  return { element: el, pinId, rect: el.getBoundingClientRect() };
}

/**
 * Own a `SelectionManager` and wire §10 flow B: a `click` on a `[data-pin]`
 * element (escaping the HUD subtree, then walking to the pinned ancestor)
 * runs `SelectionManager.select`, which moves the `data-pin-selected`
 * attribute and mirrors the pin to the URL hash. `Escape` and a click outside
 * any pin unlock/clear the selection (§8.1).
 *
 * `measuring` suppresses selection: while measurement mode is active the
 * `MeasurementTool` owns clicks, so the handler early-returns — mirroring how
 * the Crosshair is suppressed in measurement mode (§8.3).
 */
export function useSelectedElement(measuring: boolean): SelectedElement {
  const managerRef = useRef<SelectionManager | null>(null);
  if (managerRef.current === null) managerRef.current = new SelectionManager();
  const manager = managerRef.current;

  const [selected, setSelected] = useState<HoveredElement | null>(() =>
    resolveSelected(manager.selectedPin),
  );

  // `measuring` is read inside the click handler — keep a ref so the listener
  // (bound once) always sees the live value without rebinding.
  const measuringRef = useRef(measuring);
  measuringRef.current = measuring;

  useEffect(() => {
    const onClick = (e: MouseEvent): void => {
      // Selection is suppressed while the MeasurementTool owns clicks (§8.3).
      if (measuringRef.current) return;
      const target = e.target instanceof HTMLElement ? e.target : null;
      const pinned = findPinnedAncestor(escapeHud(target));
      const pinId = pinned?.getAttribute(PIN_ATTR) ?? null;
      if (pinned && pinId) {
        manager.select(pinId);
        setSelected(resolveSelected(pinId));
      } else {
        // Click-outside any pin clears the locked selection (§8.1).
        manager.clear();
        setSelected(null);
      }
    };
    const onKey = (e: KeyboardEvent): void => {
      // Esc unlocks the selection (§8.1).
      if (e.key === 'Escape') {
        manager.unlock();
        manager.clear();
        setSelected(null);
      }
    };
    document.addEventListener('click', onClick);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('click', onClick);
      document.removeEventListener('keydown', onKey);
    };
  }, [manager]);

  const clear = (): void => {
    manager.clear();
    setSelected(null);
  };

  return { selected, clear };
}
