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

  it('withPinScope passes (config, context) args through to the host webpack (R-23-03)', () => {
    // R-23-03 — strengthen AC-092: the prior "composes" test only checked
    // `called = true`. SPEC §I-1 wrapper contract requires args
    // passthrough. Confirms a regression that drops args would surface.
    const seen: Array<{ config: unknown; context: unknown }> = [];
    const hostWebpack = (config: unknown, context: unknown): unknown => {
      seen.push({ config, context });
      return config;
    };
    const wrapped = withPinScope({ webpack: hostWebpack });
    const inputConfig = { mode: 'development' };
    const inputCtx = { isServer: false };
    (wrapped.webpack as (c: unknown, ctx: unknown) => unknown)(
      inputConfig,
      inputCtx,
    );
    expect(seen).toHaveLength(1);
    expect(seen[0]?.config).toBe(inputConfig);
    expect(seen[0]?.context).toBe(inputCtx);
  });

  it('withPinScope does not mutate the input config (R-23-03)', () => {
    // R-23-03 — strengthen AC-092: the SPEC wrapper contract requires
    // input immutability. Tests the spread-vs-return-same mutant: a
    // refactor returning `nextConfig` directly (instead of `{...nextConfig,
    // webpack: ...}`) would mutate; this test would fail. Frozen input
    // proves the wrapper does not attempt mutation.
    const input = Object.freeze({ reactStrictMode: true, customKey: 42 });
    const wrapped = withPinScope(input);
    // Wrapped must be a NEW object, not the same reference.
    expect(wrapped).not.toBe(input);
    // Original input must be unchanged.
    expect(input).toEqual({ reactStrictMode: true, customKey: 42 });
    // Wrapped must include the input keys plus webpack.
    expect(wrapped['reactStrictMode']).toBe(true);
    expect(wrapped['customKey']).toBe(42);
    expect(typeof wrapped.webpack).toBe('function');
  });

  it('PinScopeWebpackPlugin exposes a working apply method', () => {
    const plugin = new PinScopeWebpackPlugin();
    expect(typeof plugin.apply).toBe('function');
    expect(() => plugin.apply({ hooks: {} })).not.toThrow();
  });

  it('PinScopeWebpackPlugin.apply is a no-op when enabled:false (R-23-03)', () => {
    // R-23-03 — strengthen AC-092: SPEC says "no-op when production".
    // Prior test only checked apply didn't throw on `{ hooks: {} }`.
    // A regression that READ compiler.hooks even when disabled would not
    // surface. This Proxy raises on ANY hook access; apply must not touch
    // it when enabled:false.
    const plugin = new PinScopeWebpackPlugin({ enabled: false });
    const hooksProxy = new Proxy(
      {},
      {
        get(): unknown {
          throw new Error('hooks accessed despite enabled:false');
        },
      },
    );
    expect(() => plugin.apply({ hooks: hooksProxy })).not.toThrow();
  });

  it('reads the pinscope runtime named export (AC-091, R-23-03)', async () => {
    // R-23-03 — strengthen AC-091: the prior "declares every documented
    // subpath" test (in package-export-map describe) only checks
    // pkg.exports definedness. This asserts the runtime named export
    // contract: `pinscope/vite`'s plugin function exists, returns a Vite
    // plugin object with the documented name/enforce.
    const url = pathToFileURL(
      path.join(root, pkg.exports['./vite'] as string),
    ).href;
    const code = `import(${JSON.stringify(url)}).then(m => { const p = m.pinscope(); if (p && p.name === 'vite-plugin-pinscope' && p.enforce === 'pre') process.exit(0); console.error('bad plugin shape: ' + JSON.stringify({name: p && p.name, enforce: p && p.enforce})); process.exit(1); }).catch(e => { console.error(e.message); process.exit(2); });`;
    const result = spawnSync('node', ['--input-type=module', '-e', code], {
      encoding: 'utf-8',
      timeout: 15000,
    });
    expect(
      result.status,
      `subprocess → ${result.stderr || result.stdout || 'no output'}`,
    ).toBe(0);
  });
});
