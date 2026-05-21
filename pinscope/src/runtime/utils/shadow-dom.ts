/** Shadow DOM handling — see SPEC §12. */

const SHADOW_ATTR = 'data-pin-shadow';

/**
 * Mark every Shadow-DOM host under `root` with `data-pin-shadow`. PinScope
 * cannot pin across a shadow boundary, so the InfoPanel reports limited
 * inspection for these hosts. Returns the number of hosts marked.
 */
export function markShadowHosts(root: ParentNode = document): number {
  let count = 0;
  for (const el of Array.from(root.querySelectorAll('*'))) {
    if (el instanceof HTMLElement && el.shadowRoot) {
      el.setAttribute(SHADOW_ATTR, '');
      count += 1;
    }
  }
  return count;
}

/** True when an element is a shadow host with limited inspection. */
export function isShadowLimited(el: Element): boolean {
  return el.hasAttribute(SHADOW_ATTR);
}
