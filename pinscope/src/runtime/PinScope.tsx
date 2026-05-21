/** PinScope root component — see SPEC §7.1. */

import type { ReactElement } from 'react';
import { createPortal } from 'react-dom';
import { PinBadges } from './components/PinBadges.js';
import { InfoPanel } from './components/InfoPanel.js';
import { useHoveredElement } from './hooks/useHoveredElement.js';

export interface PinScopeProps {
  /** Runtime kill-switch. */
  enabled?: boolean;
  /** Which side the InfoPanel docks to. */
  hudPosition?: 'left' | 'right';
}

/**
 * PS-R2 scope: mounts the inspection layer (PinBadges + InfoPanel). The
 * measurement, control and state layers are added by later rounds.
 */
export function PinScope(props: PinScopeProps = {}): ReactElement | null {
  // Guard production: PinScope never ships to a production build.
  if (process.env.NODE_ENV === 'production') return null;
  if (props.enabled === false) return null;
  return <PinScopeHud hudPosition={props.hudPosition ?? 'right'} />;
}

function PinScopeHud({
  hudPosition,
}: {
  hudPosition: 'left' | 'right';
}): ReactElement | null {
  const hovered = useHoveredElement();
  if (typeof document === 'undefined') return null;
  return createPortal(
    <div data-pinscope-ui="root">
      <PinBadges />
      <InfoPanel hovered={hovered} position={hudPosition} />
    </div>,
    document.body,
  );
}
