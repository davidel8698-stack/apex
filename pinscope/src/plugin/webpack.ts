/** Webpack integration — see SPEC §15. */

import type { PinScopeOptions } from './index.js';

/** Minimal structural type for a webpack compiler. */
export interface WebpackCompiler {
  hooks: Record<string, unknown>;
}

/**
 * Webpack plugin that instruments an app with PinScope in development.
 * A no-op when PinScope is disabled (production).
 */
export class PinScopeWebpackPlugin {
  readonly options: PinScopeOptions;

  constructor(options: PinScopeOptions = {}) {
    this.options = options;
  }

  apply(compiler: WebpackCompiler): void {
    const enabled =
      this.options.enabled ?? process.env['NODE_ENV'] !== 'production';
    if (!enabled) return;
    // Dev-only: a later round taps `compiler.hooks` to register the loader.
    void compiler.hooks;
  }
}
