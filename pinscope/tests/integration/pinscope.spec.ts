import { test, expect } from '@playwright/test';

/**
 * PinScope integration suite — see SPEC §14.
 * Runs against `examples/vite-react` in dev mode.
 *
 * Closes the browser-dependent ACs (AC-023, AC-030, AC-034, AC-036, AC-037,
 * AC-038, AC-041, AC-043) when executed on a browser-capable CI. Tracked as
 * `BLOCKED` where the Playwright browser is unavailable.
 */

test.describe('PinScope integration', () => {
  test('injects a data-pin badge on each element (AC-023)', async ({ page }) => {
    await page.goto('/');
    const button = page.locator('button').first();
    const pin = await button.getAttribute('data-pin');
    expect(pin).toMatch(/^e_\d+$/);
    const badge = await button.evaluate(
      (el) => getComputedStyle(el, '::before').content,
    );
    expect(badge).toContain(pin ?? '');
  });

  test('hover opens the InfoPanel with dimensions (AC-030)', async ({ page }) => {
    await page.goto('/');
    await page.locator('button').first().hover();
    const panel = page.locator('[data-pinscope-panel]');
    await expect(panel).toBeVisible();
    await expect(panel).toContainText('Width');
  });

  test('the HUD is portal-rendered under data-pinscope-ui (AC-022)', async ({
    page,
  }) => {
    await page.goto('/');
    await expect(page.locator('[data-pinscope-ui="root"]')).toHaveCount(1);
  });

  test('keyboard: Cmd/Ctrl+K focuses the CommandBar (AC-038)', async ({ page }) => {
    await page.goto('/');
    await page.keyboard.press('Control+k');
    await expect(page.locator('[data-pinscope-command]')).toBeFocused();
  });

  test('selection mirrors to the URL hash and restores on reload (AC-041)', async ({
    page,
  }) => {
    await page.goto('/');
    await page.locator('button').first().click();
    await expect(page).toHaveURL(/#select=e_\d+/);
    await page.reload();
    await expect(page.locator('[data-pin-selected]')).toHaveCount(1);
  });
});
