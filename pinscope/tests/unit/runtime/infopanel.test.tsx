import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { InfoPanel } from '../../../src/runtime/components/InfoPanel.js';
import type { HoveredElement } from '../../../src/types/element-info.js';

function hoveredOf(el: HTMLElement): HoveredElement {
  return {
    element: el,
    pinId: 'e_9',
    rect: { width: 100, height: 40, x: 0, y: 0 } as DOMRect,
  };
}

afterEach(() => {
  cleanup();
  document.body.innerHTML = '';
  localStorage.clear();
});

describe('InfoPanel sections (AC-031)', () => {
  it('renders Appearance, Layout and Hierarchy sections', () => {
    const el = document.createElement('button');
    document.body.appendChild(el);
    const { container } = render(<InfoPanel hovered={hoveredOf(el)} />);
    expect(container.querySelector('[data-section="appearance"]')).not.toBeNull();
    expect(container.querySelector('[data-section="layout"]')).not.toBeNull();
    expect(container.querySelector('[data-section="hierarchy"]')).not.toBeNull();
  });
});

describe('InfoPanel collapsible persistence (AC-032)', () => {
  it('persists a collapsed section to localStorage across remount', () => {
    const el = document.createElement('button');
    document.body.appendChild(el);

    const first = render(<InfoPanel hovered={hoveredOf(el)} />);
    fireEvent.click(
      first.container.querySelector('[data-section-toggle="dimensions"]') as HTMLElement,
    );
    expect(
      first.container
        .querySelector('[data-section="dimensions"]')
        ?.getAttribute('data-collapsed'),
    ).toBe('true');
    expect(localStorage.getItem('pinscope:section:dimensions')).toBe('1');
    first.unmount();

    // Re-mount = a page reload.
    const second = render(<InfoPanel hovered={hoveredOf(el)} />);
    expect(
      second.container
        .querySelector('[data-section="dimensions"]')
        ?.getAttribute('data-collapsed'),
    ).toBe('true');
    expect(
      second.container.querySelector('[data-section-body="dimensions"]'),
    ).toBeNull();
  });
});

describe('InfoPanel color rendering (AC-033)', () => {
  it('renders a swatch for color values and a dash for empty ones', () => {
    const el = document.createElement('button');
    el.style.color = 'rgb(255, 0, 0)';
    document.body.appendChild(el);
    const { container } = render(<InfoPanel hovered={hoveredOf(el)} />);
    expect(
      container.querySelector('[data-style-row="Color"] [data-swatch]'),
    ).not.toBeNull();
    expect(
      container.querySelector('[data-style-row="Shadow"] [data-empty]'),
    ).not.toBeNull();
  });
});
