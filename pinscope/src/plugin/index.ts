/** PinScope Vite plugin entry — see SPEC.md §6.1, §10-D. */

import * as fs from 'node:fs';
import * as path from 'node:path';
import type { Plugin } from 'vite';
import { transformJSX } from './ast-transformer.js';
import { PinMap } from './pin-map.js';
import { stripPins } from './production-stripper.js';

/** Dev-server route through which the runtime persists a snapshot (§10-D). */
const SNAPSHOT_ROUTE = '/__pinscope/snapshot';

/** Structural shapes the snapshot middleware relies on (avoids a Vite dep). */
interface SnapshotReq {
  url?: string;
  method?: string;
  on(event: 'data', cb: (chunk: Buffer) => void): void;
  on(event: 'end', cb: () => void): void;
  on(event: 'error', cb: (err: Error) => void): void;
}
interface SnapshotRes {
  statusCode: number;
  setHeader(name: string, value: string): void;
  end(body?: string): void;
}

/**
 * Read a request body, write the snapshot JSON to `.pinscope/snapshots/`, and
 * answer the request. The filename is derived from `snapshot.id` (`s_<digits>`)
 * — never from untrusted input — so a hostile body cannot traverse the path.
 */
function handleSnapshotRequest(
  req: SnapshotReq,
  res: SnapshotRes,
  projectRoot: string,
): void {
  const chunks: Buffer[] = [];
  req.on('data', (chunk) => chunks.push(chunk));
  req.on('error', () => {
    res.statusCode = 400;
    res.end('snapshot request stream error');
  });
  req.on('end', () => {
    try {
      const raw = Buffer.concat(chunks).toString('utf8');
      const snapshot = JSON.parse(raw) as { id?: unknown };
      const id = typeof snapshot.id === 'string' ? snapshot.id : '';
      // Path-traversal guard: the id must be a bare `s_<digits>` token.
      if (!/^s_\d+$/.test(id)) {
        res.statusCode = 400;
        res.end('snapshot id missing or malformed');
        return;
      }
      const dir = path.join(projectRoot, '.pinscope', 'snapshots');
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(path.join(dir, `${id}.json`), raw, 'utf8');
      res.statusCode = 200;
      res.setHeader('content-type', 'application/json');
      res.end(JSON.stringify({ ok: true, id }));
    } catch {
      res.statusCode = 400;
      res.end('snapshot body is not valid JSON');
    }
  });
}

export interface PinScopeOptions {
  /** Default: `process.env.NODE_ENV !== 'production'`. */
  enabled?: boolean;
  /** Default: `/\.(jsx|tsx)$/`. */
  filePattern?: RegExp;
  /** Default: `/node_modules|\.test\./`. */
  excludePattern?: RegExp;
  /** Default: `.pinmap.json`. */
  pinMapPath?: string;
  /** Default: `true`. */
  stripInProduction?: boolean;
  /** Default: `['Fragment', 'Suspense']`. */
  excludeTags?: string[];
}

interface ResolvedOptions {
  enabled: boolean;
  filePattern: RegExp;
  excludePattern: RegExp;
  pinMapPath: string;
  stripInProduction: boolean;
  excludeTags: string[];
}

function resolveOptions(options: PinScopeOptions): ResolvedOptions {
  return {
    enabled: options.enabled ?? process.env['NODE_ENV'] !== 'production',
    filePattern: options.filePattern ?? /\.(jsx|tsx)$/,
    excludePattern: options.excludePattern ?? /node_modules|\.test\./,
    pinMapPath: options.pinMapPath ?? '.pinmap.json',
    stripInProduction: options.stripInProduction ?? true,
    excludeTags: options.excludeTags ?? ['Fragment', 'Suspense'],
  };
}

/**
 * Vite plugin that injects a stable `data-pin` attribute into every eligible
 * JSX element at build time.
 */
export function pinscope(options: PinScopeOptions = {}): Plugin {
  const opts = resolveOptions(options);
  const pinMap = new PinMap(opts.pinMapPath);

  return {
    name: 'vite-plugin-pinscope',
    enforce: 'pre',

    buildStart() {
      pinMap.load();
    },

    configureServer(server) {
      // §10-D: register the dev-server endpoint that persists snapshots to
      // `.pinscope/snapshots/`. The `node:fs` write lives only here — the
      // browser runtime stays `fs`-free.
      const projectRoot = server.config.root;
      server.middlewares.use((req, res, next) => {
        const url = (req as { url?: string }).url ?? '';
        const method = (req as { method?: string }).method ?? '';
        if (method === 'POST' && url.split('?')[0] === SNAPSHOT_ROUTE) {
          handleSnapshotRequest(
            req as unknown as SnapshotReq,
            res as unknown as SnapshotRes,
            projectRoot,
          );
          return;
        }
        next();
      });
    },

    transform(code, id) {
      if (!opts.enabled) return null;
      if (!opts.filePattern.test(id)) return null;
      if (opts.excludePattern.test(id)) return null;
      return transformJSX(code, id, pinMap, {
        excludeTags: opts.excludeTags,
      });
    },

    buildEnd() {
      pinMap.reconcile();
      pinMap.save();
    },

    transformIndexHtml(html) {
      if (opts.enabled || !opts.stripInProduction) return html;
      return stripPins(html);
    },
  };
}
