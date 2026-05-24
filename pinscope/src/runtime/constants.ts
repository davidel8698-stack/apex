/** Shared runtime constants. */

/** Attribute marking the PinScope HUD subtree (excluded from inspection). */
export const HUD_ROOT_ATTR = 'data-pinscope-ui';

/** Attribute carrying a Pin id on an inspected element. */
export const PIN_ATTR = 'data-pin';

/** Attribute marking the currently selected pinned element. */
export const SELECTED_ATTR = 'data-pin-selected';

/** Reserved z-index range — see SPEC §12.6 (max 32-bit signed int). */
export const Z_BADGE = 2147483645;
export const Z_HOVER = 2147483646;
export const Z_SELECTED = 2147483647;
