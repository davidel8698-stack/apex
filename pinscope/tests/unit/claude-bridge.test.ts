import { describe, it, expect, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {
  HistoryManager,
  type HistoryStore,
  type HistoryData,
} from '../../src/runtime/managers/HistoryManager.js';
import {
  ClaudeBridge,
  type ClipboardLike,
} from '../../src/runtime/managers/ClaudeBridge.js';
import { parseCommand } from '../../src/runtime/parsers/operation-parser.js';
import {
  buildOperation,
  type BuildContext,
} from '../../src/runtime/parsers/operation-builder.js';

class FileHistoryStore implements HistoryStore {
  constructor(private readonly file: string) {}
  read(): HistoryData {
    if (!fs.existsSync(this.file)) return { version: '1.0', entries: [] };
    return JSON.parse(fs.readFileSync(this.file, 'utf-8')) as HistoryData;
  }
  write(data: HistoryData): void {
    fs.writeFileSync(this.file, JSON.stringify(data, null, 2));
  }
}

class MockClipboard implements ClipboardLike {
  text = '';
  async writeText(text: string): Promise<void> {
    this.text = text;
  }
}

const ctx: BuildContext = {
  tag: 'button',
  selector: 'button.cta',
  rect: { x: 0, y: 0, w: 100, h: 40 },
  currentStyles: { padding: '8px' },
  viewport: '1440x900',
};

const tmpFiles: string[] = [];
function tmpPath(): string {
  const p = path.join(
    os.tmpdir(),
    `pinscope-hist-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  tmpFiles.push(p);
  return p;
}
afterEach(() => {
  for (const f of tmpFiles.splice(0)) {
    if (fs.existsSync(f)) fs.rmSync(f);
  }
});

describe('ClaudeBridge.send (AC-053)', () => {
  it('copies the Operation JSON to the clipboard and appends history', async () => {
    const file = tmpPath();
    const history = new HistoryManager(new FileHistoryStore(file));
    const clipboard = new MockClipboard();
    const bridge = new ClaudeBridge(history, clipboard);

    const raw = 'e_1.padding → 12px';
    const op = buildOperation(parseCommand(raw), ctx);
    const json = await bridge.send(op, raw);

    expect(clipboard.text).toBe(json);
    expect((JSON.parse(clipboard.text) as { pin: string }).pin).toBe('e_1');

    expect(fs.existsSync(file)).toBe(true);
    const data = JSON.parse(fs.readFileSync(file, 'utf-8')) as HistoryData;
    expect(data.entries.length).toBe(1);
    expect(data.entries[0]?.result).toBe('sent');
    expect(data.entries[0]?.raw_input).toBe(raw);
  });

  it('caps history at the last 1000 entries', () => {
    const history = new HistoryManager(new FileHistoryStore(tmpPath()));
    for (let i = 0; i < 1010; i++) {
      history.append({
        timestamp: new Date().toISOString(),
        raw_input: `cmd ${i}`,
        parsed: null,
        result: 'sent',
      });
    }
    const entries = history.list();
    expect(entries.length).toBe(1000);
    expect(entries[entries.length - 1]?.raw_input).toBe('cmd 1009');
  });
});
