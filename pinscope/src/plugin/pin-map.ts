/** PinMap manager — see SPEC.md §6.3 + resolution I-2 (`reconcile`). */

import fs from 'node:fs';
import type { PinMapData, PinMapEntry } from '../types/pin-map.js';

export class PinMap {
  private data: PinMapData = { version: 1, next_id: 1, entries: {} };
  private dirty = false;
  private seen = new Set<string>();

  constructor(private readonly filePath: string) {}

  /** Load `.pinmap.json` if it exists; a missing file is a fresh start. */
  load(): void {
    this.seen.clear();
    if (!fs.existsSync(this.filePath)) return;
    try {
      const parsed = JSON.parse(
        fs.readFileSync(this.filePath, 'utf-8'),
      ) as PinMapData;
      this.migrate(parsed);
      this.data = parsed;
    } catch (err) {
      console.warn(
        `[PinScope] Could not load PinMap from ${this.filePath}`,
        err,
      );
    }
  }

  /** Persist to disk only when something changed. */
  save(): void {
    if (!this.dirty) return;
    fs.writeFileSync(
      this.filePath,
      JSON.stringify(this.data, null, 2),
      'utf-8',
    );
    this.dirty = false;
  }

  /**
   * Return the stable id for a key, allocating a new one on first sight.
   * Ids monotonically increase and are never reused.
   */
  getOrAssign(key: string, tag: string): string {
    this.seen.add(key);
    const now = new Date().toISOString();
    const existing = this.data.entries[key];
    if (existing) {
      existing.last_seen = now;
      delete existing.deleted;
      this.dirty = true;
      return existing.id;
    }
    const id = `e_${this.data.next_id++}`;
    this.data.entries[key] = { id, tag, created: now, last_seen: now };
    this.dirty = true;
    return id;
  }

  /**
   * Mark entries not seen during this build as `deleted` (SPEC §6.4, I-2).
   * Ids are retained, never reused. Pass `seenKeys` explicitly or rely on the
   * keys accumulated by `getOrAssign` since the last `load`.
   */
  reconcile(seenKeys?: Iterable<string>): void {
    const seen = seenKeys ? new Set(seenKeys) : this.seen;
    for (const [key, entry] of Object.entries(this.data.entries)) {
      if (!seen.has(key) && entry.deleted !== true) {
        entry.deleted = true;
        this.dirty = true;
      }
    }
  }

  /** Number of entries (including soft-deleted). */
  get size(): number {
    return Object.keys(this.data.entries).length;
  }

  /** Test/inspection accessor — returns a structural copy. */
  snapshot(): PinMapData {
    return JSON.parse(JSON.stringify(this.data)) as PinMapData;
  }

  private migrate(parsed: PinMapData): void {
    if (parsed.version !== 1) {
      throw new Error(`Unsupported PinMap version: ${String(parsed.version)}`);
    }
  }
}

export type { PinMapData, PinMapEntry };
