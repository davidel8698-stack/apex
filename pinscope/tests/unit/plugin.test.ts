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

/** Minimal fake of a connect-style middleware server. */
interface FakeMiddleware {
  (req: unknown, res: unknown, next: () => void): void;
}
interface FakeServer {
  middlewares: { use(fn: FakeMiddleware): void };
  config: { root: string };
}

/** Drive a POST request body through a middleware and await the response. */
function postThrough(
  mw: FakeMiddleware,
  url: string,
  body: string,
): Promise<{ status: number }> {
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
      end(): void {
        status = res.statusCode;
        resolve({ status });
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

    const file = path.join(root, '.pinscope', 'snapshots', 's_1717000000000.json');
    expect(fs.existsSync(file)).toBe(true);
    const written = JSON.parse(fs.readFileSync(file, 'utf8')) as { id: string };
    expect(written.id).toBe('s_1717000000000');
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
