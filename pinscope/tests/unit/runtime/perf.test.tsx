import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup } from '@testing-library/react';
import { PinScope } from '../../../src/runtime/PinScope.js';
import { findPinnedAncestor } from '../../../src/runtime/utils/element-walker.js';

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

  it('keeps hover per-frame work under 8 ms (AC-071)', () => {
    const host = document.createElement('div');
    host.innerHTML =
      '<section data-pin="e_1"><button data-pin="e_2"><span>x</span></button></section>';
    document.body.appendChild(host);
    const span = host.querySelector('span') as HTMLElement;

    // warm
    findPinnedAncestor(span)?.getBoundingClientRect();

    const runs = 100;
    const start = performance.now();
    for (let i = 0; i < runs; i++) {
      const pinned = findPinnedAncestor(span);
      pinned?.getBoundingClientRect();
    }
    const perFrame = (performance.now() - start) / runs;
    expect(perFrame).toBeLessThan(8);
  });
});
