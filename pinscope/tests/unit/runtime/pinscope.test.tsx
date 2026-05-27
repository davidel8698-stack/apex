import { describe, it, expect, afterEach, vi } from 'vitest';
import { act, render, cleanup } from '@testing-library/react';
import { PinScope } from '../../../src/runtime/PinScope.js';

afterEach(() => {
  cleanup();
  vi.unstubAllEnvs();
  document.body.innerHTML = '';
});

describe('PinScope root', () => {
  it('renders null under NODE_ENV=production (AC-020)', () => {
    vi.stubEnv('NODE_ENV', 'production');
    const { container } = render(<PinScope />);
    expect(container.innerHTML).toBe('');
    expect(document.querySelector('[data-pinscope-ui="root"]')).toBeNull();
  });

  it('renders null when enabled is false (AC-021)', () => {
    const { container } = render(<PinScope enabled={false} />);
    expect(container.innerHTML).toBe('');
    expect(document.querySelector('[data-pinscope-ui="root"]')).toBeNull();
  });

  it('portals the HUD into document.body (AC-022)', () => {
    render(<PinScope />);
    const hud = document.querySelector('[data-pinscope-ui="root"]');
    expect(hud).not.toBeNull();
    expect(hud?.parentElement).toBe(document.body);
  });
});

// R-20-01 DoD — VoidBadges mounted into the visible-HUD tree
describe('R-20-01 — VoidBadges mount', () => {
  it('mounts VoidBadges inside the visible HUD root for void [data-pin] elements', () => {
    const img = document.createElement('img');
    img.setAttribute('data-pin', 'e_9');
    document.body.appendChild(img);

    render(<PinScope />);
    const hud = document.querySelector('[data-pinscope-ui="root"]');
    expect(hud).not.toBeNull();
    // VoidBadges portal exists inside the visible-HUD tree
    const voidBadgesRoot = hud?.querySelector('[data-pinscope-void-badges]');
    expect(voidBadgesRoot).not.toBeNull();
    // The void element gets a JS-overlay badge keyed by pin id
    const badge = hud?.querySelector('[data-void-badge="e_9"]');
    expect(badge).not.toBeNull();
  });
});

/**
 * R-25-13 — AC-024 integration coverage: multi-tag overlay correctness
 * through the live `<PinScope/>` mount.
 *
 * The isolation test in `overlays.test.tsx:199` proves `<VoidBadges/>` in
 * isolation; the existing R-20-01 above proves a single-img pre-mount
 * case. This integration case strengthens the AC by covering MULTIPLE
 * VOID_TAGS (img + input + hr) in the same mount AND asserting the badge
 * count matches the pinned-void-element count — kills any tag-filter
 * narrowing mutation in `VOID_TAGS` (e.g. only `IMG` survives).
 *
 * DEFERRED to FIX-wave (NEW FINDING NF-25-01 candidate): post-mount void
 * element discovery — `VoidBadges` uses `useEffect(..., [])` and does not
 * re-collect on observer events. RuntimePinObserver assigns `e_r{N}` to
 * post-mount void elements correctly, but the overlay never appears for
 * them. Not addressed in R25 (production fix, not a test-rigor sweep).
 */
describe('R-25-13 / AC-024 — VoidBadges integration with <PinScope/> for multiple void tags', () => {
  it('AC-024 — three different void-tag elements with data-pin each get one [data-void-badge] overlay', () => {
    // Three different void tags from VOID_TAGS — kills mutants that narrow
    // the set (e.g., remove INPUT or HR) by failing the count assertion.
    const img = document.createElement('img');
    img.setAttribute('data-pin', 'e_v1');
    const input = document.createElement('input');
    input.setAttribute('data-pin', 'e_v2');
    const hr = document.createElement('hr');
    hr.setAttribute('data-pin', 'e_v3');
    document.body.append(img, input, hr);

    render(<PinScope />);
    const hud = document.querySelector('[data-pinscope-ui="root"]');
    expect(hud).not.toBeNull();

    // One overlay node per pinned void element — exact count, not "≥1".
    const badges = hud?.querySelectorAll('[data-void-badge]') ?? [];
    expect(badges.length).toBe(3);

    // Each pin id appears exactly once in the overlay set — kills any
    // de-duplication or key-collision mutation.
    const badgeIds = new Set(
      Array.from(badges).map((b) => b.getAttribute('data-void-badge')),
    );
    expect(badgeIds).toEqual(new Set(['e_v1', 'e_v2', 'e_v3']));

    // None of the badge ids match a non-void tag — the set-equality assert
    // above already proves no extras, and the count=3 assert already kills
    // any "treat all [data-pin] as void" mutation in VoidBadges.collect.
  });

  it('AC-024 — a non-void tag (<div data-pin>) does NOT receive an overlay even when colocated with void tags (sanity)', () => {
    const img = document.createElement('img');
    img.setAttribute('data-pin', 'e_v9');
    const div = document.createElement('div');
    div.setAttribute('data-pin', 'e_keep');
    document.body.append(img, div);

    render(<PinScope />);
    const hud = document.querySelector('[data-pinscope-ui="root"]');
    expect(hud).not.toBeNull();

    // The void <img> gets a badge.
    expect(hud?.querySelector('[data-void-badge="e_v9"]')).not.toBeNull();
    // The non-void <div> does NOT get a badge — kills any mutation that
    // drops the VOID_TAGS filter in `VoidBadges.collect`.
    expect(hud?.querySelector('[data-void-badge="e_keep"]')).toBeNull();
  });
});

/**
 * R-25-14 — AC-025 integration coverage: nested subtree assignment through
 * the live `<PinScope/>` mount + RuntimePinObserver pipeline.
 *
 * The isolation test in `edge-cases.test.ts:12-41` proves the observer in
 * isolation; the existing R-20-02 below proves a single-element post-mount
 * case. This new integration case covers a NESTED subtree: the observer
 * must walk into the inserted subtree and assign e_r{N} ids to multiple
 * levels, not just the root insertion node. Catches any walk-only-shallow
 * regression in the observer's mutation handler.
 */
describe('R-25-14 / AC-025 — RuntimePinObserver assigns nested-subtree e_r ids', () => {
  it('AC-025 — a nested subtree inserted after mount has e_r{N} assigned to every level', async () => {
    const { unmount } = render(<PinScope />);

    // Let the observer become live.
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    // Build a 3-level subtree completely off-DOM, then insert the root.
    const grandparent = document.createElement('section');
    const parent = document.createElement('div');
    const child = document.createElement('button');
    parent.appendChild(child);
    grandparent.appendChild(parent);
    document.body.appendChild(grandparent);

    // Allow the MutationObserver to deliver + the observer to walk.
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    expect(grandparent.getAttribute('data-pin')).toMatch(/^e_r\d+$/);
    expect(parent.getAttribute('data-pin')).toMatch(/^e_r\d+$/);
    expect(child.getAttribute('data-pin')).toMatch(/^e_r\d+$/);

    // The three assigned ids are distinct — no aliasing within a single
    // mutation batch (kills any "reuse last id" mutation in the observer).
    const ids = new Set([
      grandparent.getAttribute('data-pin'),
      parent.getAttribute('data-pin'),
      child.getAttribute('data-pin'),
    ]);
    expect(ids.size).toBe(3);

    unmount();
  });
});

// R-20-02 DoD — RuntimePinObserver lifecycle
describe('R-20-02 — RuntimePinObserver lifecycle', () => {
  it('assigns e_r{N} runtime ids to elements added after mount, and disconnects on unmount', async () => {
    const { unmount } = render(<PinScope />);

    // The observer is deferred via queueMicrotask (perf: keeps mount path
    // under AC-070 50ms). Await the microtask queue + the macrotask queue
    // so the observer is live before we add the test element.
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    // Append a fresh element without data-pin AFTER the observer is live
    const fresh = document.createElement('span');
    document.body.appendChild(fresh);

    // Flush MutationObserver delivery (it batches via microtask)
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    const pinAfterMount = fresh.getAttribute('data-pin');
    expect(pinAfterMount).toMatch(/^e_r\d+$/);

    // Unmount → observer must disconnect; subsequent appends are NOT assigned
    unmount();

    const afterUnmount = document.createElement('span');
    document.body.appendChild(afterUnmount);
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });
    expect(afterUnmount.getAttribute('data-pin')).toBeNull();
  });
});

// R-20-03 DoD — Shift+P / Shift+C toggles via real <PinScope/>
describe('R-20-03 — §8.11 Shift+P / Shift+C toggles', () => {
  function dispatchShortcut(key: string): void {
    document.dispatchEvent(
      new KeyboardEvent('keydown', {
        key,
        shiftKey: true,
        bubbles: true,
        cancelable: true,
      }),
    );
  }

  it('Shift+P toggles the pin badge layers (CSS + JS overlay)', async () => {
    // Seed a void [data-pin] so both layers have content
    const img = document.createElement('img');
    img.setAttribute('data-pin', 'e_42');
    document.body.appendChild(img);

    render(<PinScope />);
    const hud = document.querySelector('[data-pinscope-ui="root"]');
    expect(hud).not.toBeNull();

    // Initial: both layers visible
    expect(hud?.querySelector('[data-pinscope-badges]')).not.toBeNull();
    expect(hud?.querySelector('[data-pinscope-void-badges]')).not.toBeNull();

    // Shift+P → both layers hidden
    await act(async () => {
      dispatchShortcut('P');
    });
    expect(hud?.querySelector('[data-pinscope-badges]')).toBeNull();
    expect(hud?.querySelector('[data-pinscope-void-badges]')).toBeNull();

    // Shift+P again → both layers returned
    await act(async () => {
      dispatchShortcut('P');
    });
    expect(hud?.querySelector('[data-pinscope-badges]')).not.toBeNull();
    expect(hud?.querySelector('[data-pinscope-void-badges]')).not.toBeNull();
  });

  it('Shift+C toggles the crosshair', async () => {
    render(<PinScope />);
    const hud = document.querySelector('[data-pinscope-ui="root"]');

    // Move the mouse so the crosshair has a position to render
    await act(async () => {
      document.dispatchEvent(
        new MouseEvent('mousemove', { clientX: 100, clientY: 100 }),
      );
    });
    expect(hud?.querySelector('[data-pinscope-crosshair]')).not.toBeNull();

    // Shift+C → crosshair gone
    await act(async () => {
      dispatchShortcut('C');
    });
    expect(hud?.querySelector('[data-pinscope-crosshair]')).toBeNull();

    // Shift+C again → returns (requires another mouse-move to repopulate pos)
    await act(async () => {
      dispatchShortcut('C');
      document.dispatchEvent(
        new MouseEvent('mousemove', { clientX: 150, clientY: 150 }),
      );
    });
    expect(hud?.querySelector('[data-pinscope-crosshair]')).not.toBeNull();
  });
});

// R-21-02 DoD — Shadow-DOM marking + InfoPanel limited-inspection report
describe('R-21-02 — Shadow-DOM marking + InfoPanel limited-inspection report', () => {
  it('PinScopeHud marks Shadow-DOM hosts on mount, re-sweeps on MutationObserver tick, and disconnects on unmount', async () => {
    // Seed a Shadow-DOM host BEFORE render so the initial sweep can mark it.
    const host1 = document.createElement('div');
    host1.attachShadow({ mode: 'open' });
    document.body.appendChild(host1);

    const { unmount } = render(<PinScope />);

    // Flush the microtask queue so the queueMicrotask-deferred effect (if any)
    // and the synchronous mount sweep both settle.
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    // Initial sweep marked the first host
    expect(host1.getAttribute('data-pin-shadow')).toBe('');

    // Append a SECOND shadow host post-mount → MutationObserver re-sweep marks it
    const host2 = document.createElement('div');
    host2.attachShadow({ mode: 'open' });
    document.body.appendChild(host2);

    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    expect(host2.getAttribute('data-pin-shadow')).toBe('');

    // Unmount → observer disconnects; subsequent shadow-host appends are NOT marked
    unmount();

    const host3 = document.createElement('div');
    host3.attachShadow({ mode: 'open' });
    document.body.appendChild(host3);

    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    expect(host3.getAttribute('data-pin-shadow')).toBeNull();
  });

  it('InfoPanel reports limited inspection over a shadow host, absent over a non-shadow pin', async () => {
    // Pre-mount: seed a shadow host AND a non-shadow pin, both pinned.
    const shadowHost = document.createElement('div');
    shadowHost.setAttribute('data-pin', 'e_shadow');
    shadowHost.attachShadow({ mode: 'open' });
    // Give the host non-zero rect so elementFromPoint can land on it
    shadowHost.style.cssText = 'position:fixed; left:10px; top:10px; width:50px; height:50px;';
    document.body.appendChild(shadowHost);

    const plainHost = document.createElement('div');
    plainHost.setAttribute('data-pin', 'e_plain');
    plainHost.style.cssText = 'position:fixed; left:200px; top:10px; width:50px; height:50px;';
    document.body.appendChild(plainHost);

    render(<PinScope />);

    // Allow initial sweep to land + observer to settle
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    // Sanity: initial sweep marked the shadow host but not the plain one
    expect(shadowHost.getAttribute('data-pin-shadow')).toBe('');
    expect(plainHost.hasAttribute('data-pin-shadow')).toBe(false);

    const hud = document.querySelector('[data-pinscope-ui="root"]');
    expect(hud).not.toBeNull();

    // Stub elementFromPoint to land on the shadow host. The hover hook
    // throttles via rAF, so dispatch then flush.
    const originalEFP = document.elementFromPoint.bind(document);
    document.elementFromPoint = ((x: number, _y: number) => {
      if (x < 100) return shadowHost;
      return plainHost;
    }) as typeof document.elementFromPoint;

    try {
      // Hover the shadow host (x=20 routes to shadowHost via the stub)
      await act(async () => {
        document.dispatchEvent(
          new MouseEvent('mousemove', { clientX: 20, clientY: 20, bubbles: true }),
        );
        // Flush rAF + state updates
        await new Promise((r) => setTimeout(r, 0));
        await new Promise((r) => setTimeout(r, 16));
      });

      expect(
        hud!.querySelector('[data-pinscope-shadow-limited]'),
      ).not.toBeNull();

      // Hover the non-shadow pin (x=220 routes to plainHost via the stub)
      await act(async () => {
        document.dispatchEvent(
          new MouseEvent('mousemove', { clientX: 220, clientY: 20, bubbles: true }),
        );
        await new Promise((r) => setTimeout(r, 0));
        await new Promise((r) => setTimeout(r, 16));
      });

      expect(
        hud!.querySelector('[data-pinscope-shadow-limited]'),
      ).toBeNull();
    } finally {
      document.elementFromPoint = originalEFP;
    }
  });
});

// R-21-03 DoD — heavy-page degrade (30fps throttle + skip-small-badge)
describe('R-21-03 — heavy-page degrade', () => {
  it('> 500 pins switches hover to ≥ 30 Hz throttle; < 500 stays on rAF', async () => {
    // Helper — count document.elementFromPoint invocations as a proxy for
    // resolution-body invocations (each resolution calls it exactly once).
    // Returns a tuple [resolutionCount, restore].
    function instrument(): { count: () => number; restore: () => void } {
      const original = document.elementFromPoint.bind(document);
      let calls = 0;
      document.elementFromPoint = ((_x: number, _y: number) => {
        calls += 1;
        // Always return null so the hook short-circuits without touching state.
        return null;
      }) as typeof document.elementFromPoint;
      return {
        count: () => calls,
        restore: () => {
          document.elementFromPoint = original;
        },
      };
    }

    // --- Case A: HEAVY page (600 pins) → ≤ 6 resolutions over 150 ms ---
    for (let i = 0; i < 600; i++) {
      const el = document.createElement('div');
      el.setAttribute('data-pin', `e_h${i}`);
      document.body.appendChild(el);
    }

    vi.useFakeTimers();
    try {
      render(<PinScope />);

      const probeA = instrument();
      try {
        // Dispatch 30 mousemoves at 5 ms intervals (150 ms total span).
        for (let i = 0; i < 30; i++) {
          await act(async () => {
            document.dispatchEvent(
              new MouseEvent('mousemove', {
                clientX: 10 + i,
                clientY: 10 + i,
                bubbles: true,
              }),
            );
            vi.advanceTimersByTime(5);
          });
        }
        // Flush any trailing throttled call still pending.
        await act(async () => {
          vi.advanceTimersByTime(40);
        });

        const heavyCount = probeA.count();
        // 30fps throttle = one call per HEAVY_PAGE_INTERVAL_MS (33 ms).
        // Over the 150 ms span + 40 ms flush we expect ≤ 6 resolutions
        // (1 leading + ~5 trailing windows). A 60 Hz rAF path would
        // produce ~9–10 resolutions, so this gate fails red if the
        // heavy-page branch is not wired.
        expect(heavyCount).toBeGreaterThan(0);
        expect(heavyCount).toBeLessThanOrEqual(6);
      } finally {
        probeA.restore();
      }
    } finally {
      vi.useRealTimers();
      cleanup();
      document.body.innerHTML = '';
    }

    // --- Case B: LIGHT page (100 pins) → > 6 resolutions (rAF path) ---
    for (let i = 0; i < 100; i++) {
      const el = document.createElement('div');
      el.setAttribute('data-pin', `e_l${i}`);
      document.body.appendChild(el);
    }

    vi.useFakeTimers();
    try {
      render(<PinScope />);

      const probeB = instrument();
      try {
        for (let i = 0; i < 30; i++) {
          await act(async () => {
            document.dispatchEvent(
              new MouseEvent('mousemove', {
                clientX: 10 + i,
                clientY: 10 + i,
                bubbles: true,
              }),
            );
            vi.advanceTimersByTime(5);
          });
        }
        // Drain any pending rAF callbacks.
        await act(async () => {
          vi.advanceTimersByTime(40);
        });

        const lightCount = probeB.count();
        // Light path runs through requestAnimationFrame (~60 Hz) — over
        // 150 ms it resolves ~9–10 times, comfortably > 6.
        expect(lightCount).toBeGreaterThan(6);
      } finally {
        probeB.restore();
      }
    } finally {
      vi.useRealTimers();
    }
  });

  it('< 16×16 badges are hidden on a heavy page (skip-small-badge sweep)', async () => {
    // 600 pins on the page → heavy-page branch is active.
    // Make 5 of them inline-sized 8×8 (below MIN_BADGE_SIZE = 16) and
    // tag them so we can find them after the sweep.
    for (let i = 0; i < 600; i++) {
      const el = document.createElement('div');
      el.setAttribute('data-pin', `e_b${i}`);
      if (i < 5) {
        el.setAttribute('data-test-small', String(i));
        el.style.cssText =
          'position:fixed; left:0; top:0; width:8px; height:8px;';
        // Force the rect lookup to return an 8×8 rect even under happy-dom
        // (which often returns zeros for elements not in an actual layout).
        (el as HTMLElement).getBoundingClientRect = () =>
          ({ x: 0, y: 0, width: 8, height: 8, top: 0, bottom: 8, left: 0, right: 8, toJSON: () => ({}) }) as DOMRect;
      } else if (i < 10) {
        el.setAttribute('data-test-large', String(i));
        el.style.cssText =
          'position:fixed; left:0; top:0; width:100px; height:100px;';
        (el as HTMLElement).getBoundingClientRect = () =>
          ({ x: 0, y: 0, width: 100, height: 100, top: 0, bottom: 100, left: 0, right: 100, toJSON: () => ({}) }) as DOMRect;
      } else {
        // Remaining pins also get a non-zero rect so they are NOT mis-stamped.
        (el as HTMLElement).getBoundingClientRect = () =>
          ({ x: 0, y: 0, width: 32, height: 32, top: 0, bottom: 32, left: 0, right: 32, toJSON: () => ({}) }) as DOMRect;
      }
      document.body.appendChild(el);
    }

    render(<PinScope />);

    // Let the initial sweep + MutationObserver settle.
    await act(async () => {
      await new Promise((r) => setTimeout(r, 0));
    });

    // Every <16×16 pin carries the skip marker.
    for (let i = 0; i < 5; i++) {
      const small = document.querySelector(`[data-test-small="${i}"]`);
      expect(small).not.toBeNull();
      expect(small!.getAttribute('data-pin-skipbadge')).toBe('');
    }

    // Normal-sized siblings do NOT carry the marker.
    for (let i = 5; i < 10; i++) {
      const large = document.querySelector(`[data-test-large="${i}"]`);
      expect(large).not.toBeNull();
      expect(large!.hasAttribute('data-pin-skipbadge')).toBe(false);
    }

    // The complementary <style> block is injected into the HUD.
    const styleBlock = document.querySelector(
      'style[data-pinscope-skip-badge]',
    );
    expect(styleBlock).not.toBeNull();
  });
});

// R-21-01 DoD — touch tap/long-press + responsive HUD collapse (< 768px)
describe('R-21-01 — touch + responsive collapse', () => {
  /**
   * Helper — dispatch a TouchEvent with one Touch whose clientX/clientY land
   * on the given target. happy-dom supports `TouchEvent` + `Touch` natively.
   * The PinScope touch listener registers on `document`, so events are
   * dispatched on `document` (not on the target itself) to mirror real
   * mobile-Safari event delivery.
   */
  function dispatchTouch(
    type: 'touchstart' | 'touchend',
    target: Element,
    clientX: number,
    clientY: number,
  ): void {
    const touch = new Touch({
      identifier: 0,
      target,
      clientX,
      clientY,
      pageX: clientX,
      pageY: clientY,
      screenX: clientX,
      screenY: clientY,
    });
    const event = new TouchEvent(type, {
      bubbles: true,
      cancelable: true,
      touches: type === 'touchend' ? [] : [touch],
      targetTouches: type === 'touchend' ? [] : [touch],
      changedTouches: [touch],
    });
    document.dispatchEvent(event);
  }

  it('tap (touchstart→touchend < 500ms) selects a pinned element', async () => {
    // Seed a pinned host element with a known rect.
    const pinned = document.createElement('div');
    pinned.setAttribute('data-pin', 'e_7');
    pinned.style.cssText =
      'position:fixed; left:50px; top:50px; width:80px; height:80px;';
    document.body.appendChild(pinned);

    // Stub elementFromPoint so jsdom/happy-dom returns the pinned element
    // when the touch coordinates land inside its rect.
    const originalEFP = document.elementFromPoint.bind(document);
    document.elementFromPoint = ((x: number, y: number) => {
      if (x >= 50 && x <= 130 && y >= 50 && y <= 130) return pinned;
      return null;
    }) as typeof document.elementFromPoint;

    try {
      render(<PinScope />);

      // Tap = touchstart then touchend < 500 ms later at the same coords.
      await act(async () => {
        dispatchTouch('touchstart', pinned, 70, 70);
        // ~50 ms dwell — well under LONG_PRESS_MS (500).
        await new Promise((r) => setTimeout(r, 50));
        dispatchTouch('touchend', pinned, 70, 70);
        // Flush any pending state update from the listener.
        await new Promise((r) => setTimeout(r, 0));
      });

      // The pinned element carries data-pin-selected, proving the tap routed
      // through SelectionManager.select(pinId).
      const sel = document.querySelector('[data-pin-selected]');
      expect(sel).toBe(pinned);
    } finally {
      document.elementFromPoint = originalEFP;
    }
  });

  it('long-press (touchend ≥ 500ms after touchstart) locks the selection', async () => {
    // Seed a pinned host element with a known rect.
    const pinned = document.createElement('div');
    pinned.setAttribute('data-pin', 'e_8');
    pinned.style.cssText =
      'position:fixed; left:50px; top:50px; width:80px; height:80px;';
    document.body.appendChild(pinned);

    const originalEFP = document.elementFromPoint.bind(document);
    document.elementFromPoint = ((x: number, y: number) => {
      if (x >= 50 && x <= 130 && y >= 50 && y <= 130) return pinned;
      return null;
    }) as typeof document.elementFromPoint;

    vi.useFakeTimers();
    try {
      render(<PinScope />);

      // Long-press = touchend ≥ LONG_PRESS_MS (500) after touchstart.
      await act(async () => {
        dispatchTouch('touchstart', pinned, 70, 70);
      });
      await act(async () => {
        // Advance well past the 500 ms threshold so the gesture is a long-press.
        vi.advanceTimersByTime(600);
      });
      await act(async () => {
        dispatchTouch('touchend', pinned, 70, 70);
      });

      // After long-press, the element is selected (locked by SelectionManager.
      // select, which is the same primitive the tap branch uses — locked=true
      // is the default).
      expect(document.querySelector('[data-pin-selected]')).toBe(pinned);

      // Regression guard: a subsequent mouseleave must NOT clear the selection
      // (locked selection survives mouse-out per §8.1).
      await act(async () => {
        pinned.dispatchEvent(
          new MouseEvent('mouseleave', { bubbles: true }),
        );
        // Let any handlers settle.
        vi.advanceTimersByTime(50);
      });

      expect(document.querySelector('[data-pin-selected]')).toBe(pinned);
    } finally {
      vi.useRealTimers();
      document.elementFromPoint = originalEFP;
    }
  });

  it('compact viewport (innerWidth < 768) collapses HUD; restoring width re-expands it', async () => {
    // Capture original width so the test restores it.
    const originalWidth = window.innerWidth;
    // Start in compact mode BEFORE render so the initial useViewportSize read
    // is compact (otherwise the first render is the desktop tree).
    Object.defineProperty(window, 'innerWidth', {
      configurable: true,
      writable: true,
      value: 600,
    });

    try {
      render(<PinScope />);

      // Fire resize so any post-mount useViewportSize listener picks up the
      // compact value (covers either eager-read or listener-only paths).
      await act(async () => {
        window.dispatchEvent(new Event('resize'));
        await new Promise((r) => setTimeout(r, 0));
      });

      const hud = document.querySelector('[data-pinscope-ui="root"]');
      expect(hud).not.toBeNull();

      // Visible-HUD subtree is absent in compact mode — no PinBadges layer.
      expect(hud!.querySelector('[data-pinscope-badges]')).toBeNull();
      // The FloatingToggle is exposed so the user can re-expand the HUD.
      expect(hud!.querySelector('[data-pinscope-toggle]')).not.toBeNull();

      // Restore to a desktop width and dispatch resize → HUD re-expands.
      Object.defineProperty(window, 'innerWidth', {
        configurable: true,
        writable: true,
        value: 1280,
      });
      await act(async () => {
        window.dispatchEvent(new Event('resize'));
        await new Promise((r) => setTimeout(r, 0));
      });

      expect(hud!.querySelector('[data-pinscope-badges]')).not.toBeNull();
    } finally {
      Object.defineProperty(window, 'innerWidth', {
        configurable: true,
        writable: true,
        value: originalWidth,
      });
    }
  });

  it('compact viewport: tapping FloatingToggle expands the full HUD (R-23-08, F-22-01)', async () => {
    // R-23-08 — fixes F-22-01. Pre-R23, the compact-viewport branch
    // rendered a FloatingToggle whose `onShow={() => setHudVisible(true)}`
    // callback was inert (`hudVisible` already defaulted to `true`). The
    // inline comment promised "tap to re-expand" but the code did not
    // deliver. Post-R23, `compactExpanded` tracks the override: tap →
    // `setCompactExpanded(true)` → compact branch fails → full HUD
    // renders. This test exercises the round-trip.
    const originalWidth = window.innerWidth;
    Object.defineProperty(window, 'innerWidth', {
      configurable: true,
      writable: true,
      value: 600,
    });

    try {
      render(<PinScope />);
      await act(async () => {
        window.dispatchEvent(new Event('resize'));
        await new Promise((r) => setTimeout(r, 0));
      });

      const hud = document.querySelector('[data-pinscope-ui="root"]');
      expect(hud).not.toBeNull();

      // Pre-tap: compact branch — only FloatingToggle, no PinBadges.
      expect(hud!.querySelector('[data-pinscope-badges]')).toBeNull();
      const toggle = hud!.querySelector(
        '[data-pinscope-toggle]',
      ) as HTMLButtonElement | null;
      expect(toggle).not.toBeNull();

      // Tap the FloatingToggle.
      await act(async () => {
        toggle!.click();
      });

      // Post-tap (still compact viewport): full HUD renders.
      // `[data-pinscope-badges]` exists (PinBadges mounted).
      expect(hud!.querySelector('[data-pinscope-badges]')).not.toBeNull();
    } finally {
      Object.defineProperty(window, 'innerWidth', {
        configurable: true,
        writable: true,
        value: originalWidth,
      });
    }
  });
});
