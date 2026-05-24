import { describe, it, expect } from 'vitest';
import {
  resolveProperty,
  SHORTCUT_PROPERTIES,
} from '../../src/runtime/parsers/property-shortcuts.js';

const expected: Record<string, string> = {
  'padding-y': 'padding-block',
  'padding-x': 'padding-inline',
  'margin-y': 'margin-block',
  'margin-x': 'margin-inline',
  bg: 'background-color',
  fg: 'color',
  radius: 'border-radius',
  weight: 'font-weight',
  size: 'font-size',
  shadow: 'box-shadow',
};

describe('resolveProperty (AC-051)', () => {
  it.each(Object.entries(expected))('resolves %s -> %s', (shortcut, css) => {
    expect(resolveProperty(shortcut)).toBe(css);
  });

  it('passes through a non-shortcut property unchanged', () => {
    expect(resolveProperty('padding')).toBe('padding');
    expect(resolveProperty('border-top-width')).toBe('border-top-width');
  });

  it('exposes every shortcut name', () => {
    expect([...SHORTCUT_PROPERTIES].sort()).toEqual(Object.keys(expected).sort());
  });
});
