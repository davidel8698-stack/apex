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
