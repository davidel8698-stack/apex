/** Production stripper — removes `data-pin` attributes from HTML (SPEC §6.1). */

const DATA_PIN_ATTR = /\sdata-pin="[^"]*"/g;

/**
 * Remove every `data-pin="…"` attribute from an HTML string. Used by the
 * plugin's `transformIndexHtml` hook when PinScope is disabled, guaranteeing
 * zero PinScope artifacts reach a production build.
 */
export function stripPins(html: string): string {
  return html.replace(DATA_PIN_ATTR, '');
}
