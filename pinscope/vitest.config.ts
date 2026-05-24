import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['tests/unit/**/*.test.{ts,tsx}'],
    // Build-module tests run in node; runtime tests need a DOM.
    environment: 'node',
    environmentMatchGlobs: [['tests/unit/runtime/**', 'happy-dom']],
  },
});
