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
