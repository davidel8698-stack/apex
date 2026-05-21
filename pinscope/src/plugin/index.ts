/** PinScope Vite plugin entry — see SPEC.md §6.1. */

import type { Plugin } from 'vite';
import { transformJSX } from './ast-transformer.js';
import { PinMap } from './pin-map.js';
import { stripPins } from './production-stripper.js';

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
