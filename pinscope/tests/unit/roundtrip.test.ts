import { describe, it, expect } from 'vitest';
import { runScenario } from '../../examples/roundtrip/scenario.js';

describe('APEX round-trip scenario (AC-107)', () => {
  it('resolves a UI change in at most 2 communication rounds', () => {
    const result = runScenario('e_47.padding-y → 12px');
    expect(result.rounds).toBeLessThanOrEqual(2);
    expect(result.rounds).toBe(1);
  });

  it('derives a concrete, unambiguous edit from the Operation', () => {
    const result = runScenario('e_47.bg → #ffffff');
    expect(result.operation.pin).toBe('e_47');
    expect(result.edit).toContain('background-color');
    expect(result.edit).toContain('#ffffff');
  });
});
