/** Runtime pin assignment for dynamic content — see SPEC §12. */

import { PIN_ATTR } from '../constants.js';

/**
 * Assigns `e_r{N}` ids to elements added to the DOM after build time, so
 * dynamically-rendered UI is still inspectable. The `e_r` prefix keeps the
 * runtime id space distinct from the build-time `e_N` space.
 */
export class RuntimePinObserver {
  private counter = 0;
  private observer: MutationObserver | null = null;

  /** Begin watching `root` for added subtrees. */
  start(root: Node = document.body): void {
    if (this.observer) return;
    this.observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of Array.from(mutation.addedNodes)) {
          if (node instanceof HTMLElement) this.assign(node);
        }
      }
    });
    this.observer.observe(root, { childList: true, subtree: true });
  }

  /** Stop watching. */
  stop(): void {
    this.observer?.disconnect();
    this.observer = null;
  }

  /** Assign runtime ids to `el` and every descendant that lacks a pin. */
  assign(el: HTMLElement): void {
    const all: Element[] = [el, ...Array.from(el.querySelectorAll('*'))];
    for (const node of all) {
      if (node instanceof HTMLElement && node.getAttribute(PIN_ATTR) === null) {
        node.setAttribute(PIN_ATTR, `e_r${++this.counter}`);
      }
    }
  }
}
