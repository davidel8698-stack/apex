import { describe, it, expect } from 'vitest';
import { parseCommand } from '../../src/runtime/parsers/operation-parser.js';
import {
  buildOperation,
  OperationBuildError,
  type BuildContext,
} from '../../src/runtime/parsers/operation-builder.js';

const ctx: BuildContext = {
  tag: 'button',
  selector: 'button.cta',
  rect: { x: 10, y: 20, w: 120, h: 40 },
  currentStyles: { padding: '8px', color: 'rgb(0, 0, 0)' },
  childrenPins: ['e_2'],
  viewport: '1440x900',
};

/** Structural validator for the §9.3 Operation schema. */
function isValidOperation(value: unknown): boolean {
  if (typeof value !== 'object' || value === null) return false;
  const o = value as Record<string, unknown>;
  if (o['version'] !== '1.0') return false;
  if (typeof o['pin'] !== 'string') return false;
  if (!['operation', 'annotation', 'diagnostic'].includes(o['request_type'] as string)) {
    return false;
  }
  if (typeof o['current_styles'] !== 'object' || o['current_styles'] === null) return false;
  const ctxObj = o['context'];
  if (typeof ctxObj !== 'object' || ctxObj === null) return false;
  const c = ctxObj as Record<string, unknown>;
  if (typeof c['tag'] !== 'string' || typeof c['selector'] !== 'string') return false;
  if (!Array.isArray(c['children_pins'])) return false;
  if (typeof c['rect'] !== 'object' || c['rect'] === null) return false;
  const meta = o['meta'];
  if (typeof meta !== 'object' || meta === null) return false;
  if (o['operations'] !== undefined && !Array.isArray(o['operations'])) return false;
  return true;
}

const samples = [
  'e_1.padding → 12px',
  'e_1.padding-y → 10px',
  'e_1.bg → #ffffff',
  'e_1.color → red',
  'e_1.padding +→ 4px',
  'e_1.radius → 8px',
  'e_2 += active',
  'e_2 -= hidden',
  '? why is this slow',
  '?',
];

describe('buildOperation — §9.3 conformance (AC-052)', () => {
  it.each(samples)('produces a schema-valid Operation for "%s"', (input) => {
    const op = buildOperation(parseCommand(input), ctx);
    const roundTripped = JSON.parse(JSON.stringify(op)) as unknown;
    expect(isValidOperation(roundTripped)).toBe(true);
  });

  it('resolves shortcut properties in the operations list', () => {
    const op = buildOperation(parseCommand('e_1.padding-y → 10px'), ctx);
    expect(op.operations?.[0]?.property).toBe('padding-block');
    expect(op.operations?.[0]?.operation).toBe('set');
  });

  it('marks a query as a diagnostic request', () => {
    const op = buildOperation(parseCommand('? why slow'), ctx);
    expect(op.request_type).toBe('diagnostic');
    expect(op.annotation).toBe('why slow');
  });

  it('emits class operations for += / -=', () => {
    const op = buildOperation(parseCommand('e_2 += active'), ctx);
    expect(op.operations?.[0]?.operation).toBe('add-class');
    expect(op.operations?.[0]?.value).toBe('active');
  });

  it('rejects local-only commands (select / measure / snapshot)', () => {
    expect(() => buildOperation(parseCommand('select e_1'), ctx)).toThrow(
      OperationBuildError,
    );
    expect(() => buildOperation(parseCommand('measure e_1 to e_2'), ctx)).toThrow(
      OperationBuildError,
    );
  });
});
