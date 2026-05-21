import { describe, it, expect, afterEach } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { Rulers } from '../../../src/runtime/components/Rulers.js';
import { Crosshair } from '../../../src/runtime/components/Crosshair.js';
import {
  GridOverlay,
  nextGridMode,
  type GridMode,
} from '../../../src/runtime/components/GridOverlay.js';
import {
  MeasurementTool,
  measure,
} from '../../../src/runtime/components/MeasurementTool.js';
import { VoidBadges } from '../../../src/runtime/components/VoidBadges.js';

afterEach(() => {
  cleanup();
  document.body.innerHTML = '';
});

describe('Rulers (AC-034)', () => {
  it('renders ticks at the configured interval', () => {
    const { container } = render(<Rulers width={1440} height={900} />);
    const xTicks = container.querySelectorAll('[data-ruler-tick="x"]');
    // 0, 100, ... 1400 -> 15 ticks
    expect(xTicks).toHaveLength(15);
  });

  it('labels ticks in a monospace font', () => {
    const { container } = render(<Rulers width={300} height={300} />);
    const bar = container.querySelector('[data-pinscope-rulers] > div');
    expect(bar?.getAttribute('style')).toContain('monospace');
  });
});

describe('Crosshair (AC-035)', () => {
  it('tracks the cursor position', () => {
    const { container } = render(<Crosshair />);
    fireEvent.mouseMove(document.body, { clientX: 120, clientY: 240 });
    const vLine = container.querySelector('[data-crosshair="v"]');
    expect(vLine?.getAttribute('style')).toContain('left: 120px');
  });

  it('hides when the cursor is over the HUD', () => {
    document.body.innerHTML =
      '<div data-pinscope-ui="root"><button id="hud-btn">x</button></div>';
    const { container } = render(<Crosshair />);
    fireEvent.mouseMove(document.body, { clientX: 50, clientY: 50 });
    expect(container.querySelector('[data-crosshair="v"]')).not.toBeNull();
    const hudBtn = document.getElementById('hud-btn') as HTMLElement;
    fireEvent.mouseMove(hudBtn, { clientX: 10, clientY: 10 });
    expect(container.querySelector('[data-crosshair="v"]')).toBeNull();
  });
});

describe('GridOverlay (AC-036)', () => {
  it('cycles modes off -> pixel -> baseline -> column -> spacing -> off', () => {
    const seen: GridMode[] = [];
    let mode: GridMode = 'off';
    for (let i = 0; i < 5; i++) {
      mode = nextGridMode(mode);
      seen.push(mode);
    }
    expect(seen).toEqual(['pixel', 'baseline', 'column', 'spacing', 'off']);
  });

  it('renders an SVG pattern for each active mode', () => {
    for (const mode of ['pixel', 'baseline', 'column', 'spacing'] as GridMode[]) {
      const { container, unmount } = render(<GridOverlay mode={mode} />);
      expect(container.querySelector(`[data-grid-pattern="${mode}"]`)).not.toBeNull();
      unmount();
    }
  });

  it('renders nothing when the mode is off', () => {
    const { container } = render(<GridOverlay mode="off" />);
    expect(container.innerHTML).toBe('');
  });
});

describe('MeasurementTool (AC-039)', () => {
  it('computes dx / dy / diagonal / gap', () => {
    expect(measure({ x: 0, y: 0 }, { x: 30, y: 40 })).toEqual({
      dx: 30,
      dy: 40,
      diagonal: 50,
      gap: 30,
    });
  });

  it('renders four labels after two clicks', () => {
    const { container } = render(<MeasurementTool />);
    expect(container.innerHTML).toBe('');
    fireEvent.click(document.body, { clientX: 0, clientY: 0 });
    fireEvent.click(document.body, { clientX: 30, clientY: 40 });
    const label = (axis: string): string =>
      container.querySelector(`[data-measure="${axis}"]`)?.textContent ?? '';
    expect(label('dx')).toContain('30');
    expect(label('dy')).toContain('40');
    expect(label('diagonal')).toContain('50');
    expect(label('gap')).toContain('30');
  });
});

describe('VoidBadges (AC-024)', () => {
  it('renders an overlay badge carrying the matching pin id over a void element', () => {
    document.body.innerHTML =
      '<img data-pin="e_5" src="x" /><input data-pin="e_6" />';
    const { container } = render(<VoidBadges />);
    const badge = container.querySelector('[data-void-badge="e_5"]');
    expect(badge).not.toBeNull();
    expect(badge?.textContent).toBe('e_5');
    expect(container.querySelector('[data-void-badge="e_6"]')).not.toBeNull();
  });

  it('ignores non-void pinned elements', () => {
    document.body.innerHTML = '<div data-pin="e_1">x</div>';
    const { container } = render(<VoidBadges />);
    expect(container.querySelector('[data-void-badge]')).toBeNull();
  });
});
