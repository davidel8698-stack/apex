import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup } from '@testing-library/react';
import { PinBadges } from '../../../src/runtime/components/PinBadges.js';
import { InfoPanel } from '../../../src/runtime/components/InfoPanel.js';
import { PinScope } from '../../../src/runtime/PinScope.js';

afterEach(() => {
  cleanup();
  // The HUD portal-renders into document.body; clear leftover nodes so the
  // next test starts with a quiet body.
  document.body.innerHTML = '';
});

describe('PinBadges', () => {
  it('injects a style element carrying the data-pin ::before rule', () => {
    const { container } = render(<PinBadges />);
    const style = container.querySelector('style');
    expect(style).not.toBeNull();
    expect(style?.textContent).toContain('[data-pin]::before');
    expect(style?.textContent).toContain('content: attr(data-pin)');
  });
});

describe('InfoPanel', () => {
  it('renders nothing when no element is hovered', () => {
    const { container } = render(<InfoPanel hovered={null} />);
    expect(container.innerHTML).toBe('');
  });

  it('renders dimensions and pin id from the hovered element', () => {
    const el = document.createElement('button');
    document.body.appendChild(el);
    const hovered = {
      element: el,
      pinId: 'e_7',
      rect: { width: 200, height: 56, x: 10, y: 20 } as DOMRect,
    };
    const { getByTestId } = render(<InfoPanel hovered={hovered} />);
    expect(getByTestId('pin-id').textContent).toContain('e_7');
    expect(getByTestId('dimensions').textContent).toContain('200px');
    expect(getByTestId('dimensions').textContent).toContain('56px');
    expect(getByTestId('typography').textContent).toContain('Size');
  });
});

/**
 * R-25-08 — AC-021 strengthen: PinScope kill-switches return null.
 *
 * Two independent kill-switches must both yield a no-op render:
 *   (1) `enabled={false}` — explicit runtime opt-out (SPEC §7.1).
 *   (2) `process.env.NODE_ENV === 'production'` — production guard
 *       (SPEC §1, §7.1 — "PinScope never ships to a production build").
 *
 * Each is verified independently to kill the mutant that drops only one
 * of the two guards.
 */
describe('PinScope kill-switches (AC-021)', () => {
  it('AC-021 — enabled={false} renders null (no HUD, no portal)', () => {
    const { container } = render(<PinScope enabled={false} />);
    expect(container.innerHTML).toBe('');
    // The portal target must also be absent — the kill-switch fires BEFORE
    // any portal is mounted into document.body.
    expect(document.querySelector('[data-pinscope-ui="root"]')).toBeNull();
  });

  it('AC-021 — NODE_ENV=production renders null (production guard)', () => {
    const prev = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const { container } = render(<PinScope />);
      expect(container.innerHTML).toBe('');
      expect(document.querySelector('[data-pinscope-ui="root"]')).toBeNull();
    } finally {
      process.env.NODE_ENV = prev;
    }
  });
});

/**
 * R-25-08 — AC-022 strengthen: HUD portal mount and identity.
 *
 * The HUD lives in a portal rooted at `[data-pinscope-ui="root"]`. Two
 * invariants:
 *   (1) Rendering `<PinScope/>` creates exactly ONE `data-pinscope-ui="root"`
 *       node attached to `document.body` (not the local render container).
 *   (2) The portal root is a direct child of `document.body` — this is what
 *       makes the HUD overlay-able with a top-of-stack z-index regardless
 *       of where `<PinScope/>` is rendered in the React tree.
 */
describe('PinScope HUD portal target (AC-022)', () => {
  it('AC-022 — renders exactly one [data-pinscope-ui="root"] on document.body', () => {
    render(<PinScope />);
    const roots = document.querySelectorAll('[data-pinscope-ui="root"]');
    expect(roots.length).toBe(1);
    // The portal node lives directly under document.body, not inside the
    // local @testing-library container.
    expect(roots[0]?.parentElement).toBe(document.body);
  });

  it('AC-022 — portal escapes the local render container (z-index/stacking sanity)', () => {
    const { container } = render(<PinScope />);
    // The local container has NO HUD root inside it — the HUD is portalled
    // out, which is what enables it to overlay any host-app stacking ctx.
    expect(container.querySelector('[data-pinscope-ui="root"]')).toBeNull();
    // But document.body DOES have it.
    expect(document.querySelector('[data-pinscope-ui="root"]')).not.toBeNull();
  });
});
