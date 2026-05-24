import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
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

  it('dynamically imports each built entry point', async () => {
    for (const sp of subpaths) {
      const target = pkg.exports[sp] as string;
      const mod = (await import(
        pathToFileURL(path.join(root, target)).href
      )) as Record<string, unknown>;
      expect(mod).toBeTypeOf('object');
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
