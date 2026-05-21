import { describe, it, expect } from 'vitest';
import {
  LongPressDetector,
  isCompactViewport,
  MOBILE_BREAKPOINT,
  LONG_PRESS_MS,
} from '../../src/runtime/utils/long-press.js';

describe('LongPressDetector (AC-064)', () => {
  it('classifies a short press as a tap', () => {
    const detector = new LongPressDetector();
    detector.start(1000);
    expect(detector.end(1100)).toBe('tap');
  });

  it('classifies a press held >= 500ms as a long-press', () => {
    const detector = new LongPressDetector();
    detector.start(1000);
    expect(detector.end(1000 + LONG_PRESS_MS)).toBe('long-press');
  });
});

describe('isCompactViewport (AC-064)', () => {
  it('flags viewports below the mobile breakpoint', () => {
    expect(isCompactViewport(500)).toBe(true);
    expect(isCompactViewport(MOBILE_BREAKPOINT - 1)).toBe(true);
    expect(isCompactViewport(MOBILE_BREAKPOINT)).toBe(false);
    expect(isCompactViewport(1024)).toBe(false);
  });
});
