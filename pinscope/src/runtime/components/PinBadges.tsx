/** Pin badge layer — CSS-only path (see SPEC §7.2). */

import type { ReactElement } from 'react';
import { badgeCss } from '../styles/badges.css.js';

/**
 * Injects the CSS-only pin badge styles. Every `[data-pin]` element gets a
 * label via `::before`. The JS-overlay path for void elements (img, input)
 * is deferred (SPEC §7.2, AC-024).
 */
export function PinBadges(): ReactElement {
  return <style data-pinscope-badges="">{badgeCss}</style>;
}
