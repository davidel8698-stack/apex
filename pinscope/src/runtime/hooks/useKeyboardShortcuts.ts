/** Keyboard shortcut dispatch — see SPEC §8.11. */

import { useEffect, useRef } from 'react';

// R-23-05 — `'command'` (Cmd+K) and `'escape'` were removed from the
// dispatcher table because they are owned by `CommandBar.tsx` and
// `useSelectedElement.ts` directly (Cmd+K focuses CommandBar; Escape
// blurs CommandBar / clears selection). They are SPEC §8.11 user-facing
// shortcuts but are NOT serviced by this dispatcher.
export type ShortcutId =
  | 'grid-cycle'
  | 'grid-0'
  | 'grid-1'
  | 'grid-2'
  | 'grid-3'
  | 'grid-4'
  | 'toggle-hud'
  | 'toggle-pins'
  | 'measure'
  | 'snapshot'
  | 'crosshair';

interface ShortcutDef {
  key: string;
  shift?: boolean;
  meta?: boolean;
}

export const SHORTCUTS: Record<ShortcutId, ShortcutDef> = {
  'grid-cycle': { key: 'g', shift: true },
  'grid-0': { key: '0', shift: true },
  'grid-1': { key: '1', shift: true },
  'grid-2': { key: '2', shift: true },
  'grid-3': { key: '3', shift: true },
  'grid-4': { key: '4', shift: true },
  'toggle-hud': { key: 'h', shift: true },
  'toggle-pins': { key: 'p', shift: true },
  measure: { key: 'm', shift: true },
  snapshot: { key: 's', shift: true },
  crosshair: { key: 'c', shift: true },
};

export interface KeyLike {
  key: string;
  shiftKey: boolean;
  metaKey: boolean;
  ctrlKey: boolean;
}

/** Resolve a keyboard event to a shortcut id, or null. */
export function matchShortcut(e: KeyLike): ShortcutId | null {
  const key = e.key.toLowerCase();
  const entries = Object.entries(SHORTCUTS) as [ShortcutId, ShortcutDef][];
  for (const [id, def] of entries) {
    if (def.key !== key) continue;
    if ((def.shift ?? false) !== e.shiftKey) continue;
    if ((def.meta ?? false) !== (e.metaKey || e.ctrlKey)) continue;
    return id;
  }
  return null;
}

export type ShortcutHandlers = Partial<Record<ShortcutId, () => void>>;

/** Bind the §8.11 shortcut table to handlers on `document`. */
export function useKeyboardShortcuts(handlers: ShortcutHandlers): void {
  const ref = useRef(handlers);
  ref.current = handlers;
  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      const id = matchShortcut(e);
      const handler = id ? ref.current[id] : undefined;
      if (handler) {
        e.preventDefault();
        handler();
      }
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, []);
}
