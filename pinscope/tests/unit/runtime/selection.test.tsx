import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { SelectionManager } from '../../../src/runtime/managers/SelectionManager.js';
import { PinScope } from '../../../src/runtime/PinScope.js';

afterEach(() => {
  location.hash = '';
  document.body.innerHTML = '';
});

describe('SelectionManager (AC-041)', () => {
  it('mirrors the selected pin to the URL hash', () => {
    const sm = new SelectionManager();
    sm.select('e_47');
    expect(location.hash).toBe('#select=e_47');
    expect(sm.selectedPin).toBe('e_47');
    expect(sm.isLocked).toBe(true);
  });

  it('restores the selected pin from the hash on construction (reload)', () => {
    location.hash = 'select=e_12';
    const restored = new SelectionManager();
    expect(restored.selectedPin).toBe('e_12');
    expect(restored.isLocked).toBe(true);
  });

  it('moves the data-pin-selected attribute to the chosen element', () => {
    document.body.innerHTML =
      '<div data-pin="e_1"></div><div data-pin="e_2"></div>';
    const sm = new SelectionManager();
    sm.select('e_1');
    expect(
      document.querySelector('[data-pin="e_1"]')?.hasAttribute('data-pin-selected'),
    ).toBe(true);
    sm.select('e_2');
    expect(
      document.querySelector('[data-pin="e_1"]')?.hasAttribute('data-pin-selected'),
    ).toBe(false);
    expect(
      document.querySelector('[data-pin="e_2"]')?.hasAttribute('data-pin-selected'),
    ).toBe(true);
  });

  it('clear removes the selection and the hash', () => {
    const sm = new SelectionManager();
    sm.select('e_5');
    sm.clear();
    expect(sm.selectedPin).toBeNull();
    expect(location.hash).toBe('');
  });

  it('goBack steps through selection history', () => {
    const sm = new SelectionManager();
    sm.select('e_1');
    sm.select('e_2');
    sm.goBack();
    expect(sm.selectedPin).toBe('e_1');
  });
});

/**
 * §10-B / §11 — the `select e_N` CommandBar command (the `"select" Target`
 * grammar form of §11) must drive the same selection lock as a `[data-pin]`
 * click: move the `data-pin-selected` attribute, mirror the URL hash, AND lock
 * the InfoPanel onto the pin. R-17-01 (F-17-01): before the fix `PinScopeHud`
 * held two independent `SelectionManager` instances, so the command moved the
 * attribute + hash but never updated the React `selected` state the InfoPanel
 * reads — the panel never locked.
 */
describe('select e_N command — InfoPanel lock (R-17-01, §10-B/§11)', () => {
  beforeEach(() => {
    // §8.6 — the CommandBar persists history through a dev-server endpoint;
    // stub `fetch` so the network seam never escapes the test.
    vi.stubGlobal('fetch', () =>
      Promise.resolve({ ok: true, status: 200 } as Response),
    );
  });

  afterEach(() => {
    cleanup();
    vi.unstubAllGlobals();
    if (typeof location !== 'undefined') location.hash = '';
    document.body.innerHTML = '';
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

  it('the `select e_N` command locks the InfoPanel', () => {
    const pin = plantPin('e_2');
    render(<PinScope />);

    // Nothing selected and the InfoPanel is not locked before the command.
    expect(document.querySelector('[data-pin-selected]')).toBeNull();
    expect(hud().querySelector('[data-testid="pin-id"]')).toBeNull();

    // Type `select e_2` into the CommandBar and submit it — no prior click on
    // any `[data-pin]` element.
    const input = hud().querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    expect(input).not.toBeNull();
    fireEvent.change(input, { target: { value: 'select e_2' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    // §10-B — the command routed through the canonical SelectionManager: the
    // attribute moved and the hash is mirrored.
    expect(document.querySelector('[data-pin-selected]')).toBe(pin);
    expect(location.hash).toBe('#select=e_2');

    // The InfoPanel is now LOCKED onto e_2 — its content reflects the pin id
    // even though the mouse never hovered or clicked a `[data-pin]` element.
    const pinIdLabel = hud().querySelector('[data-testid="pin-id"]');
    expect(pinIdLabel).not.toBeNull();
    expect(pinIdLabel?.textContent).toContain('e_2');
  });

  it('a [data-pin] click still locks the InfoPanel (flow-B not regressed)', () => {
    const pin = plantPin('e_9');
    render(<PinScope />);

    expect(pin.hasAttribute('data-pin-selected')).toBe(false);
    fireEvent.click(pin);

    // §10-B click path is preserved verbatim — attribute, hash, and the
    // InfoPanel lock all still come from the one canonical manager.
    expect(document.querySelector('[data-pin-selected]')).toBe(pin);
    expect(location.hash).toBe('#select=e_9');
    const pinIdLabel = hud().querySelector('[data-testid="pin-id"]');
    expect(pinIdLabel).not.toBeNull();
    expect(pinIdLabel?.textContent).toContain('e_9');
  });
});
