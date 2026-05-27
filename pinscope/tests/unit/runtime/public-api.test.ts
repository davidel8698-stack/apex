import { describe, it, expect } from 'vitest';
import * as api from '../../../src/index.js';

describe('public API surface (AC-091)', () => {
  it('exports the plugin and runtime entry points', () => {
    expect(typeof api.pinscope).toBe('function');
    expect(typeof api.PinScope).toBe('function');
    expect(typeof api.useDevState).toBe('function');
  });

  it('re-exports withPinScope from the package root (SPEC §15)', () => {
    expect(typeof api.withPinScope).toBe('function');
  });

  it('R25 strict (AC-091) — exports exactly the documented surface; no accidental private leakage', () => {
    // R25 W7 strict bump: AC-091 min_tests 1→4. The fourth case codifies
    // the SPEC §15 public-API set as a complete inventory — kills any
    // mutant that accidentally adds a private symbol to the package root
    // (e.g. by re-exporting a manager class meant to stay internal).
    const documentedSurface = new Set([
      'pinscope',
      'PinScope',
      'useDevState',
      'withPinScope',
      'default', // ES module reflection includes the default export wrapper
    ]);
    const actual = new Set(Object.keys(api));
    // Every documented symbol is present.
    for (const name of documentedSurface) {
      if (name === 'default') continue; // ESM-only artifact, not always present
      expect(actual.has(name)).toBe(true);
    }
    // No undocumented public exports — any accidental new symbol surfaces here.
    for (const name of actual) {
      if (!documentedSurface.has(name)) {
        throw new Error(
          `AC-091 — undocumented public export "${name}" found on package root`,
        );
      }
    }
  });
});
