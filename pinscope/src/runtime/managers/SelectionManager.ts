/** Selection state + URL-hash mirroring — see SPEC §8.9. */

import { PIN_ATTR, SELECTED_ATTR } from '../constants.js';

const HASH_RE = /#select=(e_r?\d+)/;

export class SelectionManager {
  private selected: string | null = null;
  private locked = false;
  private readonly history: string[] = [];

  constructor() {
    this.restoreFromHash();
  }

  get selectedPin(): string | null {
    return this.selected;
  }

  get isLocked(): boolean {
    return this.locked;
  }

  /** Lock selection onto a pin and mirror it to the URL hash. */
  select(pinId: string, lock = true): void {
    this.applyAttr(this.selected, false);
    this.selected = pinId;
    this.locked = lock;
    this.history.push(pinId);
    this.applyAttr(pinId, true);
    this.syncHash();
  }

  /** Transient hover selection — ignored while locked. */
  hover(pinId: string): void {
    if (!this.locked) this.selected = pinId;
  }

  unlock(): void {
    this.locked = false;
  }

  clear(): void {
    this.applyAttr(this.selected, false);
    this.selected = null;
    this.locked = false;
    this.syncHash();
  }

  /** Step back through selection history. */
  goBack(): string | null {
    this.history.pop();
    const prev = this.history[this.history.length - 1] ?? null;
    if (prev) this.select(prev);
    else this.clear();
    return prev;
  }

  private restoreFromHash(): void {
    if (typeof location === 'undefined') return;
    const match = HASH_RE.exec(location.hash);
    if (match) {
      this.selected = match[1] ?? null;
      this.locked = true;
    }
  }

  private syncHash(): void {
    if (typeof location === 'undefined') return;
    if (this.selected) {
      location.hash = `select=${this.selected}`;
    } else if (location.hash.startsWith('#select=')) {
      location.hash = '';
    }
  }

  private applyAttr(pinId: string | null, on: boolean): void {
    if (!pinId || typeof document === 'undefined') return;
    const el = document.querySelector(`[${PIN_ATTR}="${pinId}"]`);
    if (!el) return;
    if (on) el.setAttribute(SELECTED_ATTR, '');
    else el.removeAttribute(SELECTED_ATTR);
  }
}
