import { describe, it, expect } from 'vitest';
import { parseCommand } from '../../src/runtime/parsers/operation-parser.js';
import {
  buildOperation,
  OperationBuildError,
  type BuildContext,
} from '../../src/runtime/parsers/operation-builder.js';
import type { Operation } from '../../src/types/operation.js';

/**
 * Behavioral test for AC-107 (R-15-11).
 *
 * SPEC §1 / §17.6: a structured PinScope Operation resolves a UI change in
 * <= 2 communication rounds (target: 1, no clarification). The previous
 * version of this test imported `runScenario` from the bundled round-trip
 * demo script and asserted `result.rounds === 1` — a value the demo script
 * itself computes. That is self-fulfilling: it verifies the example emits the
 * number the example was written to emit, not that the framework's
 * `parseCommand` -> `buildOperation` path *guarantees* a 1-round resolution.
 *
 * This test instead exercises the production primitives directly and OWNS the
 * completeness logic. An Operation is "1-round complete" — an executor needs
 * no clarifying round — when it has a non-empty `pin`, `request_type ===
 * 'operation'`, and an `operations[0]` carrying a concrete `value` or `delta`.
 * The negative case feeds an under-specified command and proves the
 * assertion can fail (a genuine red/green dual, not another self-fulfilling
 * test).
 */

const CTX: BuildContext = {
  tag: 'button',
  selector: 'button.cta',
  rect: { x: 24, y: 320, w: 140, h: 38 },
  currentStyles: { 'padding-block': '6px' },
  viewport: '1440x900',
};

/**
 * Communication rounds an Operation needs. 1 = directly applicable with no
 * clarification; 2 = the executor must ask a clarifying question. The
 * completeness predicate is derived here from the §9.3 Operation shape — it
 * is NOT imported from the demo. `value !== undefined || delta !== undefined`
 * (R-15-09 routes increment/decrement magnitudes to `delta`).
 */
function communicationRounds(op: Operation): number {
  const item = op.operations?.[0];
  const complete =
    op.pin !== '' &&
    op.request_type === 'operation' &&
    item !== undefined &&
    (item.value !== undefined || item.delta !== undefined);
  return complete ? 1 : 2;
}

describe('APEX round-trip via production primitives (AC-107)', () => {
  it('resolves a concrete operation command in a single communication round', () => {
    const parsed = parseCommand('e_47.padding-y → 12px');
    const op = buildOperation(parsed, CTX);

    // Re-derive completeness from the Operation the framework produced.
    expect(op.pin).toBe('e_47');
    expect(op.request_type).toBe('operation');
    expect(op.operations).toBeDefined();
    expect(op.operations).toHaveLength(1);
    const item = op.operations?.[0];
    expect(item?.value ?? item?.delta).toBeDefined();

    expect(communicationRounds(op)).toBe(1);
    expect(communicationRounds(op)).toBeLessThanOrEqual(2);
  });

  it('resolves an increment command in one round (delta-carrying operation)', () => {
    const parsed = parseCommand('e_47.padding +-> 4');
    const op = buildOperation(parsed, CTX);

    const item = op.operations?.[0];
    expect(item?.delta).toBe(4);
    expect(communicationRounds(op)).toBe(1);
  });

  it('does NOT resolve an under-specified query in one round', () => {
    // A bare `? layout` query carries no concrete operation item — it is a
    // diagnostic request, so an executor cannot apply an edit without a
    // follow-up round. This is the negative case proving the 1-round
    // assertion can fail.
    const parsed = parseCommand('? layout');
    const op = buildOperation(parsed, CTX);

    expect(op.request_type).not.toBe('operation');
    expect(op.operations).toBeUndefined();
    expect(communicationRounds(op)).toBe(2);
    expect(communicationRounds(op)).not.toBe(1);
  });

  it('treats a local-only select command as not 1-round resolvable', () => {
    // `select` is a local action, not a Claude payload — `buildOperation`
    // rejects it outright. A command that cannot even produce an Operation
    // is, by definition, not a 1-round resolution.
    const parsed = parseCommand('select e_47');
    expect(() => buildOperation(parsed, CTX)).toThrow(OperationBuildError);
  });
});
