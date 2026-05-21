/** Global state-override panel — see SPEC §8.8. */

import { useState } from 'react';
import type { ReactElement } from 'react';

export type StateOverride = 'none' | 'hover' | 'focus' | 'active';

const STATES: readonly StateOverride[] = ['none', 'hover', 'focus', 'active'];

/** Force (or clear) a global interaction state via `<html data-state-override>`. */
export function applyStateOverride(state: StateOverride): void {
  if (typeof document === 'undefined') return;
  const html = document.documentElement;
  if (state === 'none') html.removeAttribute('data-state-override');
  else html.setAttribute('data-state-override', state);
}

export function StatePanel(): ReactElement {
  const [state, setState] = useState<StateOverride>('none');
  const choose = (next: StateOverride): void => {
    setState(next);
    applyStateOverride(next);
  };
  return (
    <div data-pinscope-state="">
      {STATES.map((s) => (
        <button
          key={s}
          type="button"
          data-state-btn={s}
          aria-pressed={state === s}
          onClick={() => choose(s)}
        >
          {s}
        </button>
      ))}
    </div>
  );
}
