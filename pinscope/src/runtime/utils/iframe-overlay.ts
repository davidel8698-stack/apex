/** Cross-origin iframe handling — see SPEC §12 (Edge Cases) and Appendix A.5. */

import { PIN_ATTR, Z_SELECTED } from '../constants.js';

/** Attribute marking an `<iframe>` PinScope can only outline (cross-origin). */
export const IFRAME_ATTR = 'data-pin-iframe';

/** Attribute marking a generated cross-origin iframe outline overlay. */
export const IFRAME_OVERLAY_ATTR = 'data-pinscope-iframe-overlay';

/**
 * True when an `<iframe>` is cross-origin. PinScope cannot inject into a
 * cross-origin frame: reading `contentDocument` throws a `SecurityError` or
 * yields `null`. A live same-origin `Document` returns `false`.
 */
export function isCrossOriginFrame(frame: HTMLIFrameElement): boolean {
  try {
    const doc = frame.contentDocument;
    return !doc;
  } catch {
    return true;
  }
}

/**
 * Sweep `root` for `<iframe>` elements and, for every cross-origin frame,
 * stamp `data-pin-iframe` and draw an outline + label overlay (no injection).
 * Same-origin frames are left untouched. Returns the number of cross-origin
 * frames marked.
 */
export function markCrossOriginFrames(root: ParentNode = document): number {
  // R-26-01 reconciliation pass — purge any overlays from a prior invocation
  // so repeated calls remain idempotent (one overlay per cross-origin frame).
  const overlayHost =
    (root as Node & { ownerDocument?: Document | null }).ownerDocument ??
    document;
  for (const stale of Array.from(
    overlayHost.querySelectorAll('[data-pinscope-iframe-overlay]'),
  )) {
    stale.remove();
  }

  let count = 0;
  for (const frame of Array.from(root.querySelectorAll('iframe'))) {
    if (!isCrossOriginFrame(frame)) continue;

    frame.setAttribute(IFRAME_ATTR, '');

    const rect = frame.getBoundingClientRect();
    const overlay = document.createElement('div');
    overlay.setAttribute(IFRAME_OVERLAY_ATTR, '');
    overlay.style.position = 'absolute';
    overlay.style.top = `${rect.top}px`;
    overlay.style.left = `${rect.left}px`;
    overlay.style.width = `${rect.width}px`;
    overlay.style.height = `${rect.height}px`;
    overlay.style.outline = '2px dashed currentColor';
    overlay.style.pointerEvents = 'none';
    overlay.style.zIndex = String(Z_SELECTED);

    let label = frame.getAttribute(PIN_ATTR);
    if (!label) {
      try {
        label = new URL(frame.src).host;
      } catch {
        label = frame.src;
      }
    }
    const labelEl = document.createElement('div');
    labelEl.textContent = label;
    overlay.appendChild(labelEl);

    document.body.appendChild(overlay);
    count += 1;
  }
  return count;
}

/** True when an element is a cross-origin iframe with limited inspection. */
export function isIframeLimited(el: Element): boolean {
  return el.hasAttribute(IFRAME_ATTR);
}
