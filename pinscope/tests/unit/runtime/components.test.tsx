import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup } from '@testing-library/react';
import { PinBadges } from '../../../src/runtime/components/PinBadges.js';
import { InfoPanel } from '../../../src/runtime/components/InfoPanel.js';

afterEach(cleanup);

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
