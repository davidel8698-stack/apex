/** Dev-server-backed snapshot store — see SPEC §8.10, §10 flow D. */

import type { Snapshot } from '../../types/snapshot.js';
import type { SnapshotStore } from './SnapshotManager.js';

/** The dev-server route a snapshot is persisted through (§10-D). */
export const SNAPSHOT_ENDPOINT = '/__pinscope/snapshot';

/** Raised when the dev-server rejects (or never receives) a snapshot POST. */
export class SnapshotPersistError extends Error {
  readonly status?: number;
  constructor(message: string, status?: number) {
    super(message);
    this.name = 'SnapshotPersistError';
    this.status = status;
  }
}

/**
 * A `SnapshotStore` that persists each snapshot by POSTing it to the PinScope
 * dev-server endpoint `/__pinscope/snapshot` (§10 flow D). The dev server
 * writes the file to `.pinscope/snapshots/` — the browser runtime stays free
 * of `node:fs`.
 *
 * `SnapshotStore.write` is synchronous, so the POST is fired and its promise
 * tracked; `flush()` awaits the in-flight write so callers (and tests) can
 * observe a failed persist instead of a silently swallowed one.
 */
export class EndpointSnapshotStore implements SnapshotStore {
  private readonly endpoint: string;
  private pending: Promise<void> = Promise.resolve();

  constructor(endpoint: string = SNAPSHOT_ENDPOINT) {
    this.endpoint = endpoint;
  }

  write(snapshot: Snapshot): void {
    this.pending = this.post(snapshot);
  }

  /** Await the most recent persist; rejects with `SnapshotPersistError`. */
  flush(): Promise<void> {
    return this.pending;
  }

  private async post(snapshot: Snapshot): Promise<void> {
    if (typeof fetch !== 'function') {
      throw new SnapshotPersistError(
        'snapshot persist failed: fetch is unavailable in this environment',
      );
    }
    let response: Response;
    try {
      response = await fetch(this.endpoint, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(snapshot),
      });
    } catch (cause) {
      throw new SnapshotPersistError(
        `snapshot persist failed: network error contacting ${this.endpoint}`,
      );
    }
    if (!response.ok) {
      throw new SnapshotPersistError(
        `snapshot persist failed: ${this.endpoint} returned ${response.status}`,
        response.status,
      );
    }
  }
}
