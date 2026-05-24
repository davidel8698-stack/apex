import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { withPinScope } from '../../src/plugin/next.js';
import { PinScopeWebpackPlugin } from '../../src/plugin/webpack.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const pkg = JSON.parse(
  fs.readFileSync(path.join(root, 'package.json'), 'utf-8'),
) as { exports: Record<string, string> };
const subpaths = ['.', './vite', './runtime', './next', './webpack'];

describe('package export map (AC-090)', () => {
  it('declares every documented subpath', () => {
    for (const sp of subpaths) {
      expect(pkg.exports[sp], `exports["${sp}"]`).toBeDefined();
    }
  });

  it.each(subpaths)('resolves %s to an existing built file', (sp) => {
    const target = pkg.exports[sp] as string;
    const abs = path.join(root, target);
    expect(
      fs.existsSync(abs),
      `${target} should exist — run "npm run build" first`,
    ).toBe(true);
  });

  it('dynamically imports each built entry point', () => {
    // Subprocess-import (R-21 — fixes AC-090 host-env bug). The original
    // `await import(pathToFileURL(...).href)` runs inside Vitest's Vite-based
    // loader, which mis-handles percent-encoded non-ASCII chars in the
    // project path (Vite calls `loadAndTransform(url)` with the percent-
    // encoded URL, then fails to map back to the on-disk filename). The
    // import semantics being verified — that each dist/ entry point is a
    // loadable ESM module — are identical whether the loader is Vite's or
    // node's; running it in a node subprocess bypasses Vite entirely.
    for (const sp of subpaths) {
      const target = pkg.exports[sp] as string;
      const url = pathToFileURL(path.join(root, target)).href;
      const code = `import(${JSON.stringify(url)}).then(m => { if (m && typeof m === 'object') process.exit(0); console.error('not-object'); process.exit(1); }).catch(e => { console.error(e.message); process.exit(2); });`;
      const result = spawnSync('node', ['--input-type=module', '-e', code], {
        encoding: 'utf-8',
        timeout: 15000,
      });
      expect(
        result.status,
        `${sp} → ${result.stderr || result.stdout || 'no output'}`,
      ).toBe(0);
    }
  });
});

describe('Next.js + Webpack integration (AC-092)', () => {
  it('withPinScope preserves the input config and adds a webpack hook', () => {
    const result = withPinScope({ reactStrictMode: true });
    expect(result['reactStrictMode']).toBe(true);
    expect(typeof result.webpack).toBe('function');
  });

  it('withPinScope composes an existing webpack function', () => {
    let called = false;
    const result = withPinScope({
      webpack: (config) => {
        called = true;
        return config;
      },
    });
    (result.webpack as (c: unknown, ctx: unknown) => unknown)({}, {});
    expect(called).toBe(true);
  });

  it('PinScopeWebpackPlugin exposes a working apply method', () => {
    const plugin = new PinScopeWebpackPlugin();
    expect(typeof plugin.apply).toBe('function');
    expect(() => plugin.apply({ hooks: {} })).not.toThrow();
  });
});
