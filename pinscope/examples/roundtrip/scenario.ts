/**
 * APEX <-> PinScope round-trip scenario — see SPEC §17.6, AC-107.
 *
 * Demonstrates that a structured PinScope Operation resolves a UI change in a
 * single communication round: the Operation carries the exact pin, property
 * and value, so the executor can apply it with no clarifying question.
 *
 * A vague prose request ("make the button a bit less cramped") would need
 * several rounds; a PinScope Operation needs one.
 */

import { parseCommand } from '../../src/runtime/parsers/operation-parser.js';
import {
  buildOperation,
  type BuildContext,
} from '../../src/runtime/parsers/operation-builder.js';
import type { Operation } from '../../src/types/operation.js';

export interface RoundTripResult {
  operation: Operation;
  /** Communication rounds the change needed (1 = no clarification). */
  rounds: number;
  /** The concrete edit an executor derives from the Operation. */
  edit: string;
}

const DEMO_CONTEXT: BuildContext = {
  tag: 'button',
  selector: 'button.cta',
  rect: { x: 24, y: 320, w: 140, h: 38 },
  currentStyles: { 'padding-block': '6px' },
  viewport: '1440x900',
};

/**
 * Run the scenario: the user points at pin `e_47` and asks for more vertical
 * padding. Returns the Operation, the round count, and the derived edit.
 */
export function runScenario(
  command = 'e_47.padding-y → 12px',
): RoundTripResult {
  const parsed = parseCommand(command);
  const operation = buildOperation(parsed, DEMO_CONTEXT);

  // An Operation is "complete" when the executor needs nothing more to apply
  // it: a pin, a request type, and at least one concrete operation item.
  const item = operation.operations?.[0];
  const complete =
    operation.pin !== '' &&
    operation.request_type === 'operation' &&
    item !== undefined &&
    item.value !== undefined;

  const rounds = complete ? 1 : 2;
  const edit = item
    ? `${operation.context.selector} { ${item.property}: ${String(item.value)}; }`
    : '(no edit — clarification required)';

  return { operation, rounds, edit };
}
