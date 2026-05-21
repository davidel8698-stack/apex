import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { TopBar } from '../../../src/runtime/components/TopBar.js';
import { StatePanel } from '../../../src/runtime/components/StatePanel.js';
import { CommandBar } from '../../../src/runtime/components/CommandBar.js';

afterEach(() => {
  cleanup();
  document.body.innerHTML = '';
  document.documentElement.removeAttribute('data-state-override');
});

describe('TopBar (AC-037)', () => {
  it('shows viewport, grid mode, state, and the live pin count', () => {
    document.body.innerHTML =
      '<i data-pin="e_1"></i><i data-pin="e_2"></i><i data-pin="e_3"></i>';
    const { container } = render(
      <TopBar
        viewport={{ width: 1440, height: 900 }}
        gridMode="pixel"
        stateOverride={null}
      />,
    );
    const field = (name: string): string =>
      container.querySelector(`[data-field="${name}"]`)?.textContent ?? '';
    expect(field('viewport')).toContain('1440');
    expect(field('grid')).toContain('pixel');
    expect(field('state')).toContain('none');
    expect(field('pins')).toContain('3');
  });
});

describe('StatePanel (AC-040)', () => {
  it('sets data-state-override on <html>', () => {
    const { container } = render(<StatePanel />);
    fireEvent.click(
      container.querySelector('[data-state-btn="hover"]') as Element,
    );
    expect(document.documentElement.getAttribute('data-state-override')).toBe(
      'hover',
    );
  });

  it('clears the override when "none" is chosen', () => {
    const { container } = render(<StatePanel />);
    fireEvent.click(
      container.querySelector('[data-state-btn="focus"]') as Element,
    );
    fireEvent.click(
      container.querySelector('[data-state-btn="none"]') as Element,
    );
    expect(
      document.documentElement.hasAttribute('data-state-override'),
    ).toBe(false);
  });
});

describe('CommandBar (AC-038)', () => {
  it('focuses on Ctrl+K and blurs on Escape', () => {
    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    expect(document.activeElement).not.toBe(input);
    fireEvent.keyDown(document, { key: 'k', ctrlKey: true });
    expect(document.activeElement).toBe(input);
    fireEvent.keyDown(input, { key: 'Escape' });
    expect(document.activeElement).not.toBe(input);
  });

  it('recalls history with ArrowUp', () => {
    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'e_1.bg → red' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(input.value).toBe('');
    fireEvent.keyDown(input, { key: 'ArrowUp' });
    expect(input.value).toBe('e_1.bg → red');
  });
});
