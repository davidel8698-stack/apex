/** Hover/selection inspector panel — see SPEC §8.1. */

import { useState } from 'react';
import type { CSSProperties, ReactElement, ReactNode } from 'react';
import type { HoveredElement } from '../../types/element-info.js';
import { PIN_ATTR, Z_SELECTED } from '../constants.js';
import { isShadowLimited } from '../utils/shadow-dom.js';

export interface InfoPanelProps {
  hovered: HoveredElement | null;
  position?: 'left' | 'right';
}

/** Format a pixel value: integer when whole, one decimal otherwise. */
function px(n: number): string {
  return Number.isInteger(n) ? `${n}px` : `${n.toFixed(1)}px`;
}

const STORAGE_PREFIX = 'pinscope:section:';

function readCollapsed(id: string): boolean {
  if (typeof localStorage === 'undefined') return false;
  return localStorage.getItem(STORAGE_PREFIX + id) === '1';
}

function writeCollapsed(id: string, collapsed: boolean): void {
  if (typeof localStorage === 'undefined') return;
  localStorage.setItem(STORAGE_PREFIX + id, collapsed ? '1' : '0');
}

/** A section whose collapsed state persists to `localStorage` (AC-032). */
function CollapsibleSection({
  id,
  title,
  children,
}: {
  id: string;
  title: string;
  children: ReactNode;
}): ReactElement {
  const [collapsed, setCollapsed] = useState<boolean>(() => readCollapsed(id));
  const toggle = (): void => {
    setCollapsed((prev) => {
      const next = !prev;
      writeCollapsed(id, next);
      return next;
    });
  };
  return (
    <section data-section={id} data-testid={id} data-collapsed={collapsed}>
      <button
        type="button"
        data-section-toggle={id}
        onClick={toggle}
        style={{
          width: '100%',
          textAlign: 'left',
          background: 'none',
          border: 'none',
          color: 'inherit',
          font: 'inherit',
          cursor: 'pointer',
          padding: '4px 0',
        }}
      >
        {collapsed ? '▸' : '▾'} {title}
      </button>
      {!collapsed && <div data-section-body={id}>{children}</div>}
    </section>
  );
}

function isColorValue(value: string): boolean {
  return (
    /^#[0-9a-f]{3,8}$/i.test(value) ||
    /^rgba?\(/i.test(value) ||
    /^hsla?\(/i.test(value)
  );
}

function isEmptyValue(value: string): boolean {
  return value === '' || value === 'none' || value === 'normal' || value === '0px';
}

/** One label/value row — color values get a swatch, empties render `—` (AC-033). */
function StyleRow({ label, value }: { label: string; value: string }): ReactElement {
  return (
    <div data-style-row={label}>
      <span>{label} </span>
      {isEmptyValue(value) ? (
        <span data-empty="">—</span>
      ) : isColorValue(value) ? (
        <span>
          <span
            data-swatch={value}
            style={{
              display: 'inline-block',
              width: 10,
              height: 10,
              background: value,
              border: '1px solid #555',
              verticalAlign: 'middle',
            }}
          />{' '}
          {value}
        </span>
      ) : (
        <span>{value}</span>
      )}
    </div>
  );
}

export function InfoPanel({
  hovered,
  position = 'right',
}: InfoPanelProps): ReactElement | null {
  if (!hovered) return null;
  const { element, pinId, rect } = hovered;
  const cs =
    typeof getComputedStyle === 'function' ? getComputedStyle(element) : null;
  const get = (prop: string): string => cs?.getPropertyValue(prop).trim() ?? '';

  const parentPin =
    element.parentElement
      ?.closest(`[${PIN_ATTR}]`)
      ?.getAttribute(PIN_ATTR) ?? '';
  const childPinCount = element.querySelectorAll(`[${PIN_ATTR}]`).length;

  const style: CSSProperties = {
    position: 'fixed',
    top: 56,
    width: 320,
    background: '#111827',
    color: '#e5e7eb',
    font: "12px/1.5 ui-monospace, 'SF Mono', Consolas, monospace",
    padding: 12,
    borderRadius: 8,
    zIndex: Z_SELECTED,
  };
  if (position === 'right') style.right = 16;
  else style.left = 16;

  // R-21-02 — §12 / AC-060 — when the hovered element is a Shadow-DOM host
  // marked by `markShadowHosts` (PinScopeHud sweep + MutationObserver), render
  // an additive "limited inspection" row above the collapsible sections so
  // the inspector reports the boundary the SPEC names. The row sits outside
  // any `CollapsibleSection` (AC-032 unaffected) and never replaces an
  // existing block (AC-033 unaffected).
  const shadowLimited = isShadowLimited(element);

  return (
    <div data-pinscope-panel="" style={style}>
      <div data-testid="pin-id">
        {pinId} · {element.tagName.toLowerCase()}
      </div>
      {shadowLimited && (
        <div data-pinscope-shadow-limited="">limited inspection</div>
      )}
      <CollapsibleSection id="dimensions" title="Dimensions">
        <StyleRow label="Width" value={px(rect.width)} />
        <StyleRow label="Height" value={px(rect.height)} />
        <StyleRow
          label="X / Y"
          value={`${Math.round(rect.x)} / ${Math.round(rect.y)}`}
        />
      </CollapsibleSection>
      <CollapsibleSection id="spacing" title="Spacing">
        <StyleRow label="Padding" value={get('padding')} />
        <StyleRow label="Margin" value={get('margin')} />
      </CollapsibleSection>
      <CollapsibleSection id="typography" title="Typography">
        <StyleRow label="Family" value={get('font-family')} />
        <StyleRow label="Size" value={get('font-size')} />
        <StyleRow label="Weight" value={get('font-weight')} />
      </CollapsibleSection>
      <CollapsibleSection id="appearance" title="Appearance">
        <StyleRow label="Color" value={get('color')} />
        <StyleRow label="Background" value={get('background-color')} />
        <StyleRow label="Border" value={get('border')} />
        <StyleRow label="Radius" value={get('border-radius')} />
        <StyleRow label="Shadow" value={get('box-shadow')} />
      </CollapsibleSection>
      <CollapsibleSection id="layout" title="Layout">
        <StyleRow label="Display" value={get('display')} />
        <StyleRow label="Position" value={get('position')} />
        <StyleRow label="Z-index" value={get('z-index')} />
      </CollapsibleSection>
      <CollapsibleSection id="hierarchy" title="Hierarchy">
        <StyleRow label="Parent" value={parentPin} />
        <StyleRow label="Children" value={String(childPinCount)} />
      </CollapsibleSection>
    </div>
  );
}
