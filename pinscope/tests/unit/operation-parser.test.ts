import { describe, it, expect } from 'vitest';
import {
  parseCommand,
  OperationParseError,
  type ParsedCommand,
} from '../../src/runtime/parsers/operation-parser.js';

const valid: Array<{ input: string; kind: ParsedCommand['kind'] }> = [
  { input: 'e_1.padding → 12px', kind: 'operation' },
  { input: 'e_47.color → red', kind: 'operation' },
  { input: 'e_2.padding -> 8px', kind: 'operation' },
  { input: 'e_3.padding +→ 4px', kind: 'operation' },
  { input: 'e_3.padding -→ 4px', kind: 'operation' },
  { input: 'e_3.padding +-> 4px', kind: 'operation' },
  { input: 'e_3.padding --> 4px', kind: 'operation' },
  { input: 'e_5.font-size → 16px', kind: 'operation' },
  { input: 'e_5.padding-y → 10px', kind: 'operation' },
  { input: 'e_7.bg → #fff', kind: 'operation' },
  { input: 'e_7 . padding → 1rem', kind: 'operation' },
  { input: '  e_8.margin → 0  ', kind: 'operation' },
  { input: 'e_100.radius → 8px', kind: 'operation' },
  { input: 'e_0.opacity → 0.5', kind: 'operation' },
  { input: 'e_9 += active', kind: 'class' },
  { input: 'e_9 -= hidden', kind: 'class' },
  { input: 'e_9 += is-open', kind: 'class' },
  { input: 'select e_12', kind: 'select' },
  { input: 'SELECT e_5', kind: 'select' },
  { input: 'measure e_1 to e_2', kind: 'measure' },
  { input: 'MEASURE e_10 TO e_20', kind: 'measure' },
  { input: 'snapshot', kind: 'snapshot' },
  { input: 'snapshot Homepage', kind: 'snapshot' },
  { input: 'snapshot Hero Section', kind: 'snapshot' },
  { input: 'SNAPSHOT test', kind: 'snapshot' },
  { input: '?', kind: 'query' },
  { input: '? why is this slow', kind: 'query' },
];

const invalid: string[] = [
  '',
  '   ',
  'e_47.padding',
  'e_47 padding → 12px',
  'foo.bar → 1',
  'e_47.padding ~> 12px',
  'select',
  'select e_1 e_2',
  'measure e_1 e_2',
  'e_47 = active',
  'random text',
  'e_.padding → 1px',
];

describe('operation parser — grammar coverage (AC-050, AC-081)', () => {
  it('exercises at least 30 input cases', () => {
    expect(valid.length + invalid.length).toBeGreaterThanOrEqual(30);
  });

  it.each(valid)('parses "$input" as $kind', ({ input, kind }) => {
    expect(parseCommand(input).kind).toBe(kind);
  });

  it.each(invalid)('rejects "%s" with a typed error', (input) => {
    expect(() => parseCommand(input)).toThrow(OperationParseError);
  });
});

describe('operation parser — field extraction', () => {
  it('extracts pin, property, operator and value for a set', () => {
    const cmd = parseCommand('e_1.padding → 12px');
    expect(cmd).toEqual({
      kind: 'operation',
      pin: 'e_1',
      property: 'padding',
      op: 'set',
      value: '12px',
    });
  });

  it('maps +→ to increment and -→ to decrement', () => {
    expect(parseCommand('e_3.padding +→ 4px')).toMatchObject({ op: 'increment' });
    expect(parseCommand('e_3.padding -→ 4px')).toMatchObject({ op: 'decrement' });
  });

  it('maps += to add-class and -= to remove-class', () => {
    expect(parseCommand('e_9 += active')).toMatchObject({
      kind: 'class',
      op: 'add-class',
      className: 'active',
    });
    expect(parseCommand('e_9 -= active')).toMatchObject({ op: 'remove-class' });
  });

  it('extracts measure endpoints and snapshot/query topics', () => {
    expect(parseCommand('measure e_1 to e_2')).toMatchObject({ from: 'e_1', to: 'e_2' });
    expect(parseCommand('snapshot Homepage')).toMatchObject({ name: 'Homepage' });
    expect(parseCommand('? why slow')).toMatchObject({ topic: 'why slow' });
    expect(parseCommand('snapshot')).toEqual({ kind: 'snapshot' });
  });

  it('throws OperationParseError carrying the original input', () => {
    try {
      parseCommand('nonsense');
      expect.unreachable('should have thrown');
    } catch (err) {
      expect(err).toBeInstanceOf(OperationParseError);
      expect((err as OperationParseError).input).toBe('nonsense');
    }
  });
});
