/** Operation command parser — see SPEC §11. */

import type { OperationKind } from '../../types/operation.js';

export type ParsedCommand =
  | {
      kind: 'operation';
      pin: string;
      property: string;
      op: OperationKind;
      value: string;
    }
  | {
      kind: 'class';
      pin: string;
      op: 'add-class' | 'remove-class';
      className: string;
    }
  | { kind: 'select'; pin: string }
  | { kind: 'measure'; from: string; to: string }
  | { kind: 'snapshot'; name?: string }
  | { kind: 'query'; topic?: string };

/** Typed error for malformed command input. */
export class OperationParseError extends Error {
  readonly input: string;
  constructor(message: string, input: string) {
    super(message);
    this.name = 'OperationParseError';
    this.input = input;
  }
}

const OPERATORS: Record<string, OperationKind> = {
  '→': 'set',
  '->': 'set',
  '+→': 'increment',
  '+->': 'increment',
  '-→': 'decrement',
  '-->': 'decrement',
};

const RE_QUERY = /^\?\s*(.*)$/;
const RE_SNAPSHOT = /^snapshot(?:\s+(.+))?$/i;
const RE_MEASURE = /^measure\s+(e_\d+)\s+to\s+(e_\d+)$/i;
const RE_SELECT = /^select\s+(e_\d+)$/i;
const RE_OPERATION =
  /^(e_\d+)\s*\.\s*([a-zA-Z][a-zA-Z0-9]*(?:-[a-zA-Z0-9]+)*)\s*(\+->|\+→|-->|-→|->|→)\s*(.+)$/;
const RE_CLASS = /^(e_\d+)\s*(\+=|-=)\s*([\w-]+)$/;

/**
 * Parse a CommandBar input string into a `ParsedCommand`.
 * Throws `OperationParseError` on malformed input.
 */
export function parseCommand(input: string): ParsedCommand {
  const text = input.trim();
  if (text === '') {
    throw new OperationParseError('Empty command', input);
  }

  const query = RE_QUERY.exec(text);
  if (query) {
    const topic = query[1]?.trim();
    return topic ? { kind: 'query', topic } : { kind: 'query' };
  }

  const snapshot = RE_SNAPSHOT.exec(text);
  if (snapshot) {
    const name = snapshot[1]?.trim();
    return name ? { kind: 'snapshot', name } : { kind: 'snapshot' };
  }

  const measure = RE_MEASURE.exec(text);
  if (measure) {
    return {
      kind: 'measure',
      from: measure[1] as string,
      to: measure[2] as string,
    };
  }

  const select = RE_SELECT.exec(text);
  if (select) {
    return { kind: 'select', pin: select[1] as string };
  }

  const operation = RE_OPERATION.exec(text);
  if (operation) {
    const op = OPERATORS[operation[3] as string];
    if (!op) {
      throw new OperationParseError(
        `Unknown operator: ${String(operation[3])}`,
        input,
      );
    }
    return {
      kind: 'operation',
      pin: operation[1] as string,
      property: operation[2] as string,
      op,
      value: (operation[4] as string).trim(),
    };
  }

  const cls = RE_CLASS.exec(text);
  if (cls) {
    return {
      kind: 'class',
      pin: cls[1] as string,
      op: cls[2] === '+=' ? 'add-class' : 'remove-class',
      className: cls[3] as string,
    };
  }

  throw new OperationParseError(`Unrecognised command: "${text}"`, input);
}
