import { describe, it, expect, afterEach, vi } from 'vitest';
import { render, cleanup } from '@testing-library/react';
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
