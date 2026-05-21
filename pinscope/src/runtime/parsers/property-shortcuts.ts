/** Shortcut property resolution — see SPEC §11. */

const SHORTCUTS: Record<string, string> = {
  'padding-y': 'padding-block',
  'padding-x': 'padding-inline',
  'margin-y': 'margin-block',
  'margin-x': 'margin-inline',
  bg: 'background-color',
  fg: 'color',
  radius: 'border-radius',
  weight: 'font-weight',
  size: 'font-size',
  shadow: 'box-shadow',
};

/** Resolve a shortcut property to its CSS equivalent; pass through unknowns. */
export function resolveProperty(name: string): string {
  return SHORTCUTS[name] ?? name;
}

/** The full list of shortcut property names. */
export const SHORTCUT_PROPERTIES: readonly string[] = Object.keys(SHORTCUTS);
