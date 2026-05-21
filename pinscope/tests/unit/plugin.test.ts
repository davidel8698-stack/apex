import { describe, it, expect } from 'vitest';
import type { Plugin } from 'vite';
import { pinscope } from '../../src/plugin/index.js';

type TransformFn = (code: string, id: string) => unknown;

function transformOf(p: Plugin): TransformFn {
  const hook = p.transform;
  return (typeof hook === 'function' ? hook : hook?.handler) as unknown as TransformFn;
}

function indexHtmlOf(p: Plugin): (html: string) => string {
  const hook = p.transformIndexHtml;
  return (typeof hook === 'function' ? hook : hook?.handler) as unknown as (
    html: string,
  ) => string;
}

describe('pinscope() plugin shape (AC-001)', () => {
  it('returns a Vite plugin with the expected identity and hooks', () => {
    const p = pinscope();
    expect(p.name).toBe('vite-plugin-pinscope');
    expect(p.enforce).toBe('pre');
    expect(p.buildStart).toBeDefined();
    expect(p.transform).toBeDefined();
    expect(p.buildEnd).toBeDefined();
    expect(p.transformIndexHtml).toBeDefined();
  });
});

describe('pinscope() transform gating (AC-013)', () => {
  it('returns null for a non-matching file extension', () => {
    expect(transformOf(pinscope({ enabled: true }))('.a{}', '/src/a.css')).toBeNull();
  });

  it('returns null for an excluded path (node_modules)', () => {
    expect(
      transformOf(pinscope({ enabled: true }))('const x=1;', '/node_modules/p/A.tsx'),
    ).toBeNull();
  });

  it('returns null for a .test. file', () => {
    expect(
      transformOf(pinscope({ enabled: true }))('const x=1;', '/src/A.test.tsx'),
    ).toBeNull();
  });

  it('returns null entirely when disabled', () => {
    expect(
      transformOf(pinscope({ enabled: false }))('const x=<div/>;', '/src/A.tsx'),
    ).toBeNull();
  });

  it('transforms a matching .tsx file when enabled', () => {
    const result = transformOf(pinscope({ enabled: true }))(
      'const x = <div />;\n',
      '/src/App.tsx',
    ) as { code: string };
    expect(result.code).toMatch(/data-pin="e_\d+"/);
  });
});

describe('pinscope() transformIndexHtml (AC-009)', () => {
  it('strips data-pin from HTML when disabled', () => {
    const html = indexHtmlOf(pinscope({ enabled: false, stripInProduction: true }));
    expect(html('<div data-pin="e_1">x</div>')).toBe('<div>x</div>');
  });

  it('leaves HTML untouched when enabled', () => {
    const html = indexHtmlOf(pinscope({ enabled: true }));
    expect(html('<div data-pin="e_1">x</div>')).toBe('<div data-pin="e_1">x</div>');
  });
});
