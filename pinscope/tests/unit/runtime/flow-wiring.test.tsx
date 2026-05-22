/**
 * §10 behavioral-flow wiring — R-16-01.
 *
 * R15 mounted the §7.1 component tree; this suite proves the §10 flow seams
 * are actually wired into the live `<PinScope/>` root:
 *   - Flow C (§10-C): a CommandBar `operation` submit runs parse → build →
 *     `ClaudeBridge` (a §9.3 `Operation` JSON reaches the clipboard).
 *   - Flow D (§8.7): the `measuring` state renders the `<MeasurementTool/>`.
 *   - Flow B (§10-B): a click on a `[data-pin]` element moves the
 *     `data-pin-selected` attribute (the `useSelectedElement` hook).
 *
 * Authored to FAIL against the pre-R16 `PinScope.tsx` (no `onSubmit`, no
 * `<MeasurementTool/>` render, no `useSelectedElement`).
 */

import { describe, it, expect, afterEach, vi, beforeEach } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { PinScope } from '../../../src/runtime/PinScope.js';

/** A clipboard spy that records every `writeText` payload. */
const clipboardWrites: string[] = [];

beforeEach(() => {
  clipboardWrites.splice(0);
  // §10-C — `ClaudeBridge` copies the Operation JSON via `navigator.clipboard`.
  Object.defineProperty(navigator, 'clipboard', {
    configurable: true,
    value: {
      writeText: (text: string): Promise<void> => {
        clipboardWrites.push(text);
        return Promise.resolve();
      },
    },
  });
  // §8.6 — the CommandBar persists history through the dev-server endpoint;
  // stub `fetch` so the network seam never escapes the test.
  vi.stubGlobal('fetch', () =>
    Promise.resolve({ ok: true, status: 200 } as Response),
  );
});

afterEach(() => {
  cleanup();
  vi.unstubAllGlobals();
  vi.unstubAllEnvs();
  document.body.innerHTML = '';
  if (typeof location !== 'undefined') location.hash = '';
});

/** Query the HUD subtree portalled into document.body. */
function hud(): Element {
  const root = document.querySelector('[data-pinscope-ui="root"]');
  if (!root) throw new Error('PinScope HUD root not rendered');
  return root;
}

/** A pinned element planted in the host page (outside the HUD subtree). */
function plantPin(id: string): HTMLElement {
  const el = document.createElement('div');
  el.setAttribute('data-pin', id);
  el.textContent = `pinned ${id}`;
  document.body.appendChild(el);
  return el;
}

describe('PinScope §10 flow wiring (R-16-01)', () => {
  it('Flow C — a CommandBar operation submit reaches the Operation pipeline', async () => {
    plantPin('e_7');
    render(<PinScope />);

    const input = hud().querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    expect(input).not.toBeNull();

    // Submit a §11 operation command through the live CommandBar.
    fireEvent.change(input, { target: { value: 'e_7.bg → red' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    // The `onSubmit` handler runs parse → build → `ClaudeBridge.send`, which
    // writes the §9.3 `Operation` JSON to the clipboard. Await the async send.
    await vi.waitFor(() => {
      expect(clipboardWrites.length).toBeGreaterThan(0);
    });
    const operation = JSON.parse(clipboardWrites[0] as string) as {
      version: string;
      pin: string;
      request_type: string;
      operations?: { property: string; value?: string }[];
    };
    expect(operation.version).toBe('1.0');
    expect(operation.pin).toBe('e_7');
    expect(operation.request_type).toBe('operation');
    // `bg` resolves to `background-color`; `→` is a `set` op with value `red`.
    expect(operation.operations?.[0]?.property).toBe('background-color');
    expect(operation.operations?.[0]?.value).toBe('red');
  });

  it('Flow D — the measuring state renders the MeasurementTool', () => {
    render(<PinScope />);
    // No measurement readout before two clicks.
    expect(hud().querySelector('[data-pinscope-measure]')).toBeNull();

    // §8.11 Shift+M toggles measurement mode; two clicks produce a readout.
    fireEvent.keyDown(document, { key: 'm', shiftKey: true });
    fireEvent.click(document.body, { clientX: 10, clientY: 10 });
    fireEvent.click(document.body, { clientX: 40, clientY: 50 });

    const readout = hud().querySelector('[data-pinscope-measure]');
    expect(readout).not.toBeNull();
    // The MeasurementTool is gone once measurement mode is toggled back off.
    fireEvent.keyDown(document, { key: 'm', shiftKey: true });
    expect(hud().querySelector('[data-pinscope-measure]')).toBeNull();
  });

  it('Flow B — clicking a pinned element moves the data-pin-selected attribute', () => {
    const pin = plantPin('e_9');
    render(<PinScope />);

    expect(pin.hasAttribute('data-pin-selected')).toBe(false);
    fireEvent.click(pin);

    // The `useSelectedElement` hook ran `SelectionManager.select` → the
    // `data-pin-selected` attribute now sits on the clicked pin (§10-B).
    expect(
      document.querySelector('[data-pin-selected]'),
    ).toBe(pin);
    // §8.9 — the selection is mirrored to the URL hash.
    expect(location.hash).toBe('#select=e_9');
  });
});
