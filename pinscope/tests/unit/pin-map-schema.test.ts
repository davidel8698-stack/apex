/**
 * R-25-01 — AC-006 strengthen: `.pinmap.json` schema validation.
 *
 * The existing happy-path schema test in `pin-map.test.ts` (line 65) only
 * proves that `PinMap.save()` produces a valid file. It says nothing about
 * how the system reacts to an INVALID file. R25 strengthens AC-006 by adding
 * explicit rejection cases against a §9.1 schema validator: missing required
 * fields and wrong field types must both be detected and reported.
 *
 * The validator below is intentionally hand-rolled (~25 lines, no `ajv`
 * dependency) — the schema has 5 fields total, and a tiny purpose-built
 * validator is easier to audit than a library config.
 */

import { describe, it, expect, afterEach } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { PinMap } from '../../src/plugin/pin-map.js';

const tmpFiles: string[] = [];
function tmpPath(): string {
  const p = path.join(
    os.tmpdir(),
    `pinscope-schema-${Date.now()}-${Math.random().toString(36).slice(2)}.json`,
  );
  tmpFiles.push(p);
  return p;
}

afterEach(() => {
  for (const f of tmpFiles.splice(0)) {
    if (fs.existsSync(f)) fs.rmSync(f);
  }
});

/**
 * Validate a parsed object against the SPEC §9.1 PinMap schema.
 * Returns `{ ok: true }` or `{ ok: false, error: string }`.
 *
 * Schema (SPEC §9.1):
 *   {
 *     version: 1,
 *     next_id: number,
 *     entries: Record<string, {
 *       id: string,           // `e_N`
 *       tag: string,
 *       created: string,      // ISO-8601
 *       last_seen: string,    // ISO-8601
 *       deleted?: true        // optional, soft-delete flag
 *     }>
 *   }
 */
function validatePinMapSchema(raw: unknown): { ok: true } | { ok: false; error: string } {
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
    return { ok: false, error: 'root must be a non-null object' };
  }
  const r = raw as Record<string, unknown>;
  if (r['version'] !== 1) {
    return { ok: false, error: `version must be 1, got ${JSON.stringify(r['version'])}` };
  }
  if (typeof r['next_id'] !== 'number' || !Number.isFinite(r['next_id']) || r['next_id'] < 1) {
    return {
      ok: false,
      error: `next_id must be a positive number, got ${JSON.stringify(r['next_id'])}`,
    };
  }
  if (!r['entries'] || typeof r['entries'] !== 'object' || Array.isArray(r['entries'])) {
    return { ok: false, error: 'entries must be a non-null object' };
  }
  const entries = r['entries'] as Record<string, unknown>;
  for (const [key, val] of Object.entries(entries)) {
    if (!val || typeof val !== 'object' || Array.isArray(val)) {
      return { ok: false, error: `entries.${key} must be an object` };
    }
    const e = val as Record<string, unknown>;
    if (typeof e['id'] !== 'string' || !/^e_\d+$/.test(e['id'])) {
      return {
        ok: false,
        error: `entries.${key}.id must match /^e_\\d+$/, got ${JSON.stringify(e['id'])}`,
      };
    }
    if (typeof e['tag'] !== 'string') {
      return { ok: false, error: `entries.${key}.tag must be a string` };
    }
    if (typeof e['created'] !== 'string') {
      return { ok: false, error: `entries.${key}.created must be a string` };
    }
    if (typeof e['last_seen'] !== 'string') {
      return { ok: false, error: `entries.${key}.last_seen must be a string` };
    }
    if (e['deleted'] !== undefined && e['deleted'] !== true) {
      return {
        ok: false,
        error: `entries.${key}.deleted must be undefined or true, got ${JSON.stringify(e['deleted'])}`,
      };
    }
  }
  return { ok: true };
}

describe('PinMap schema validation (AC-006)', () => {
  it('AC-006 — valid PinMap roundtrips through JSON and passes the schema', () => {
    const p = tmpPath();
    const m = new PinMap(p);
    m.getOrAssign('src/Button.tsx:10:5', 'button');
    m.getOrAssign('src/Input.tsx:22:7', 'input');
    m.save();

    const raw = JSON.parse(fs.readFileSync(p, 'utf-8'));
    const result = validatePinMapSchema(raw);
    expect(result.ok).toBe(true);

    const reloaded = new PinMap(p);
    reloaded.load();
    expect(reloaded.getOrAssign('src/Button.tsx:10:5', 'button')).toBe('e_1');
    expect(reloaded.getOrAssign('src/Input.tsx:22:7', 'input')).toBe('e_2');
  });

  it('AC-006 — missing required `version` field is rejected with a clear error', () => {
    const invalid = { next_id: 3, entries: {} };
    const result = validatePinMapSchema(invalid);
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toMatch(/version must be 1/);
    }

    const missingNextId = { version: 1, entries: {} };
    const r2 = validatePinMapSchema(missingNextId);
    expect(r2.ok).toBe(false);
    if (!r2.ok) {
      expect(r2.error).toMatch(/next_id/);
    }

    const missingEntries = { version: 1, next_id: 1 };
    const r3 = validatePinMapSchema(missingEntries);
    expect(r3.ok).toBe(false);
    if (!r3.ok) {
      expect(r3.error).toMatch(/entries/);
    }
  });

  it('AC-006 — wrong field types are rejected with a clear error', () => {
    const wrongNextId = { version: 1, next_id: 'string', entries: {} };
    const r1 = validatePinMapSchema(wrongNextId);
    expect(r1.ok).toBe(false);
    if (!r1.ok) {
      expect(r1.error).toMatch(/next_id must be a positive number/);
    }

    const wrongVersion = { version: 2, next_id: 1, entries: {} };
    const r2 = validatePinMapSchema(wrongVersion);
    expect(r2.ok).toBe(false);
    if (!r2.ok) {
      expect(r2.error).toMatch(/version must be 1/);
    }

    const wrongIdShape = {
      version: 1,
      next_id: 2,
      entries: {
        key1: {
          id: 'not-e-format',
          tag: 'div',
          created: '2026-01-01T00:00:00Z',
          last_seen: '2026-01-01T00:00:00Z',
        },
      },
    };
    const r3 = validatePinMapSchema(wrongIdShape);
    expect(r3.ok).toBe(false);
    if (!r3.ok) {
      expect(r3.error).toMatch(/id must match/);
    }

    const wrongDeleted = {
      version: 1,
      next_id: 2,
      entries: {
        key1: {
          id: 'e_1',
          tag: 'div',
          created: '2026-01-01T00:00:00Z',
          last_seen: '2026-01-01T00:00:00Z',
          deleted: 'yes',
        },
      },
    };
    const r4 = validatePinMapSchema(wrongDeleted);
    expect(r4.ok).toBe(false);
    if (!r4.ok) {
      expect(r4.error).toMatch(/deleted/);
    }
  });
});
