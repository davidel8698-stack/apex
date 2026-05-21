import { describe, it, expect } from 'vitest';
import { elementRect } from '../../src/runtime/utils/rect-math.js';
import {
  throttle,
  shouldSkipBadge,
  isHeavyPage,
  HEAVY_PAGE_THRESHOLD,
} from '../../src/runtime/utils/throttle.js';

describe('elementRect — SVG-aware (AC-062)', () => {
  it('maps an SVG bbox through getCTM into viewport space', () => {
    const svgEl = {
      namespaceURI: 'http://www.w3.org/2000/svg',
      getBBox: () => ({ x: 10, y: 20, width: 30, height: 40 }),
      getCTM: () => ({ a: 1, b: 0, c: 0, d: 1, e: 5, f: 6 }),
      getBoundingClientRect: () => ({ x: 0, y: 0, width: 0, height: 0 }),
    } as unknown as Element;
    expect(elementRect(svgEl)).toEqual({ x: 15, y: 26, w: 30, h: 40 });
  });

  it('falls back to getBoundingClientRect for HTML elements', () => {
    const htmlEl = {
      namespaceURI: 'http://www.w3.org/1999/xhtml',
      getBoundingClientRect: () => ({ x: 1, y: 2, width: 3, height: 4 }),
    } as unknown as Element;
    expect(elementRect(htmlEl)).toEqual({ x: 1, y: 2, w: 3, h: 4 });
  });
});

describe('heavy-page throttling (AC-065)', () => {
  it('limits call frequency to leading + trailing', async () => {
    let calls = 0;
    const fn = throttle(() => {
      calls += 1;
    }, 30);
    for (let i = 0; i < 20; i++) fn();
    expect(calls).toBe(1);
    await new Promise((resolve) => setTimeout(resolve, 60));
    expect(calls).toBe(2);
  });

  it('skips badges smaller than 16x16', () => {
    expect(shouldSkipBadge(10, 10)).toBe(true);
    expect(shouldSkipBadge(20, 8)).toBe(true);
    expect(shouldSkipBadge(20, 20)).toBe(false);
  });

  it('flags pages over the heavy-page threshold', () => {
    expect(HEAVY_PAGE_THRESHOLD).toBe(500);
    expect(isHeavyPage(600)).toBe(true);
    expect(isHeavyPage(100)).toBe(false);
  });
});
