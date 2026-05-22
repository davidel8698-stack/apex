import { describe, it, expect, afterEach, vi } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { PinScope } from '../../../src/runtime/PinScope.js';

afterEach(() => {
  cleanup();
  vi.unstubAllEnvs();
  document.body.innerHTML = '';
});

/** Query the HUD subtree portalled into document.body. */
function hud(): Element {
  const root = document.querySelector('[data-pinscope-ui="root"]');
  if (!root) throw new Error('PinScope HUD root not rendered');
  return root;
}

describe('PinScope root assembly (R-15-01, §7.1)', () => {
  it('mounts all seven §7.1 components into the HUD tree', () => {
    render(<PinScope defaultGridMode="pixel" />);
    // The Crosshair draws once the pointer has a position (§8.3) — give it one.
    fireEvent.mouseMove(document.body, { clientX: 60, clientY: 60 });
    const root = hud();
    // Measurement + control surface.
    expect(root.querySelector('[data-pinscope-rulers]')).not.toBeNull();
    expect(root.querySelector('[data-pinscope-crosshair]')).not.toBeNull();
    expect(root.querySelector('[data-pinscope-grid]')).not.toBeNull();
    expect(root.querySelector('[data-pinscope-topbar]')).not.toBeNull();
    expect(root.querySelector('[data-pinscope-command]')).not.toBeNull();
    // Inspection layer: PinBadges renders a <style> badge sheet; the rulers
    // corner is the InfoPanel-adjacent live-coordinate readout.
    expect(root.querySelector('[data-pinscope-badges]')).not.toBeNull();
    expect(root.querySelector('[data-pinscope-ruler-corner]')).not.toBeNull();
  });

  it('renders the GridOverlay only when defaultGridMode is non-off', () => {
    const { unmount } = render(<PinScope defaultGridMode="off" />);
    expect(hud().querySelector('[data-pinscope-grid]')).toBeNull();
    unmount();
    document.body.innerHTML = '';
    render(<PinScope defaultGridMode="baseline" />);
    expect(hud().querySelector('[data-pinscope-grid="baseline"]')).not.toBeNull();
  });

  it('shows only the FloatingToggle when the HUD is hidden', () => {
    render(<PinScope />);
    // Toggle HUD off via the §8.11 Shift+H shortcut.
    fireEvent.keyDown(document, { key: 'h', shiftKey: true });
    const root = hud();
    expect(root.querySelector('[data-pinscope-toggle]')).not.toBeNull();
    // No other §7.1 component is rendered while hidden.
    expect(root.querySelector('[data-pinscope-rulers]')).toBeNull();
    expect(root.querySelector('[data-pinscope-topbar]')).toBeNull();
    expect(root.querySelector('[data-pinscope-command]')).toBeNull();
  });

  it('clicking the FloatingToggle restores the HUD', () => {
    render(<PinScope />);
    fireEvent.keyDown(document, { key: 'h', shiftKey: true });
    const toggle = hud().querySelector('[data-pinscope-toggle]') as HTMLElement;
    expect(toggle).not.toBeNull();
    fireEvent.click(toggle);
    expect(hud().querySelector('[data-pinscope-topbar]')).not.toBeNull();
  });

  it('does not react to shortcuts when shortcutsEnabled={false}', () => {
    render(<PinScope defaultGridMode="pixel" shortcutsEnabled={false} />);
    const before = hud().querySelector('[data-pinscope-grid]')?.getAttribute(
      'data-pinscope-grid',
    );
    expect(before).toBe('pixel');
    // Shift+G would cycle the grid mode if shortcuts were live.
    fireEvent.keyDown(document, { key: 'g', shiftKey: true });
    const after = hud().querySelector('[data-pinscope-grid]')?.getAttribute(
      'data-pinscope-grid',
    );
    expect(after).toBe('pixel');
  });

  it('cycles the grid mode on Shift+G when shortcuts are enabled', () => {
    render(<PinScope defaultGridMode="pixel" />);
    expect(
      hud().querySelector('[data-pinscope-grid]')?.getAttribute('data-pinscope-grid'),
    ).toBe('pixel');
    fireEvent.keyDown(document, { key: 'g', shiftKey: true });
    expect(
      hud().querySelector('[data-pinscope-grid]')?.getAttribute('data-pinscope-grid'),
    ).toBe('baseline');
  });

  it('still renders null under NODE_ENV=production (guard preserved)', () => {
    vi.stubEnv('NODE_ENV', 'production');
    const { container } = render(<PinScope defaultGridMode="pixel" />);
    expect(container.innerHTML).toBe('');
    expect(document.querySelector('[data-pinscope-ui="root"]')).toBeNull();
  });
});
