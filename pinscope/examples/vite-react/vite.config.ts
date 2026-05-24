import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { defineConfig } from 'vite';
import { pinscope } from '../../dist/plugin/index.js';

const here = path.dirname(fileURLToPath(import.meta.url));

// PinScope's Vite plugin injects `data-pin` in development; in a production
// build it is disabled, so this app ships zero PinScope bytes (see AC-010).
export default defineConfig({
  root: here,
  plugins: [pinscope()],
  esbuild: { jsx: 'automatic', jsxImportSource: 'react' },
  resolve: {
    alias: {
      'pinscope/runtime': path.resolve(here, '../../dist/runtime/PinScope.js'),
    },
  },
  build: {
    outDir: path.resolve(here, 'dist'),
    emptyOutDir: true,
  },
});
