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
