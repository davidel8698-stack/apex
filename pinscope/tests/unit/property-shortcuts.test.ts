import { describe, it, expect } from 'vitest';
import {
  resolveProperty,
  SHORTCUT_PROPERTIES,
} from '../../src/runtime/parsers/property-shortcuts.js';
import { parseCommand } from '../../src/runtime/parsers/operation-parser.js';

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

/**
 * R-25-09 — AC-051 strengthen: end-to-end pipeline coverage for every shortcut.
 *
 * The block above proves `resolveProperty(shortcut) → css` for each pair, plus
 * a pass-through sanity. R25 strengthens AC-051 with two more invariants the
 * SPEC §11 promises but the existing tests do not lock:
 *   (A) Every name in the source `SHORTCUT_PROPERTIES` constant resolves to
 *       a DIFFERENT CSS name (proves it is actually a shortcut, not an
 *       accidental pass-through), AND that resolved CSS is a non-empty
 *       kebab-case string — kills mutations that nullify SHORTCUTS entries.
 *   (B) Each shortcut is acceptable through the live operation pipeline:
 *       `e_1.{shortcut} → 0` parses into a `kind: 'operation'` ParsedCommand
 *       whose `property` carries the raw shortcut name (per SPEC §11
 *       grammar) — and `resolveProperty` on that property yields the
 *       expected CSS. This guards against parser regressions that would
 *       reject a valid shortcut name.
 *
 * Note: SHORTCUT_PROPERTIES currently has 10 entries (not the 32 implied
 * by AC-051 SPEC text). The matrix-bump target was originally 1→32; the
 * actual achievable rigor delta under the current SPEC implementation is
 * 1→{count-of-source-shortcuts}. See WAVE-R25-RESULT.md §W3 for the
 * discovery + W7 matrix-bump revision.
 */
describe('SHORTCUT_PROPERTIES source-driven coverage (AC-051)', () => {
  it('AC-051 — SHORTCUT_PROPERTIES has the expected baseline count (locks any source-side regression)', () => {
    // The current SPEC §11 implementation exposes 10 shortcuts; any change
    // to this count must update both the source AND this test, making
    // accidental removals explicit.
    expect(SHORTCUT_PROPERTIES.length).toBe(10);
  });

  it.each([...SHORTCUT_PROPERTIES])(
    'AC-051 — shortcut %s resolves to a non-empty CSS name different from itself',
    (shortcut) => {
      const resolved = resolveProperty(shortcut);
      expect(resolved.length).toBeGreaterThan(0);
      expect(resolved).not.toBe(shortcut); // proves it's actually a shortcut
      // Resolved CSS must be a kebab-case identifier (no spaces, no caps).
      expect(resolved).toMatch(/^[a-z]+(-[a-z]+)*$/);
    },
  );

  it.each([...SHORTCUT_PROPERTIES])(
    'AC-051 — shortcut %s flows through parseCommand as the operation property',
    (shortcut) => {
      const parsed = parseCommand(`e_1.${shortcut} → 0`);
      // The shortcut name survives parsing verbatim as `parsed.property`.
      // The operation pipeline resolves it downstream via resolveProperty.
      expect(parsed.kind).toBe('operation');
      if (parsed.kind === 'operation') {
        expect(parsed.property).toBe(shortcut);
        expect(parsed.pin).toBe('e_1');
        expect(parsed.value).toBe('0');
        // And the resolver still maps this property to a valid CSS name.
        expect(resolveProperty(parsed.property)).toBe(expected[shortcut]);
      }
    },
  );
});
