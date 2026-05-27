import { describe, it, expect } from 'vitest';
import { transformJSX } from '../../src/plugin/ast-transformer.js';
import { PinMap } from '../../src/plugin/pin-map.js';
import { transformerCases } from './fixtures/transformer-cases.js';

const EXCLUDE = ['Fragment', 'Suspense'];
const PIN_RE = /data-pin="e_\d+"/;

function freshMap(): PinMap {
  return new PinMap('/tmp/pinscope-test-nonexistent.pinmap.json');
}

function run(jsx: string, map: PinMap = freshMap()) {
  return transformJSX(`const x = ${jsx};\n`, '/src/App.tsx', map, {
    excludeTags: EXCLUDE,
  });
}

describe('AST transformer — fixture cases', () => {
  it('provides at least 50 input/output pairs (AC-080)', () => {
    expect(transformerCases.length).toBeGreaterThanOrEqual(50);
  });

  it.each(transformerCases)('$name', (c) => {
    const out = run(c.jsx).code;
    if (c.expectPin) {
      expect(out).toMatch(PIN_RE);
    } else {
      expect(out).not.toMatch(PIN_RE);
    }
  });
});

describe('AST transformer — behavior', () => {
  it('injects data-pin starting at e_1 (AC-002)', () => {
    expect(run('<button>Hi</button>').code).toMatch(/data-pin="e_1"/);
  });

  it('does not re-pin an element that already has data-pin (AC-004)', () => {
    const out = run('<div data-pin="e_keep" />').code;
    expect(out).toContain('data-pin="e_keep"');
    expect(out).not.toMatch(PIN_RE);
  });

  it('skips elements carrying data-pin-ignore (AC-004)', () => {
    expect(run('<div data-pin-ignore />').code).not.toMatch(PIN_RE);
  });

  it('skips elements whose tag is in excludeTags — Fragment, Suspense (AC-003)', () => {
    expect(run('<Fragment />').code).not.toMatch(PIN_RE);
    expect(run('<Suspense />').code).not.toMatch(PIN_RE);
  });

  it('emits a source map (AC-011)', () => {
    expect(run('<div />').map).not.toBeNull();
  });

  it('assigns identical ids across two runs of the same source (AC-005)', () => {
    const src = 'const x = <button><span /></button>;\n';
    const a = transformJSX(src, '/src/App.tsx', freshMap(), {
      excludeTags: EXCLUDE,
    });
    const b = transformJSX(src, '/src/App.tsx', freshMap(), {
      excludeTags: EXCLUDE,
    });
    expect(a.code).toBe(b.code);
  });

  it('assigns distinct ids to distinct elements', () => {
    const out = run('<div><span /><span /></div>').code;
    const ids = [...out.matchAll(/data-pin="(e_\d+)"/g)].map((m) => m[1]);
    expect(ids.length).toBe(3);
    expect(new Set(ids).size).toBe(3);
  });

  it('resolves a member-expression tag (AC-012)', () => {
    expect(run('<Foo.Bar />').code).toMatch(PIN_RE);
  });

  it('resolves a namespaced JSX tag (AC-012)', () => {
    expect(run('<svg:rect />').code).toMatch(PIN_RE);
  });
});

/**
 * R-25-05 — AC-004 strengthen: excludeTags + data-pin-ignore opt-outs.
 *
 * The existing AC-004 cases above prove (a) a pre-existing `data-pin` is not
 * overwritten and (b) `data-pin-ignore` opts out. R25 explicitly covers the
 * excludeTags config path (previously tagged AC-003 only) and adds a
 * positive sanity case proving sibling elements ARE instrumented when the
 * sibling does not carry the opt-out. The trio kills any single-rule
 * shortcut that disables the opt-outs.
 */
describe('AST transformer — opt-out rules (AC-004)', () => {
  it('AC-004 — excludeTags from config is honored', () => {
    const out = run('<Fragment><span /></Fragment>').code;
    // Fragment is in EXCLUDE; the span (not excluded) IS instrumented.
    expect(out).not.toMatch(/data-pin="e_\d+"[^>]*?>\s*<span/);
    expect(out).toContain('<Fragment>');
    expect(out).toMatch(/data-pin="e_\d+"/); // the span got pinned
  });

  it('AC-004 — data-pin-ignore opt-out is honored', () => {
    const out = run('<div data-pin-ignore><span /></div>').code;
    // The outer div has data-pin-ignore — must NOT have data-pin.
    // The inner span IS instrumented (opt-out is per-element, not inherited).
    const divMatch = /<div\s+data-pin-ignore[^>]*>/.exec(out);
    expect(divMatch).not.toBeNull();
    // The divMatch substring itself must not contain data-pin.
    expect(divMatch?.[0]).not.toMatch(/data-pin="e_/);
  });

  it('AC-004 — sibling without opt-out IS instrumented (sanity)', () => {
    const out = run('<section><Fragment /><button /></section>').code;
    // Fragment skipped, but button gets a pin AND section gets a pin.
    const pins = [...out.matchAll(/data-pin="(e_\d+)"/g)].map((m) => m[1]);
    expect(pins.length).toBe(2); // section + button
    expect(new Set(pins).size).toBe(2);
  });
});
