import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Behavioral test for AC-076 (R-15-10).
 *
 * `html2canvas` must be loaded with a *lazy dynamic import* — it must not be
 * fetched until `captureScreenshot` is actually called (SPEC §4 / resolution
 * I-4). The previous version of this test grepped `screenshot.ts` source for
 * the string `import('html2canvas')`, which is a false pass: a refactor that
 * keeps the token but breaks laziness still passes, and a correct lazy import
 * written differently fails.
 *
 * This test instead exercises the real module. `html2canvas` is mocked with a
 * spy default export. The spy is invoked through `html2canvas(element)`; the
 * factory's `evaluated` flag records whether the module body ran. We assert:
 *   1. importing `screenshot.ts` does NOT load/evaluate `html2canvas`;
 *   2. calling `captureScreenshot` loads it exactly once and yields a PNG
 *      data URL.
 *
 * A `captureScreenshot` rewritten to a static top-level
 * `import html2canvas from 'html2canvas'` would evaluate the mocked module at
 * `screenshot.ts` import time — failing assertion (1).
 */

/** Set true the first time the mocked `html2canvas` module body evaluates. */
const moduleState = { evaluated: false };

/** Spy for the `html2canvas` default export — counts real invocations. */
const html2canvasSpy = vi.fn((_element: HTMLElement, _opts: unknown) => {
  return Promise.resolve({
    toDataURL: (type: string) => `data:${type};base64,AAAA`,
  });
});

vi.mock('html2canvas', () => {
  // This factory body runs only when the `html2canvas` module is first
  // imported. Recording it here lets the test observe *when* the load
  // happens relative to `captureScreenshot`.
  moduleState.evaluated = true;
  return { default: html2canvasSpy };
});

beforeEach(() => {
  html2canvasSpy.mockClear();
  moduleState.evaluated = false;
});

describe('screenshot — lazy html2canvas (AC-076)', () => {
  it('does not load html2canvas merely by importing the screenshot module', async () => {
    // Import the module under test. If `captureScreenshot` used a static
    // top-level import, the mocked `html2canvas` module body would evaluate
    // here and `moduleState.evaluated` would already be true.
    const mod = await import('../../src/runtime/utils/screenshot.js');
    expect(typeof mod.captureScreenshot).toBe('function');
    expect(moduleState.evaluated).toBe(false);
    expect(html2canvasSpy).not.toHaveBeenCalled();
  });

  it('loads html2canvas exactly once when captureScreenshot runs and returns a PNG data URL', async () => {
    const { captureScreenshot } = await import(
      '../../src/runtime/utils/screenshot.js'
    );
    // Still not loaded after import — only after the call.
    expect(moduleState.evaluated).toBe(false);

    const element = { nodeType: 1 } as unknown as HTMLElement;
    const result = await captureScreenshot(element);

    expect(moduleState.evaluated).toBe(true);
    expect(html2canvasSpy).toHaveBeenCalledTimes(1);
    expect(html2canvasSpy).toHaveBeenCalledWith(
      element,
      expect.objectContaining({ logging: false }),
    );
    expect(result).toBe('data:image/png;base64,AAAA');
  });

  it('passes a caller-supplied backgroundColor through to html2canvas', async () => {
    const { captureScreenshot } = await import(
      '../../src/runtime/utils/screenshot.js'
    );
    const element = { nodeType: 1 } as unknown as HTMLElement;
    await captureScreenshot(element, { backgroundColor: '#fff' });

    expect(html2canvasSpy).toHaveBeenCalledTimes(1);
    expect(html2canvasSpy).toHaveBeenCalledWith(
      element,
      expect.objectContaining({ backgroundColor: '#fff' }),
    );
  });
});
