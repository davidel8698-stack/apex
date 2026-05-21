import { defineConfig } from '@playwright/test';

/**
 * Playwright integration suite — see SPEC §14.
 *
 * NOTE: this suite requires a browser binary. In environments where the
 * Playwright browser download is blocked it cannot run; the affected
 * acceptance criteria are tracked as `BLOCKED` in `convergence/STATUS.md`.
 * It is a real deliverable for a browser-capable CI.
 */
export default defineConfig({
  testDir: './tests/integration',
  timeout: 30_000,
  use: {
    baseURL: 'http://localhost:5173',
  },
  webServer: {
    command: 'npm --prefix examples/vite-react run dev -- --port 5173',
    url: 'http://localhost:5173',
    reuseExistingServer: true,
    timeout: 60_000,
  },
});
