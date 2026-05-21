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
