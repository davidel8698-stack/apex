import { describe, it, expect, afterEach } from 'vitest';
import type { Plugin } from 'vite';
import { EventEmitter } from 'node:events';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
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

/**
 * R-25-16 — AC-001/AC-009/AC-013 dedup: the three plugin-API describes
 * are grouped under a single parent so all three sub-describes share the
 * AC-001 ancestor tag for traceability. Each sub-describe still names
 * its primary AC. Pure organizational refactor — zero behavioral change.
 */
describe('pinscope() plugin API (AC-001, AC-009, AC-013)', () => {
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
});

/** Minimal fake of a connect-style middleware server. */
interface FakeMiddleware {
  (req: unknown, res: unknown, next: () => void): void;
}
interface FakeServer {
  middlewares: { use(fn: FakeMiddleware): void };
  config: { root: string };
}

/**
 * Drive a POST request body through a middleware and await the response.
 * The resolved object carries the HTTP response **body** string alongside
 * `status` so route tests can assert the `{ ok }` success flag, not only the
 * status code.
 */
function postThrough(
  mw: FakeMiddleware,
  url: string,
  body: string,
): Promise<{ status: number; body: string }> {
  return new Promise((resolve, reject) => {
    const req = new EventEmitter() as EventEmitter & {
      url: string;
      method: string;
    };
    req.url = url;
    req.method = 'POST';
    let status = 200;
    const res = {
      statusCode: 200,
      setHeader(): void {},
      end(responseBody?: string): void {
        status = res.statusCode;
        resolve({ status, body: responseBody ?? '' });
      },
    };
    mw(req, res, () => reject(new Error('next() called — route not matched')));
    req.emit('data', Buffer.from(body));
    req.emit('end');
  });
}

describe('pinscope() snapshot dev-server route (R-15-06, §10-D)', () => {
  const tmpRoots: string[] = [];
  afterEach(() => {
    for (const root of tmpRoots.splice(0)) {
      fs.rmSync(root, { recursive: true, force: true });
    }
  });

  it('writes the snapshot body to .pinscope/snapshots/s_<id>.json', async () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pinscope-snap-'));
    tmpRoots.push(root);

    const p = pinscope({ enabled: true });
    const configureServer = p.configureServer;
    expect(configureServer).toBeDefined();

    let captured: FakeMiddleware | null = null;
    const server: FakeServer = {
      config: { root },
      middlewares: {
        use(fn): void {
          captured = fn;
        },
      },
    };
    const hook =
      typeof configureServer === 'function'
        ? configureServer
        : configureServer?.handler;
    await (hook as (s: FakeServer) => void)(server);
    expect(captured).not.toBeNull();

    const snapshot = { version: '1.0', id: 's_1717000000000', elements: {} };
    const result = await postThrough(
      captured as FakeMiddleware,
      '/__pinscope/snapshot',
      JSON.stringify(snapshot),
    );
    expect(result.status).toBe(200);

    // F-16-05 — the HTTP response body, not only the status, carries the
    // `{ ok: true }` success flag (kills mutant M3: `ok: true → false`).
    const response = JSON.parse(result.body) as { ok: boolean; id: string };
    expect(response.ok).toBe(true);
    expect(response.id).toBe('s_1717000000000');

    const file = path.join(root, '.pinscope', 'snapshots', 's_1717000000000.json');
    expect(fs.existsSync(file)).toBe(true);
    const written = JSON.parse(fs.readFileSync(file, 'utf8')) as { id: string };
    expect(written.id).toBe('s_1717000000000');
  });

  it('creates the snapshot directory chain when the project root is nested', async () => {
    // F-16-07 — the project root is a multi-level path that is NOT created on
    // disk before the POST, so `.pinscope/snapshots/` must be built by the
    // handler's `mkdirSync(dir, { recursive: true })`. Kills mutant M4
    // (`recursive: true → false`): with `recursive: false` the `mkdirSync`
    // throws `ENOENT`, the route answers 400 and no file is written.
    const base = fs.mkdtempSync(path.join(os.tmpdir(), 'pinscope-snap-nested-'));
    tmpRoots.push(base);
    const root = path.join(base, 'workspace', 'apps', 'web');
    // Deliberately uncreated — only `base` exists on disk.
    expect(fs.existsSync(root)).toBe(false);

    const p = pinscope({ enabled: true });
    const configureServer = p.configureServer;
    expect(configureServer).toBeDefined();

    let captured: FakeMiddleware | null = null;
    const server: FakeServer = {
      config: { root },
      middlewares: {
        use(fn): void {
          captured = fn;
        },
      },
    };
    const hook =
      typeof configureServer === 'function'
        ? configureServer
        : configureServer?.handler;
    await (hook as (s: FakeServer) => void)(server);
    expect(captured).not.toBeNull();

    const snapshot = { version: '1.0', id: 's_1717000099999', elements: {} };
    const result = await postThrough(
      captured as FakeMiddleware,
      '/__pinscope/snapshot',
      JSON.stringify(snapshot),
    );
    expect(result.status).toBe(200);
    const response = JSON.parse(result.body) as { ok: boolean };
    expect(response.ok).toBe(true);

    const file = path.join(root, '.pinscope', 'snapshots', 's_1717000099999.json');
    expect(fs.existsSync(file)).toBe(true);
  });
});

describe('pinscope() history dev-server route (R-15-07, §8.6)', () => {
  const tmpRoots: string[] = [];
  afterEach(() => {
    for (const root of tmpRoots.splice(0)) {
      fs.rmSync(root, { recursive: true, force: true });
    }
  });

  /** Wire up the configureServer hook and return the registered middleware. */
  async function middlewareFor(root: string): Promise<FakeMiddleware> {
    const p = pinscope({ enabled: true });
    const configureServer = p.configureServer;
    expect(configureServer).toBeDefined();
    let captured: FakeMiddleware | null = null;
    const server: FakeServer = {
      config: { root },
      middlewares: {
        use(fn): void {
          captured = fn;
        },
      },
    };
    const hook =
      typeof configureServer === 'function'
        ? configureServer
        : configureServer?.handler;
    await (hook as (s: FakeServer) => void)(server);
    expect(captured).not.toBeNull();
    return captured as FakeMiddleware;
  }

  it('writes the posted command history to .pinscope/history.json', async () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pinscope-hist-'));
    tmpRoots.push(root);
    const mw = await middlewareFor(root);

    const body = JSON.stringify({
      version: '1.0',
      entries: [
        { timestamp: 't0', raw_input: 'e_1.bg → red', parsed: null, result: 'sent' },
      ],
    });
    const result = await postThrough(mw, '/__pinscope/history', body);
    expect(result.status).toBe(200);

    // F-16-06 — the HTTP response body carries the `{ ok: true, count }`
    // success flag (kills mutant M5: `ok: true → false`).
    const response = JSON.parse(result.body) as { ok: boolean; count: number };
    expect(response.ok).toBe(true);
    expect(response.count).toBe(1);

    const file = path.join(root, '.pinscope', 'history.json');
    expect(fs.existsSync(file)).toBe(true);
    const written = JSON.parse(fs.readFileSync(file, 'utf8')) as {
      entries: { raw_input: string }[];
    };
    expect(written.entries).toHaveLength(1);
    expect(written.entries[0]?.raw_input).toBe('e_1.bg → red');
  });

  it('caps the persisted history at the last 1000 entries', async () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'pinscope-hist-'));
    tmpRoots.push(root);
    const mw = await middlewareFor(root);

    const entries = Array.from({ length: 1200 }, (_v, i) => ({
      timestamp: `t${i}`,
      raw_input: `cmd_${i}`,
      parsed: null,
      result: 'sent' as const,
    }));
    const result = await postThrough(
      mw,
      '/__pinscope/history',
      JSON.stringify({ version: '1.0', entries }),
    );
    expect(result.status).toBe(200);

    // F-16-06 — the response body's `{ ok, count }` reflects the capped count
    // (kills mutant M5: `ok: true → false`).
    const response = JSON.parse(result.body) as { ok: boolean; count: number };
    expect(response.ok).toBe(true);
    expect(response.count).toBe(1000);

    const file = path.join(root, '.pinscope', 'history.json');
    const written = JSON.parse(fs.readFileSync(file, 'utf8')) as {
      entries: { raw_input: string }[];
    };
    // §8.6 — "History persisted to `.pinscope/history.json` (last 1000)".
    expect(written.entries).toHaveLength(1000);
    expect(written.entries[0]?.raw_input).toBe('cmd_200');
    expect(written.entries[999]?.raw_input).toBe('cmd_1199');
  });
});

