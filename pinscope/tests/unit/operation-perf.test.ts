import { describe, it, expect } from 'vitest';
import { parseCommand } from '../../src/runtime/parsers/operation-parser.js';
import { getSuggestions } from '../../src/runtime/parsers/autocomplete.js';

describe('operation protocol performance', () => {
  it('parses a command in under 4 ms (AC-072)', () => {
    const cmd = 'e_47.padding-y → 12px';
    parseCommand(cmd); // warm
    const start = performance.now();
    const runs = 200;
    for (let i = 0; i < runs; i++) parseCommand(cmd);
    const avg = (performance.now() - start) / runs;
    expect(avg).toBeLessThan(4);
  });

  it('returns autocomplete suggestions in under 50 ms (AC-054)', () => {
    const pins = Array.from({ length: 500 }, (_, i) => `e_${i}`);
    const properties = [
      'padding', 'padding-block', 'margin', 'color', 'background-color',
      'border-radius', 'font-size', 'font-weight', 'box-shadow',
    ];
    getSuggestions('e_4', pins, properties); // warm
    const start = performance.now();
    const result = getSuggestions('e_4', pins, properties);
    expect(performance.now() - start).toBeLessThan(50);
    expect(result.length).toBeGreaterThan(0);
  });

  it('suggests properties after a dot', () => {
    const result = getSuggestions('e_1.pad', [], ['padding', 'padding-block', 'margin']);
    expect(result).toContain('padding');
    expect(result).toContain('padding-block');
    expect(result).not.toContain('margin');
  });
});
