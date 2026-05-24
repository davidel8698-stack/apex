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
});
