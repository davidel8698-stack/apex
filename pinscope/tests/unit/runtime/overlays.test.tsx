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
import { badgeCss } from '../../../src/runtime/styles/badges.css.js';

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

describe('Rulers multi-scale + corner (R-15-03, §8.2)', () => {
  it('renders ticks at the 10/50/100/200 px scales (multi-scale set)', () => {
    const { container } = render(<Rulers width={400} height={400} />);
    const rulers = container.querySelector('[data-pinscope-rulers]');
    // The four §8.2 scales are recorded on the rulers root.
    expect(rulers?.getAttribute('data-ruler-scales')).toBe('10,50,100,200');

    // Minor scales (10, 50) are drawn as repeating-gradient stripe elements,
    // one per scale on the horizontal bar — each tagged with its scale.
    const stripeScales = new Set<string>();
    for (const s of Array.from(
      container.querySelectorAll('[data-ruler-stripe="x"]'),
    )) {
      const sc = s.getAttribute('data-ruler-scale');
      if (sc) stripeScales.add(sc);
    }
    expect(stripeScales.has('10')).toBe(true);
    expect(stripeScales.has('50')).toBe(true);

    // Major scales (100, 200) are individual labelled tick nodes; for a 400px
    // extent both the 100 and 200 scales must be present.
    const tickScales = new Set<string>();
    for (const t of Array.from(container.querySelectorAll('[data-ruler-tick="x"]'))) {
      const s = t.getAttribute('data-ruler-scale');
      if (s) tickScales.add(s);
    }
    expect(tickScales.has('100')).toBe(true);
    expect(tickScales.has('200')).toBe(true);

    // All four scales present, via two distinct tick classes (stripe + tick)
    // — proving the multi-scale hierarchy the old uniform-interval lacked.
    const allScales = new Set<string>([...stripeScales, ...tickScales]);
    expect(allScales).toEqual(new Set(['10', '50', '100', '200']));
  });

  it('renders a corner element reporting live mouse coordinates', () => {
    const { container } = render(<Rulers width={400} height={400} />);
    const corner = container.querySelector('[data-pinscope-ruler-corner]');
    expect(corner).not.toBeNull();
    fireEvent.mouseMove(document.body, { clientX: 137, clientY: 84 });
    expect(corner?.textContent).toContain('137');
    expect(corner?.textContent).toContain('84');
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

describe('badge CSS hostile-CSS hardening (R-15-05, §12)', () => {
  it('hardens the load-bearing badge ::before declarations with !important', () => {
    // §12: PinScope styles use !important so a hostile host rule cannot win.
    const count = (badgeCss.match(/!important/g) ?? []).length;
    expect(count).toBeGreaterThanOrEqual(12);
  });

  it('hardens the badge z-index against a host z-index override', () => {
    expect(badgeCss).toMatch(/z-index:\s*2147483645\s*!important/);
  });

  it('hardens the badge background against a host background override', () => {
    // The first ::before block carries the blue badge background.
    expect(badgeCss).toMatch(/background:[^;]*!important/);
  });

  it('keeps the HUD-exempt ::before rule winning over the hardened badge', () => {
    // The exempt rule must also be !important or the hardened badge leaks
    // into the HUD subtree.
    expect(badgeCss).toMatch(
      /\[data-pinscope-ui\] \[data-pin\]::before\s*\{\s*display:\s*none\s*!important/,
    );
  });

  it('wins over a hostile host ::before rule via getPropertyPriority', () => {
    // Parse the badgeCss into a stylesheet and confirm the badge ::before
    // declarations report `important` priority — the reliable jsdom predicate.
    const style = document.createElement('style');
    style.textContent = badgeCss;
    document.head.appendChild(style);
    const sheet = style.sheet as CSSStyleSheet;
    let badgeRule: CSSStyleRule | null = null;
    for (const rule of Array.from(sheet.cssRules)) {
      if (
        rule instanceof CSSStyleRule &&
        rule.selectorText === '[data-pin]::before'
      ) {
        badgeRule = rule;
        break;
      }
    }
    expect(badgeRule).not.toBeNull();
    expect(badgeRule?.style.getPropertyPriority('background')).toBe('important');
    expect(badgeRule?.style.getPropertyPriority('z-index')).toBe('important');
    style.remove();
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
