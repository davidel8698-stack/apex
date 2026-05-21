/** Screenshot capture — see SPEC §4 + resolution I-4. */

export interface ScreenshotOptions {
  backgroundColor?: string | null;
}

/**
 * Capture an element as a PNG data URL.
 *
 * `html2canvas` is imported **dynamically** so it never enters the initial
 * PinScope bundle — it loads only when a screenshot is actually requested
 * (AC-076 / resolution I-4).
 */
export async function captureScreenshot(
  element: HTMLElement,
  options: ScreenshotOptions = {},
): Promise<string> {
  const { default: html2canvas } = await import('html2canvas');
  const canvas = await html2canvas(element, {
    backgroundColor: options.backgroundColor ?? null,
    logging: false,
  });
  return canvas.toDataURL('image/png');
}
