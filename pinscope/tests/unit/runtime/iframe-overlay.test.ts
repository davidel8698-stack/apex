import { describe, it, expect, afterEach } from 'vitest';
import {
  isCrossOriginFrame,
  markCrossOriginFrames,
  isIframeLimited,
} from '../../../src/runtime/utils/iframe-overlay.js';

afterEach(() => {
  document.body.innerHTML = '';
});

/** Make an iframe instance simulate a cross-origin `contentDocument`. */
function makeCrossOrigin(
  frame: HTMLIFrameElement,
  variant: 'throw' | 'null',
): void {
  Object.defineProperty(frame, 'contentDocument', {
    configurable: true,
    get() {
      if (variant === 'throw') {
        throw new DOMException('cross-origin', 'SecurityError');
      }
      return null;
    },
  });
}

describe('Cross-origin iframe overlay (AC-061)', () => {
  it('reports a same-origin iframe as not cross-origin and does not mark it', () => {
    const frame = document.createElement('iframe');
    document.body.appendChild(frame);
    expect(isCrossOriginFrame(frame)).toBe(false);
    const count = markCrossOriginFrames(document);
    expect(count).toBe(0);
    expect(frame.hasAttribute('data-pin-iframe')).toBe(false);
  });

  it('reports a cross-origin iframe as cross-origin when access throws', () => {
    const frame = document.createElement('iframe');
    makeCrossOrigin(frame, 'throw');
    document.body.appendChild(frame);
    expect(isCrossOriginFrame(frame)).toBe(true);
  });

  it('reports a cross-origin iframe as cross-origin when access yields null', () => {
    const frame = document.createElement('iframe');
    makeCrossOrigin(frame, 'null');
    document.body.appendChild(frame);
    expect(isCrossOriginFrame(frame)).toBe(true);
  });

  it('marks cross-origin frames, returns the count, and appends one overlay each', () => {
    const sameOrigin = document.createElement('iframe');
    document.body.appendChild(sameOrigin);

    const crossA = document.createElement('iframe');
    crossA.setAttribute('data-pin', 'e_42');
    makeCrossOrigin(crossA, 'throw');
    document.body.appendChild(crossA);

    const crossB = document.createElement('iframe');
    crossB.src = 'https://example.com/widget';
    makeCrossOrigin(crossB, 'null');
    document.body.appendChild(crossB);

    const count = markCrossOriginFrames(document);
    expect(count).toBe(2);
    expect(crossA.hasAttribute('data-pin-iframe')).toBe(true);
    expect(crossB.hasAttribute('data-pin-iframe')).toBe(true);
    expect(sameOrigin.hasAttribute('data-pin-iframe')).toBe(false);

    const overlays = document.querySelectorAll(
      '[data-pinscope-iframe-overlay]',
    );
    expect(overlays.length).toBe(2);
  });

  it('labels the overlay with the frame data-pin id when present', () => {
    const frame = document.createElement('iframe');
    frame.setAttribute('data-pin', 'e_42');
    makeCrossOrigin(frame, 'throw');
    document.body.appendChild(frame);

    markCrossOriginFrames(document);
    const overlay = document.querySelector('[data-pinscope-iframe-overlay]');
    expect(overlay?.textContent).toContain('e_42');
  });

  it('falls back to the frame src host for the overlay label', () => {
    const frame = document.createElement('iframe');
    frame.src = 'https://example.com/widget';
    makeCrossOrigin(frame, 'null');
    document.body.appendChild(frame);

    markCrossOriginFrames(document);
    const overlay = document.querySelector('[data-pinscope-iframe-overlay]');
    expect(overlay?.textContent).toContain('example.com');
  });

  it('builds an absolutely-positioned, click-through overlay', () => {
    const frame = document.createElement('iframe');
    makeCrossOrigin(frame, 'throw');
    document.body.appendChild(frame);

    markCrossOriginFrames(document);
    const overlay = document.querySelector<HTMLDivElement>(
      '[data-pinscope-iframe-overlay]',
    );
    expect(overlay?.style.position).toBe('absolute');
    expect(overlay?.style.pointerEvents).toBe('none');
  });

  it('reports a marked frame as iframe-limited and a plain element as not', () => {
    const frame = document.createElement('iframe');
    makeCrossOrigin(frame, 'throw');
    document.body.appendChild(frame);
    markCrossOriginFrames(document);
    expect(isIframeLimited(frame)).toBe(true);

    const plain = document.createElement('div');
    document.body.appendChild(plain);
    expect(isIframeLimited(plain)).toBe(false);
  });
});
