/** Floating HUD re-open button — see SPEC §7.1. */

import type { CSSProperties, ReactElement } from 'react';
import { Z_SELECTED } from '../constants.js';

export interface FloatingToggleProps {
  /** Re-show the HUD. */
  onShow: () => void;
}

/**
 * The single control rendered while the HUD is hidden (§7.1). Clicking it
 * re-shows the full HUD tree.
 */
export function FloatingToggle({ onShow }: FloatingToggleProps): ReactElement {
  const style: CSSProperties = {
    position: 'fixed',
    bottom: 16,
    right: 16,
    width: 36,
    height: 36,
    borderRadius: '50%',
    border: 'none',
    background: 'rgba(59, 130, 246, 0.95)',
    color: '#fff',
    font: '600 12px ui-monospace, monospace',
    cursor: 'pointer',
    zIndex: Z_SELECTED,
  };
  return (
    <button
      type="button"
      data-pinscope-toggle=""
      aria-label="Show PinScope HUD"
      onClick={onShow}
      style={style}
    >
      PS
    </button>
  );
}
