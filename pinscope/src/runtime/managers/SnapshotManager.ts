/** Snapshot system — see SPEC §8.10, §9.2. */

import type { Snapshot, ElementSnapshot } from '../../types/snapshot.js';
import { PIN_ATTR } from '../constants.js';

/** The 32 computed-style properties captured per element. */
const TRACKED_STYLES: readonly string[] = [
  'display', 'position', 'width', 'height', 'padding', 'margin', 'border',
  'color', 'background-color', 'font-family', 'font-size', 'font-weight',
  'line-height', 'border-radius', 'box-shadow', 'opacity', 'z-index',
  'flex', 'flex-direction', 'justify-content', 'align-items', 'gap',
  'grid-template-columns', 'overflow', 'text-align', 'letter-spacing',
  'transform', 'transition', 'cursor', 'visibility', 'box-sizing', 'inset',
];

export interface SnapshotStore {
  write(snapshot: Snapshot): void;
}

/** Default in-memory store. */
export class MemorySnapshotStore implements SnapshotStore {
  readonly snapshots: Snapshot[] = [];
  write(snapshot: Snapshot): void {
    this.snapshots.push(snapshot);
  }
}

function snapshotElement(el: HTMLElement): ElementSnapshot {
  const rect = el.getBoundingClientRect();
  const cs = typeof getComputedStyle === 'function' ? getComputedStyle(el) : null;

  const computed: Record<string, string> = {};
  if (cs) {
    for (const prop of TRACKED_STYLES) computed[prop] = cs.getPropertyValue(prop);
  }

  const attributes: Record<string, string> = {};
  for (const attr of Array.from(el.attributes)) attributes[attr.name] = attr.value;

  const childPins: string[] = [];
  for (const child of Array.from(el.querySelectorAll(`[${PIN_ATTR}]`))) {
    const cid = child.getAttribute(PIN_ATTR);
    if (cid && child.parentElement?.closest(`[${PIN_ATTR}]`) === el) {
      childPins.push(cid);
    }
  }

  const vw = typeof window !== 'undefined' ? window.innerWidth : 0;
  const vh = typeof window !== 'undefined' ? window.innerHeight : 0;
  const parent = el.parentElement?.closest(`[${PIN_ATTR}]`) ?? null;

  return {
    tag: el.tagName.toLowerCase(),
    classes: Array.from(el.classList),
    attributes,
    text_content: el.textContent?.trim().slice(0, 120) || undefined,
    rect: { x: rect.x, y: rect.y, w: rect.width, h: rect.height },
    computed_styles: computed,
    parent_pin: parent?.getAttribute(PIN_ATTR) ?? undefined,
    children_pins: childPins,
    visible: rect.width > 0 && rect.height > 0,
    in_viewport:
      rect.top < vh && rect.bottom > 0 && rect.left < vw && rect.right > 0,
  };
}

/** Walk every `[data-pin]` element and build a §9.2 Snapshot. */
export function createSnapshot(name?: string, doc: Document = document): Snapshot {
  const pinned = Array.from(doc.querySelectorAll(`[${PIN_ATTR}]`)).filter(
    (el): el is HTMLElement => el instanceof HTMLElement,
  );

  const elements: Record<string, ElementSnapshot> = {};
  let visible = 0;
  let inViewport = 0;
  for (const el of pinned) {
    const pinId = el.getAttribute(PIN_ATTR);
    if (!pinId) continue;
    const snap = snapshotElement(el);
    elements[pinId] = snap;
    if (snap.visible) visible++;
    if (snap.in_viewport) inViewport++;
  }

  return {
    version: '1.0',
    id: `s_${Date.now()}`,
    name,
    created: new Date().toISOString(),
    viewport: {
      width: typeof window !== 'undefined' ? window.innerWidth : 0,
      height: typeof window !== 'undefined' ? window.innerHeight : 0,
    },
    url: typeof location !== 'undefined' ? location.href : '',
    user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
    device_pixel_ratio:
      typeof window !== 'undefined' ? window.devicePixelRatio : 1,
    elements,
    summary: {
      total_elements: pinned.length,
      visible_elements: visible,
      in_viewport: inViewport,
    },
  };
}

export class SnapshotManager {
  private readonly store: SnapshotStore;

  constructor(store: SnapshotStore) {
    this.store = store;
  }

  /** Build a snapshot and persist it through the store. */
  capture(name?: string, doc?: Document): Snapshot {
    const snapshot = createSnapshot(name, doc);
    this.store.write(snapshot);
    return snapshot;
  }
}
