import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup } from '@testing-library/react';
import { PinScope } from '../../../src/runtime/PinScope.js';

afterEach(() => {
  cleanup();
  document.body.innerHTML = '';
});

describe('runtime performance', () => {
  it('mounts <PinScope/> in under 50 ms (AC-070)', () => {
    // §13 budgets the per-mount cost. Warm the render path once (one-time
    // module-eval + JIT cost a real browser pays at page load, not per
    // mount) so the measurement reflects the steady-state mount.
    const warm = render(<PinScope />);
    warm.unmount();
    cleanup();
    document.body.innerHTML = '';

    const start = performance.now();
    render(<PinScope />);
    expect(performance.now() - start).toBeLessThan(50);
  });

  it('keeps hover per-frame work under 8 ms (AC-071, R-23-07)', async () => {
    // R-23-07 — REPLACES the prior synthetic-loop micro-bench. SPEC §A.13
    // AC-071 verify clause: "perf test measures the rAF callback duration."
    // The prior test measured `findPinnedAncestor + getBoundingClientRect`
    // in a loop — microseconds always, never the real production cost.
    // This rewrite renders the assembled <PinScope/>, dispatches a real
    // mousemove, and awaits the next animation frame — capturing the
    // production hover→useHoveredElement→state-update→InfoPanel-rerender
    // path that the rAF callback actually drives. Happy-dom's rAF is
    // approximate vs. a real browser, but the test discriminates real
    // regressions (a 10ms busy-loop injected into the rAF callback turns
    // this red) where the synthetic loop could not.
    const host = document.createElement('div');
    host.innerHTML =
      '<section data-pin="e_1"><button data-pin="e_2"><span>x</span></button></section>';
    document.body.appendChild(host);
    render(<PinScope />);
    const span = host.querySelector('span') as HTMLElement;

    // Warm — first hover pays one-time JIT/module-eval cost the real
    // browser pays at page-load (not per-frame).
    span.dispatchEvent(
      new MouseEvent('mousemove', { bubbles: true, clientX: 10, clientY: 10 }),
    );
    await new Promise<void>((r) => requestAnimationFrame(() => r()));

    // Measured: real mousemove → rAF callback → React state update →
    // InfoPanel re-render → layout. Steady-state per-frame cost.
    const start = performance.now();
    span.dispatchEvent(
      new MouseEvent('mousemove', { bubbles: true, clientX: 12, clientY: 12 }),
    );
    await new Promise<void>((r) => requestAnimationFrame(() => r()));
    const perFrame = performance.now() - start;
    expect(perFrame).toBeLessThan(8);
  });
});
