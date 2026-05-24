import { describe, it, expect, afterEach, vi } from 'vitest';
import {
  createSnapshot,
  SnapshotManager,
  MemorySnapshotStore,
} from '../../../src/runtime/managers/SnapshotManager.js';
import { EndpointSnapshotStore } from '../../../src/runtime/managers/EndpointSnapshotStore.js';

afterEach(() => {
  document.body.innerHTML = '';
});

/** Structural validator for the §9.2 Snapshot schema. */
function isValidSnapshot(value: unknown): boolean {
  if (typeof value !== 'object' || value === null) return false;
  const s = value as Record<string, unknown>;
  if (s['version'] !== '1.0') return false;
  if (typeof s['id'] !== 'string' || typeof s['created'] !== 'string') return false;
  if (typeof s['url'] !== 'string' || typeof s['user_agent'] !== 'string') return false;
  if (typeof s['device_pixel_ratio'] !== 'number') return false;
  const vp = s['viewport'] as Record<string, unknown> | undefined;
  if (!vp || typeof vp['width'] !== 'number' || typeof vp['height'] !== 'number') {
    return false;
  }
  const summary = s['summary'] as Record<string, unknown> | undefined;
  if (!summary || typeof summary['total_elements'] !== 'number') return false;
  const elements = s['elements'];
  if (typeof elements !== 'object' || elements === null) return false;
  for (const el of Object.values(elements as Record<string, unknown>)) {
    const e = el as Record<string, unknown>;
    if (typeof e['tag'] !== 'string') return false;
    if (!Array.isArray(e['classes']) || !Array.isArray(e['children_pins'])) return false;
    if (typeof e['rect'] !== 'object' || e['rect'] === null) return false;
    if (typeof e['computed_styles'] !== 'object') return false;
    if (typeof e['visible'] !== 'boolean') return false;
  }
  return true;
}

describe('createSnapshot (AC-042)', () => {
  it('produces a §9.2-conformant snapshot', () => {
    document.body.innerHTML =
      '<section data-pin="e_1"><button data-pin="e_2">Go</button></section>';
    const snap = createSnapshot('test');
    expect(isValidSnapshot(JSON.parse(JSON.stringify(snap)))).toBe(true);
    expect(snap.summary.total_elements).toBe(2);
    expect(snap.elements['e_2']?.tag).toBe('button');
    expect(snap.elements['e_2']?.parent_pin).toBe('e_1');
    expect(snap.name).toBe('test');
  });

  it('records direct child pins in the hierarchy', () => {
    document.body.innerHTML =
      '<div data-pin="e_1"><span data-pin="e_2">a</span><span data-pin="e_3">b</span></div>';
    const snap = createSnapshot();
    expect(snap.elements['e_1']?.children_pins.sort()).toEqual(['e_2', 'e_3']);
  });

  it('SnapshotManager.capture persists through the store', () => {
    document.body.innerHTML = '<div data-pin="e_1">x</div>';
    const store = new MemorySnapshotStore();
    const snap = new SnapshotManager(store).capture('snap');
    expect(store.snapshots).toHaveLength(1);
    expect(store.snapshots[0]).toBe(snap);
  });
});

describe('EndpointSnapshotStore (R-15-06, §10-D)', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('POSTs the snapshot to /__pinscope/snapshot', async () => {
    document.body.innerHTML = '<div data-pin="e_1">x</div>';
    const fetchMock = vi.fn(() =>
      Promise.resolve({ ok: true, status: 200 } as Response),
    );
    vi.stubGlobal('fetch', fetchMock);

    const store = new EndpointSnapshotStore();
    const snap = new SnapshotManager(store).capture('x');
    // The store write is async — let the POST settle.
    await store.flush();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('/__pinscope/snapshot');
    expect(init.method).toBe('POST');
    const body = JSON.parse(init.body as string) as { id: string; version: string };
    expect(body.id).toBe(snap.id);
    expect(body.version).toBe('1.0');
  });

  it('surfaces a non-ok response as a typed error, never swallows it', async () => {
    document.body.innerHTML = '<div data-pin="e_1">x</div>';
    const fetchMock = vi.fn(() =>
      Promise.resolve({ ok: false, status: 500 } as Response),
    );
    vi.stubGlobal('fetch', fetchMock);

    const store = new EndpointSnapshotStore();
    new SnapshotManager(store).capture('x');
    await expect(store.flush()).rejects.toThrow(/snapshot/i);
  });
});

describe('snapshot performance (AC-075)', () => {
  it('captures 200 elements in under 500 ms', () => {
    const parts: string[] = [];
    for (let i = 0; i < 200; i++) {
      parts.push(`<div data-pin="e_${i}">item ${i}</div>`);
    }
    document.body.innerHTML = parts.join('');
    const start = performance.now();
    const snap = createSnapshot();
    expect(performance.now() - start).toBeLessThan(500);
    expect(snap.summary.total_elements).toBe(200);
  });
});
