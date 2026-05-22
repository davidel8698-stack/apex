/** Global state-override panel — see SPEC §8.8. */

import { useState } from 'react';
import type { ReactElement } from 'react';

export type StateOverride = 'none' | 'hover' | 'focus' | 'active';

const STATES: readonly StateOverride[] = ['none', 'hover', 'focus', 'active'];

/** The pseudo-classes §8.8 forces; `none` is excluded. */
const PSEUDO: Record<Exclude<StateOverride, 'none'>, string> = {
  hover: ':hover',
  focus: ':focus',
  active: ':active',
};

const RULES_ATTR = 'data-pinscope-state-rules';

/**
 * Scan `document.styleSheets` for rules whose selector contains the forced
 * pseudo-class and synthesize parallel rules scoped under
 * `[data-state-override="<state>"]` with the pseudo-class stripped — so the
 * forced state takes effect on a host whose CSS does not itself key off the
 * `[data-state-override]` attribute (SPEC §8.8).
 *
 * Cross-origin sheets throw `SecurityError` on `cssRules` access; each sheet
 * read is guarded so one inaccessible sheet never aborts the scan.
 */
function generateOverrideRules(state: Exclude<StateOverride, 'none'>): string {
  if (typeof document === 'undefined') return '';
  const pseudo = PSEUDO[state];
  const scope = `[data-state-override="${state}"]`;
  const generated: string[] = [];

  for (const sheet of Array.from(document.styleSheets)) {
    let rules: CSSRuleList;
    try {
      rules = sheet.cssRules;
    } catch {
      // Cross-origin / inaccessible stylesheet — skip, never abort the scan.
      continue;
    }
    for (const rule of Array.from(rules)) {
      // Restrict to top-level style rules — never recurse into @import /
      // @media so the scan cannot loop on nested rule trees.
      if (!(rule instanceof CSSStyleRule)) continue;
      const selector = rule.selectorText;
      if (!selector.includes(pseudo)) continue;
      // Strip the pseudo-class and re-scope under the override attribute.
      const stripped = selector.split(',').map((part) => {
        const trimmed = part.trim();
        if (!trimmed.includes(pseudo)) return null;
        return `${scope} ${trimmed.split(pseudo).join('')}`;
      });
      const scopedSelector = stripped.filter((s): s is string => s !== null);
      if (scopedSelector.length === 0) continue;
      const body = rule.style.cssText;
      generated.push(`${scopedSelector.join(', ')} { ${body} }`);
    }
  }
  return generated.join('\n');
}

/** Ensure the dedicated `<style>` element for generated rules exists. */
function ensureRulesElement(): HTMLStyleElement {
  let el = document.querySelector(`[${RULES_ATTR}]`) as HTMLStyleElement | null;
  if (!el) {
    el = document.createElement('style');
    el.setAttribute(RULES_ATTR, '');
    document.head.appendChild(el);
  }
  return el;
}

/** Force (or clear) a global interaction state via `<html data-state-override>`. */
export function applyStateOverride(state: StateOverride): void {
  if (typeof document === 'undefined') return;
  const html = document.documentElement;
  if (state === 'none') {
    html.removeAttribute('data-state-override');
    // Clear any previously generated override rules.
    const el = document.querySelector(`[${RULES_ATTR}]`);
    if (el) el.textContent = '';
    return;
  }
  html.setAttribute('data-state-override', state);
  // Synthesize the override rules so the forced state visibly applies even on
  // a host whose CSS does not key off `[data-state-override]`.
  ensureRulesElement().textContent = generateOverrideRules(state);
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
