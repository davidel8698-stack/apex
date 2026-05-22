/** Operation builder — `ParsedCommand` -> §9.3 `Operation`. */

import type { Operation, OperationItem } from '../../types/operation.js';
import type { ParsedCommand } from './operation-parser.js';
import { resolveProperty } from './property-shortcuts.js';

export interface BuildContext {
  tag: string;
  selector: string;
  rect: { x: number; y: number; w: number; h: number };
  currentStyles: Record<string, string>;
  textContent?: string;
  parentPin?: string;
  childrenPins?: string[];
  viewport: string;
}

/** Raised when a local-only command is handed to `buildOperation`. */
export class OperationBuildError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'OperationBuildError';
  }
}

/**
 * Turn an operation / class / query command into a §9.3 `Operation`.
 * `select` / `measure` / `snapshot` are local actions, not Claude payloads —
 * passing them throws `OperationBuildError`.
 */
export function buildOperation(
  parsed: ParsedCommand,
  context: BuildContext,
): Operation {
  const operation: Operation = {
    version: '1.0',
    pin: pinOf(parsed),
    context: {
      tag: context.tag,
      selector: context.selector,
      text_content: context.textContent,
      rect: {
        x: context.rect.x,
        y: context.rect.y,
        w: context.rect.w,
        h: context.rect.h,
      },
      parent_pin: context.parentPin,
      children_pins: context.childrenPins ?? [],
    },
    current_styles: context.currentStyles,
    request_type: 'operation',
    meta: {
      viewport: context.viewport,
      timestamp: new Date().toISOString(),
    },
  };

  if (parsed.kind === 'operation') {
    const item: OperationItem = {
      property: resolveProperty(parsed.property),
      operation: parsed.op,
    };
    if (parsed.op === 'increment' || parsed.op === 'decrement') {
      // §9.3 — increment/decrement magnitudes belong in `delta` (a number),
      // not `value`. A magnitude that is not a bare number (e.g. `4px`,
      // `1em`) falls back to `value` so the payload is never lossy and
      // `delta` is never NaN.
      const magnitude = numericMagnitude(parsed.value);
      if (magnitude !== null) {
        item.delta = magnitude;
      } else {
        item.value = parsed.value;
      }
    } else {
      item.value = parsed.value;
    }
    operation.operations = [item];
    return operation;
  }

  if (parsed.kind === 'class') {
    const item: OperationItem = {
      property: 'class',
      operation: parsed.op,
      value: parsed.className,
    };
    operation.operations = [item];
    return operation;
  }

  if (parsed.kind === 'query') {
    operation.request_type = 'diagnostic';
    if (parsed.topic !== undefined) operation.annotation = parsed.topic;
    return operation;
  }

  throw new OperationBuildError(
    `Command kind "${parsed.kind}" is a local action, not a Claude operation`,
  );
}

/**
 * Parse an increment/decrement magnitude string to a bare number.
 * Returns `null` for any value that is not a finite plain number (e.g.
 * `4px`, `1em`, `auto`) so the caller can fall back to `value` and never
 * emits a `NaN` `delta` (SPEC §9.3).
 */
function numericMagnitude(raw: string): number | null {
  const trimmed = raw.trim();
  if (trimmed === '') return null;
  // Reject anything carrying a unit/suffix — only a bare number is a delta.
  if (!/^[+-]?(?:\d+\.?\d*|\.\d+)$/.test(trimmed)) return null;
  const n = Number(trimmed);
  return Number.isFinite(n) ? n : null;
}

function pinOf(parsed: ParsedCommand): string {
  switch (parsed.kind) {
    case 'operation':
    case 'class':
    case 'select':
      return parsed.pin;
    case 'measure':
      return parsed.from;
    default:
      return '';
  }
}
