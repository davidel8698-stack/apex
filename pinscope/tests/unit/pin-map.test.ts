import { describe, it, expect, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { PinMap } from '../../src/plugin/pin-map.js';

const tmpFiles: string[] = [];
function tmpPath(): string {
  const p = path.join(
    os.tmpdir(),
    `pinscope-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  tmpFiles.push(p);
  return p;
}

afterEach(() => {
  for (const f of tmpFiles.splice(0)) {
    if (fs.existsSync(f)) fs.rmSync(f);
  }
});

describe('PinMap', () => {
  it('assigns e_1, e_2, e_3 monotonically (AC-007)', () => {
    const m = new PinMap(tmpPath());
    expect(m.getOrAssign('a', 'div')).toBe('e_1');
    expect(m.getOrAssign('b', 'div')).toBe('e_2');
    expect(m.getOrAssign('c', 'div')).toBe('e_3');
  });

  it('returns the same id for a known key', () => {
    const m = new PinMap(tmpPath());
    const first = m.getOrAssign('k', 'div');
    expect(m.getOrAssign('k', 'span')).toBe(first);
  });

  it('never reuses ids across 100 distinct keys (AC-007)', () => {
    const m = new PinMap(tmpPath());
    const ids = new Set<string>();
    for (let i = 0; i < 100; i++) {
      ids.add(m.getOrAssign(`key-${i}`, 'div'));
    }
    expect(ids.size).toBe(100);
  });

  it('reconcile marks unseen entries deleted (AC-008)', () => {
    const m = new PinMap(tmpPath());
    m.getOrAssign('stays', 'div');
    m.getOrAssign('goes', 'div');
    m.reconcile(['stays']);
    const entries = m.snapshot().entries;
    expect(entries['stays']?.deleted).toBeUndefined();
    expect(entries['goes']?.deleted).toBe(true);
  });

  it('re-assigning a reconciled key clears the deleted flag', () => {
    const m = new PinMap(tmpPath());
    m.getOrAssign('x', 'div');
    m.reconcile([]);
    expect(m.snapshot().entries['x']?.deleted).toBe(true);
    m.getOrAssign('x', 'div');
    expect(m.snapshot().entries['x']?.deleted).toBeUndefined();
  });

  it('save writes JSON validating against the §9.1 schema (AC-006)', () => {
    const p = tmpPath();
    const m = new PinMap(p);
    m.getOrAssign('a', 'button');
    m.save();
    const raw = JSON.parse(fs.readFileSync(p, 'utf-8')) as Record<string, unknown>;
    expect(raw['version']).toBe(1);
    expect(typeof raw['next_id']).toBe('number');
    const entries = raw['entries'] as Record<string, Record<string, unknown>>;
    expect(entries['a']?.['id']).toBe('e_1');
    expect(entries['a']?.['tag']).toBe('button');
    expect(typeof entries['a']?.['created']).toBe('string');
    expect(typeof entries['a']?.['last_seen']).toBe('string');
  });

  it('load round-trips a saved map and continues the counter', () => {
    const p = tmpPath();
    const a = new PinMap(p);
    a.getOrAssign('a', 'div');
    a.getOrAssign('b', 'span');
    a.save();
    const b = new PinMap(p);
    b.load();
    expect(b.getOrAssign('a', 'div')).toBe('e_1');
    expect(b.getOrAssign('c', 'div')).toBe('e_3');
  });

  it('load on a missing file is a fresh start', () => {
    const m = new PinMap(tmpPath());
    m.load();
    expect(m.getOrAssign('a', 'div')).toBe('e_1');
  });

  it('load warns and continues on an unsupported version (does not throw)', () => {
    const p = tmpPath();
    fs.writeFileSync(p, JSON.stringify({ version: 2, next_id: 9, entries: {} }));
    const m = new PinMap(p);
    expect(() => m.load()).not.toThrow();
    expect(m.getOrAssign('a', 'div')).toBe('e_1');
  });
});
