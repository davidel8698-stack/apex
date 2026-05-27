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

/**
 * R-25-06 — AC-007 strengthen: monotonic ID assignment invariants.
 *
 * The two pre-existing AC-007 tests above prove the happy-path counter and
 * the no-collision invariant across 100 keys. R25 explicitly covers the
 * three invariants the SPEC §6.1 stable-id-generator promises:
 *   (1) same input key reuses the same ID,
 *   (2) a new key gets the next sequential ID,
 *   (3) deletion is a soft delete — an ID is NEVER reused.
 *
 * The third case is the load-bearing one: it kills any implementation that
 * frees a deleted slot on reconcile().
 */
describe('PinMap monotonicity invariants (AC-007)', () => {
  it('AC-007 — same key reuses the same ID across getOrAssign calls', () => {
    const m = new PinMap(tmpPath());
    const first = m.getOrAssign('repeat-key', 'div');
    expect(m.getOrAssign('repeat-key', 'span')).toBe(first);
    expect(m.getOrAssign('repeat-key', 'div')).toBe(first);
  });

  it('AC-007 — new key gets the next sequential ID (no gaps)', () => {
    const m = new PinMap(tmpPath());
    expect(m.getOrAssign('a', 'div')).toBe('e_1');
    expect(m.getOrAssign('b', 'div')).toBe('e_2');
    expect(m.getOrAssign('c', 'div')).toBe('e_3');
    expect(m.getOrAssign('d', 'div')).toBe('e_4');
  });

  it('AC-007 — deletion is soft; an ID is NEVER reused after reconcile', () => {
    const m = new PinMap(tmpPath());
    const aId = m.getOrAssign('a', 'div'); // e_1
    const bId = m.getOrAssign('b', 'div'); // e_2
    expect(aId).toBe('e_1');
    expect(bId).toBe('e_2');

    // Reconcile with only 'b' alive — 'a' is soft-deleted.
    m.reconcile(['b']);
    expect(m.snapshot().entries['a']?.deleted).toBe(true);

    // A brand-new key MUST get e_3, NOT e_1 (the freed slot).
    const cId = m.getOrAssign('c', 'div');
    expect(cId).toBe('e_3');
    expect(cId).not.toBe(aId);

    // And another brand-new key gets e_4.
    expect(m.getOrAssign('d', 'div')).toBe('e_4');
  });
});
