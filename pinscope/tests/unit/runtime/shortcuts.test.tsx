import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import {
  matchShortcut,
  SHORTCUTS,
  useKeyboardShortcuts,
  type ShortcutId,
  type ShortcutHandlers,
  type KeyLike,
} from '../../../src/runtime/hooks/useKeyboardShortcuts.js';

afterEach(cleanup);

const ALL_IDS = Object.keys(SHORTCUTS) as ShortcutId[];

function eventFor(id: ShortcutId): KeyLike {
  const def = SHORTCUTS[id];
  return {
    key: def.key,
    shiftKey: def.shift ?? false,
    metaKey: false,
    ctrlKey: def.meta ?? false,
  };
}

describe('matchShortcut (AC-043)', () => {
  it.each(ALL_IDS)('resolves the %s shortcut', (id) => {
    expect(matchShortcut(eventFor(id))).toBe(id);
  });

  it('returns null for an unmapped key', () => {
    expect(
      matchShortcut({ key: 'z', shiftKey: false, metaKey: false, ctrlKey: false }),
    ).toBeNull();
  });

  // R-24-02 — kills useKeyboardShortcuts.ts:30-39 mutation survivors. The
  // it.each(ALL_IDS) test above reads `def.shift` from SHORTCUTS and
  // constructs the event with `shiftKey: def.shift` — a tautology
  // (definition tests itself). A mutation flipping any entry's `shift:
  // true → false` would also flip the event the test sends, leaving the
  // test passing. The table below holds HARDCODED expectations
  // independent of SHORTCUTS — a mutation to the table's shift flag is
  // caught by both the positive assertion (matches when shift correct)
  // AND the negative assertion (does NOT match when shift wrong).
  type Expected = {
    id: ShortcutId;
    key: string;
    shift: boolean;
    meta: boolean;
  };
  const EXPLICIT: Expected[] = [
    { id: 'grid-cycle', key: 'g', shift: true, meta: false },
    { id: 'grid-0', key: '0', shift: true, meta: false },
    { id: 'grid-1', key: '1', shift: true, meta: false },
    { id: 'grid-2', key: '2', shift: true, meta: false },
    { id: 'grid-3', key: '3', shift: true, meta: false },
    { id: 'grid-4', key: '4', shift: true, meta: false },
    { id: 'toggle-hud', key: 'h', shift: true, meta: false },
    { id: 'toggle-pins', key: 'p', shift: true, meta: false },
    { id: 'measure', key: 'm', shift: true, meta: false },
    { id: 'snapshot', key: 's', shift: true, meta: false },
    { id: 'crosshair', key: 'c', shift: true, meta: false },
  ];

  it.each(EXPLICIT)(
    'matches $id with explicit expectations (R-24-02)',
    ({ id, key, shift, meta }) => {
      // Positive: matches when modifiers are correct.
      expect(
        matchShortcut({
          key,
          shiftKey: shift,
          metaKey: false,
          ctrlKey: meta,
        }),
      ).toBe(id);
      // Negative: does NOT match when shift is wrong (kills shift-flip mutant).
      expect(
        matchShortcut({
          key,
          shiftKey: !shift,
          metaKey: false,
          ctrlKey: meta,
        }),
      ).not.toBe(id);
    },
  );
});

function Harness({ handlers }: { handlers: ShortcutHandlers }): null {
  useKeyboardShortcuts(handlers);
  return null;
}

describe('useKeyboardShortcuts (AC-043)', () => {
  it('dispatches at least 95% of the §8.11 shortcut table', () => {
    const fired = new Set<ShortcutId>();
    const handlers: ShortcutHandlers = {};
    for (const id of ALL_IDS) handlers[id] = () => fired.add(id);
    render(<Harness handlers={handlers} />);
    for (const id of ALL_IDS) {
      const def = SHORTCUTS[id];
      fireEvent.keyDown(document, {
        key: def.key,
        shiftKey: def.shift ?? false,
        ctrlKey: def.meta ?? false,
      });
    }
    expect(fired.size / ALL_IDS.length).toBeGreaterThanOrEqual(0.95);
  });
});
