/** Runtime element-inspection types — see SPEC.md §7.3, §8.1. */

import type { ElementRect } from './snapshot.js';

export interface HoveredElement {
  element: HTMLElement;
  pinId: string;
  rect: DOMRect;
}

export interface ElementInfo {
  pinId: string;
  tag: string;
  rect: ElementRect;
  computedStyles: Record<string, string>;
}
