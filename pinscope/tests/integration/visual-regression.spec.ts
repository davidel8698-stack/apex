import { test, expect } from '@playwright/test';

/**
 * PinScope visual-regression suite — see SPEC §14.
 *
 * NOTE: this suite requires a browser binary. In environments where the
 * Playwright browser download is blocked it cannot run; the affected
 * acceptance criteria are tracked as `BLOCKED` in `convergence/STATUS.md`.
 * It is a real deliverable for a browser-capable CI, which runs it across the
 * §14 matrix (Chrome/Firefox/Safari via `playwright.config.ts` projects,
 * 4 viewports, light/dark, with/without a host CSS framework).
 */

const viewports = [
  { name: 'mobile', width: 375, height: 667 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'laptop', width: 1280, height: 800 },
  { name: 'desktop', width: 1920, height: 1080 },
];

const themes = ['light', 'dark'] as const;

const hostCss = [true, false];

test.describe('PinScope visual regression (AC-083)', () => {
  for (const viewport of viewports) {
    for (const theme of themes) {
      for (const hasHostCss of hostCss) {
        const cssArm = hasHostCss ? 'host-css' : 'no-host-css';
        test(`HUD — ${viewport.name} / ${theme} / ${cssArm}`, async ({
          page,
        }) => {
          page.setViewportSize({
            width: viewport.width,
            height: viewport.height,
          });
          await page.emulateMedia({ colorScheme: theme });
          await page.goto(hasHostCss ? '/?hostCss=1' : '/');

          await expect(page).toHaveScreenshot([
            'hud',
            viewport.name,
            theme,
            cssArm,
            'baseline.png',
          ]);

          await page.locator('button').first().hover();
          await expect(page).toHaveScreenshot([
            'hud',
            viewport.name,
            theme,
            cssArm,
            'infopanel-open.png',
          ]);
        });
      }
    }
  }
});
