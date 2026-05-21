/** DOM-walking utilities for hover detection — see SPEC §7.3. */

import { HUD_ROOT_ATTR, PIN_ATTR } from '../constants.js';

/**
 * Walk out of the PinScope HUD. Given an element, return the first ancestor
 * (or the element itself) that is not inside `[data-pinscope-ui]`.
 */
export function escapeHud(el: HTMLElement | null): HTMLElement | null {
  let current = el;
  while (current && current.closest(`[${HUD_ROOT_ATTR}]`)) {
    current = current.parentElement;
  }
  return current;
}

/**
 * Walk up to the nearest ancestor (inclusive) carrying a `data-pin`
 * attribute. Returns null if none is found.
 */
export function findPinnedAncestor(el: HTMLElement | null): HTMLElement | null {
  let current = el;
  while (current && current.getAttribute(PIN_ATTR) === null) {
    current = current.parentElement;
  }
  return current;
}
