/** Command history — see SPEC §9.4, §8.6. */

import type { Operation } from '../../types/operation.js';

export interface HistoryEntry {
  timestamp: string;
  raw_input: string;
  parsed: Operation | null;
  result: 'sent' | 'applied' | 'failed' | 'reverted';
  error?: string;
}

export interface HistoryData {
  version: '1.0';
  entries: HistoryEntry[];
}

/**
 * Persistence boundary — `runtime/` stays free of `node:fs`. The browser uses
 * a memory/dev-server store; tests inject a file-backed store.
 */
export interface HistoryStore {
  read(): HistoryData;
  write(data: HistoryData): void;
}

const MAX_ENTRIES = 1000;

export class HistoryManager {
  private readonly store: HistoryStore;

  constructor(store: HistoryStore) {
    this.store = store;
  }

  /** Append an entry, keeping at most the last 1000 (SPEC §8.6). */
  append(entry: HistoryEntry): void {
    const data = this.store.read();
    data.entries.push(entry);
    if (data.entries.length > MAX_ENTRIES) {
      data.entries = data.entries.slice(-MAX_ENTRIES);
    }
    this.store.write(data);
  }

  list(): HistoryEntry[] {
    return this.store.read().entries;
  }
}

/** Default in-memory store (browser runtime). */
export class MemoryHistoryStore implements HistoryStore {
  private data: HistoryData = { version: '1.0', entries: [] };

  read(): HistoryData {
    return { version: '1.0', entries: [...this.data.entries] };
  }

  write(data: HistoryData): void {
    this.data = { version: '1.0', entries: [...data.entries] };
  }
}
