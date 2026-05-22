import { describe, it, expect, afterEach } from 'vitest';
import { SelectionManager } from '../../../src/runtime/managers/SelectionManager.js';

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
