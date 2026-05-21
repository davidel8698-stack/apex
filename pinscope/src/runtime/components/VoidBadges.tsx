/** JS-overlay badges for void elements — see SPEC §7.2. */

import { useEffect, useState } from 'react';
import type { ReactElement } from 'react';
import { PIN_ATTR, Z_BADGE } from '../constants.js';

/** Void elements cannot carry a CSS `::before`, so they get a JS overlay. */
const VOID_TAGS = new Set(['IMG', 'INPUT', 'BR', 'HR', 'AREA', 'EMBED']);

interface VoidBadge {
  pinId: string;
  x: number;
  y: number;
}

function collect(): VoidBadge[] {
  const badges: VoidBadge[] = [];
  for (const el of Array.from(document.querySelectorAll(`[${PIN_ATTR}]`))) {
    if (!VOID_TAGS.has(el.tagName)) continue;
    const pinId = el.getAttribute(PIN_ATTR);
    if (!pinId) continue;
    const rect = el.getBoundingClientRect();
    badges.push({ pinId, x: rect.left, y: rect.top });
  }
  return badges;
}

export function VoidBadges(): ReactElement {
  const [badges, setBadges] = useState<VoidBadge[]>([]);
  useEffect(() => {
    setBadges(collect());
  }, []);

  return (
    <div data-pinscope-void-badges="">
      {badges.map((badge) => (
        <div
          key={badge.pinId}
          data-void-badge={badge.pinId}
          style={{
            position: 'fixed',
            left: badge.x,
            top: badge.y,
            zIndex: Z_BADGE,
            background: 'rgba(59, 130, 246, 0.92)',
            color: '#fff',
            font: '10px/1.2 ui-monospace, monospace',
            padding: '1px 4px',
            pointerEvents: 'none',
          }}
        >
          {badge.pinId}
        </div>
      ))}
    </div>
  );
}
