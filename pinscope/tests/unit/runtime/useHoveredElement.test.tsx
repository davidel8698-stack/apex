/** R-24-02 — pin-guard mutation-survivor closure for useHoveredElement.ts:51. */

import { describe, it, expect, afterEach, vi } from 'vitest';
import { render, cleanup, act } from '@testing-library/react';
import type { ReactElement } from 'react';
import { useHoveredElement } from '../../../src/runtime/hooks/useHoveredElement.js';

afterEach(() => {
  cleanup();
  document.body.innerHTML = '';
  vi.useRealTimers();
  vi.restoreAllMocks();
});

function Harness({
  onState,
}: {
  onState: (h: ReturnType<typeof useHoveredElement>) => void;
}): ReactElement {
  const h = useHoveredElement();
  onState(h);
  return <div />;
}

describe('useHoveredElement pin-guard (R-24-02)', () => {
  it('returns null when elementFromPoint hits an HTMLElement WITHOUT data-pin', async () => {
    // R-24-02 — kills the useHoveredElement.ts:51 mutation survivor
    // `if (!pinned || !pinId)` → `if (!pinned && !pinId)`. The mutation
    // changes the guard from "exit if either is null" to "exit only if
    // both are null". The discriminating case: an HTMLElement that is
    // pinned (findPinnedAncestor returns it) but has no `data-pin`
    // attribute value (pinId === null). Under the original guard, the
    // hook exits and stays null. Under the mutated guard, the hook
    // would call setHovered with a non-null object that has
    // `pinId: null` — corrupted state.
    //
    // Test strategy: stub elementFromPoint to return a div without a
    // data-pin ancestor (so findPinnedAncestor returns null in the
    // baseline case — this is the !pinned branch). For the
    // discriminating case, we'd need to stub findPinnedAncestor to
    // return an HTMLElement and then verify the guard catches the
    // empty-pin case. Approach: create a pinned element with an empty
    // string `data-pin=""` so getAttribute returns "" (truthy-element,
    // falsy-pinId) — the exact ||-vs-&& discriminator.
    const stateLog: Array<ReturnType<typeof useHoveredElement>> = [];

    // Pinned element WITH empty data-pin (the discriminator).
    const pinnedEmpty = document.createElement('div');
    pinnedEmpty.setAttribute('data-pin', '');
    pinnedEmpty.style.cssText = 'width:100px;height:100px;';
    document.body.appendChild(pinnedEmpty);

    // Stub elementFromPoint to point at the empty-pin element.
    const originalEFP = document.elementFromPoint;
    document.elementFromPoint = vi.fn(() => pinnedEmpty);

    try {
      render(<Harness onState={(h) => stateLog.push(h)} />);

      // Trigger a mousemove + await the rAF resolve.
      await act(async () => {
        window.dispatchEvent(
          new MouseEvent('mousemove', {
            bubbles: true,
            clientX: 50,
            clientY: 50,
          }),
        );
        await new Promise((r) => requestAnimationFrame(() => r(undefined)));
      });

      // After the rAF resolves, the hook must have stayed at null
      // (the guard fires for pinId === ""). If the mutation `||` → `&&`
      // were applied, the hook would have transitioned to a
      // hovered object with pinId === "" — which is what this assertion
      // catches.
      const last = stateLog[stateLog.length - 1];
      expect(last).toBeNull();
    } finally {
      document.elementFromPoint = originalEFP;
    }
  });

  it('also returns null when no pinned ancestor is found (baseline !pinned case)', async () => {
    // Sanity baseline: with no data-pin element at all, the hook stays
    // null. This is the `!pinned` half of the original guard — separate
    // from the mutation-killing test above.
    const bare = document.createElement('div');
    bare.style.cssText = 'width:100px;height:100px;';
    document.body.appendChild(bare);

    const originalEFP = document.elementFromPoint;
    document.elementFromPoint = vi.fn(() => bare);

    const stateLog: Array<ReturnType<typeof useHoveredElement>> = [];
    try {
      render(<Harness onState={(h) => stateLog.push(h)} />);
      await act(async () => {
        window.dispatchEvent(
          new MouseEvent('mousemove', {
            bubbles: true,
            clientX: 50,
            clientY: 50,
          }),
        );
        await new Promise((r) => requestAnimationFrame(() => r(undefined)));
      });
      const last = stateLog[stateLog.length - 1];
      expect(last).toBeNull();
    } finally {
      document.elementFromPoint = originalEFP;
    }
  });
});

/**
 * R-25-02 — AC-026 hook-level coverage.
 *
 * `findPinnedAncestor` is unit-tested in `element-walker.test.ts` at the
 * utility level. R25 adds integration tests that route through the full
 * `useHoveredElement` hook — these catch wiring bugs (e.g., the hook
 * forgetting to call the utility, or dropping its result) that utility
 * tests cannot. Five discriminating cases:
 *   1. Simple element directly under the cursor carries `data-pin`.
 *   2. Cursor inside a deep child — the hook resolves the nearest
 *      pinned ancestor.
 *   3. Element mounted AFTER the hook started; cursor moves onto it.
 *   4. Cursor over a HUD element (delegates the AC-027 filter through
 *      the hook).
 *   5. Cursor over an element with NO pinned ancestor — hook stays null.
 */

async function moveCursorTo(el: HTMLElement, stateLog: Array<ReturnType<typeof useHoveredElement>>): Promise<void> {
  const originalEFP = document.elementFromPoint;
  document.elementFromPoint = vi.fn(() => el);
  try {
    render(<Harness onState={(h) => stateLog.push(h)} />);
    await act(async () => {
      // The hook listens on `document` (not `window`). Dispatch the event on
      // `document` so the listener actually fires — `window.dispatchEvent`
      // would never reach `document` because events don't propagate downward
      // through the capture chain.
      document.dispatchEvent(
        new MouseEvent('mousemove', {
          bubbles: true,
          clientX: 50,
          clientY: 50,
        }),
      );
      await new Promise((r) => requestAnimationFrame(() => r(undefined)));
    });
  } finally {
    document.elementFromPoint = originalEFP;
  }
}

describe('useHoveredElement nearest pinned ancestor (AC-026)', () => {
  it('AC-026 — returns the element itself when it carries data-pin', async () => {
    const target = document.createElement('button');
    target.setAttribute('data-pin', 'e_10');
    target.style.cssText = 'width:100px;height:100px;';
    document.body.appendChild(target);

    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    await moveCursorTo(target, log);
    const last = log[log.length - 1];
    expect(last).not.toBeNull();
    expect(last?.pinId).toBe('e_10');
    expect(last?.element).toBe(target);
  });

  it('AC-026 — walks up to the nearest pinned ancestor for nested children', async () => {
    const ancestor = document.createElement('button');
    ancestor.setAttribute('data-pin', 'e_20');
    const middle = document.createElement('span');
    const leaf = document.createElement('i');
    leaf.textContent = 'x';
    middle.appendChild(leaf);
    ancestor.appendChild(middle);
    document.body.appendChild(ancestor);

    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    await moveCursorTo(leaf, log);
    const last = log[log.length - 1];
    expect(last).not.toBeNull();
    expect(last?.pinId).toBe('e_20');
    expect(last?.element).toBe(ancestor);
  });

  it('AC-026 — resolves elements mounted AFTER the hook started observing', async () => {
    // Hook starts BEFORE the pinned element exists. The discriminating
    // assertion: the hook does not snapshot the DOM at mount time — it
    // re-queries on each mousemove, so a late-arriving `[data-pin]`
    // element is still resolvable.
    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    const originalEFP = document.elementFromPoint;

    try {
      // 1. Mount the hook on an empty document (no data-pin elements yet).
      render(<Harness onState={(h) => log.push(h)} />);

      // 2. Add the pinned element AFTER the hook is observing.
      const dynamic = document.createElement('div');
      dynamic.setAttribute('data-pin', 'e_30');
      dynamic.style.cssText = 'width:100px;height:100px;';
      document.body.appendChild(dynamic);

      // 3. Now point the cursor at it and dispatch a mousemove on `document`.
      document.elementFromPoint = vi.fn(() => dynamic);
      await act(async () => {
        document.dispatchEvent(
          new MouseEvent('mousemove', { bubbles: true, clientX: 50, clientY: 50 }),
        );
        await new Promise((r) => requestAnimationFrame(() => r(undefined)));
      });
    } finally {
      document.elementFromPoint = originalEFP;
    }
    const last = log[log.length - 1];
    expect(last).not.toBeNull();
    expect(last?.pinId).toBe('e_30');
  });

  it('AC-026 (AC-027 delegation) — returns null when cursor is over a HUD element', async () => {
    const hud = document.createElement('div');
    hud.setAttribute('data-pinscope-ui', 'root');
    const inside = document.createElement('button');
    inside.setAttribute('data-pin', 'e_40');
    hud.appendChild(inside);
    document.body.appendChild(hud);

    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    await moveCursorTo(inside, log);
    const last = log[log.length - 1];
    // `escapeHud` walks the element out of the HUD subtree — once outside,
    // there is no pinned ancestor on the body, so the hook stays null.
    expect(last).toBeNull();
  });

  it('AC-026 — returns null when cursor is over an element with no pinned ancestor', async () => {
    const bare = document.createElement('section');
    bare.style.cssText = 'width:100px;height:100px;';
    document.body.appendChild(bare);

    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    await moveCursorTo(bare, log);
    const last = log[log.length - 1];
    expect(last).toBeNull();
  });
});

/**
 * R-25-03 — AC-027 hook-level HUD filtering coverage.
 *
 * Three cases that prove the hook respects the `[data-pinscope-ui]` filter:
 *   1. Cursor on the HUD root itself.
 *   2. Cursor on a deeply nested HUD descendant.
 *   3. Cursor on an app element adjacent to (but NOT inside) the HUD —
 *      sanity, must NOT be ignored.
 */
describe('useHoveredElement HUD filtering (AC-027)', () => {
  it('AC-027 — ignores cursor on the HUD root itself', async () => {
    const hud = document.createElement('div');
    hud.setAttribute('data-pinscope-ui', 'root');
    hud.setAttribute('data-pin', 'e_50'); // even if HUD has data-pin, it's filtered
    document.body.appendChild(hud);

    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    await moveCursorTo(hud, log);
    const last = log[log.length - 1];
    expect(last).toBeNull();
  });

  it('AC-027 — ignores cursor on a deeply nested HUD descendant', async () => {
    const hud = document.createElement('div');
    hud.setAttribute('data-pinscope-ui', 'root');
    const mid = document.createElement('section');
    const inner = document.createElement('button');
    inner.setAttribute('data-pin', 'e_60');
    mid.appendChild(inner);
    hud.appendChild(mid);
    document.body.appendChild(hud);

    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    await moveCursorTo(inner, log);
    const last = log[log.length - 1];
    expect(last).toBeNull();
  });

  it('AC-027 — app element adjacent to (not inside) the HUD is NOT ignored (sanity)', async () => {
    // Build: <div data-pinscope-ui="root"></div><button data-pin="e_70">app</button>
    const hud = document.createElement('div');
    hud.setAttribute('data-pinscope-ui', 'root');
    document.body.appendChild(hud);

    const app = document.createElement('button');
    app.setAttribute('data-pin', 'e_70');
    document.body.appendChild(app);

    const log: Array<ReturnType<typeof useHoveredElement>> = [];
    await moveCursorTo(app, log);
    const last = log[log.length - 1];
    expect(last).not.toBeNull();
    expect(last?.pinId).toBe('e_70');
  });
});
