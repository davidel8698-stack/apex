import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { TopBar } from '../../../src/runtime/components/TopBar.js';
import { StatePanel } from '../../../src/runtime/components/StatePanel.js';
import { CommandBar } from '../../../src/runtime/components/CommandBar.js';
import { Crosshair } from '../../../src/runtime/components/Crosshair.js';
import { applyStateOverride } from '../../../src/runtime/components/StatePanel.js';

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

describe('StatePanel stylesheet-scan override rules (R-15-04, §8.8)', () => {
  afterEach(() => {
    for (const s of Array.from(
      document.querySelectorAll('[data-pinscope-state-rules]'),
    )) {
      s.remove();
    }
    for (const s of Array.from(document.querySelectorAll('style.host-css'))) {
      s.remove();
    }
  });

  it('generates override rules from host :hover stylesheet rules', () => {
    const host = document.createElement('style');
    host.className = 'host-css';
    host.textContent = '.btn:hover { color: red }';
    document.head.appendChild(host);

    applyStateOverride('hover');

    const gen = document.querySelector(
      '[data-pinscope-state-rules]',
    ) as HTMLStyleElement | null;
    expect(gen).not.toBeNull();
    const css = gen?.textContent ?? '';
    expect(css).toContain('[data-state-override="hover"]');
    expect(css).toContain('.btn');
    expect(css).not.toContain(':hover');
  });

  it('clears the generated rules when the override is "none"', () => {
    const host = document.createElement('style');
    host.className = 'host-css';
    host.textContent = '.link:focus { outline: blue }';
    document.head.appendChild(host);

    applyStateOverride('focus');
    const gen = document.querySelector(
      '[data-pinscope-state-rules]',
    ) as HTMLStyleElement | null;
    expect(gen?.textContent).toContain('[data-state-override="focus"]');

    applyStateOverride('none');
    const cleared = document.querySelector(
      '[data-pinscope-state-rules]',
    ) as HTMLStyleElement | null;
    expect(cleared?.textContent ?? '').toBe('');
  });
});

describe('Crosshair disable conditions (R-15-02, §8.3)', () => {
  it('does not render while in measurement mode', () => {
    const { container } = render(<Crosshair measuring />);
    fireEvent.mouseMove(document.body, { clientX: 200, clientY: 200 });
    expect(container.querySelector('[data-pinscope-crosshair]')).toBeNull();
  });

  it('does not render while the HUD is hidden', () => {
    const { container } = render(<Crosshair hudHidden />);
    fireEvent.mouseMove(document.body, { clientX: 200, clientY: 200 });
    expect(container.querySelector('[data-pinscope-crosshair]')).toBeNull();
  });

  it('renders normally with no disable props (guard is conditional)', () => {
    const { container } = render(<Crosshair />);
    fireEvent.mouseMove(document.body, { clientX: 200, clientY: 200 });
    expect(container.querySelector('[data-pinscope-crosshair]')).not.toBeNull();
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
