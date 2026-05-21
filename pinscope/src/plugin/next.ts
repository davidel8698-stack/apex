/** Next.js integration — see SPEC §15. */

import type { PinScopeOptions } from './index.js';

/** Minimal structural type for a Next.js config object. */
export interface NextConfig {
  webpack?: (config: unknown, context: unknown) => unknown;
  [key: string]: unknown;
}

/**
 * Wrap a Next.js config so PinScope instruments the app in development.
 * Returns a new config object; the input is never mutated. When PinScope is
 * disabled (production) the config is returned unchanged.
 */
export function withPinScope(
  nextConfig: NextConfig = {},
  options: PinScopeOptions = {},
): NextConfig {
  const enabled = options.enabled ?? process.env['NODE_ENV'] !== 'production';
  if (!enabled) {
    return { ...nextConfig };
  }
  return {
    ...nextConfig,
    webpack(config: unknown, context: unknown): unknown {
      // Compose any webpack function the host config already defined.
      // Dev-only: a later round registers the data-pin loader here.
      return typeof nextConfig.webpack === 'function'
        ? nextConfig.webpack(config, context)
        : config;
    },
  };
}
