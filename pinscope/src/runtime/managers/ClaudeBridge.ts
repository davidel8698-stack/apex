/** Claude bridge — clipboard + history for a sent Operation (flow C). */

import type { Operation } from '../../types/operation.js';
import type { HistoryManager } from './HistoryManager.js';

/** Minimal clipboard surface — injectable for tests. */
export interface ClipboardLike {
  writeText(text: string): Promise<void>;
}

function defaultClipboard(): ClipboardLike | undefined {
  if (typeof navigator !== 'undefined' && navigator.clipboard) {
    return navigator.clipboard;
  }
  return undefined;
}

export class ClaudeBridge {
  private readonly history: HistoryManager;
  private readonly clipboard: ClipboardLike | undefined;

  constructor(history: HistoryManager, clipboard?: ClipboardLike) {
    this.history = history;
    this.clipboard = clipboard ?? defaultClipboard();
  }

  /**
   * Copy the Operation JSON to the clipboard and record it in history.
   * Returns the JSON string that was sent.
   */
  async send(operation: Operation, rawInput: string): Promise<string> {
    const json = JSON.stringify(operation, null, 2);
    try {
      if (this.clipboard) await this.clipboard.writeText(json);
      this.history.append({
        timestamp: new Date().toISOString(),
        raw_input: rawInput,
        parsed: operation,
        result: 'sent',
      });
      return json;
    } catch (err) {
      this.history.append({
        timestamp: new Date().toISOString(),
        raw_input: rawInput,
        parsed: operation,
        result: 'failed',
        error: err instanceof Error ? err.message : String(err),
      });
      throw err;
    }
  }
}
