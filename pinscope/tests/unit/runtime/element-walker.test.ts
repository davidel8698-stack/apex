import { describe, it, expect, afterEach } from 'vitest';
import {
  escapeHud,
  findPinnedAncestor,
} from '../../../src/runtime/utils/element-walker.js';

afterEach(() => {
  document.body.innerHTML = '';
});

function mount(html: string): HTMLElement {
  const root = document.createElement('div');
  root.innerHTML = html;
  document.body.appendChild(root);
  return root;
}

describe('findPinnedAncestor (AC-026)', () => {
  it('returns the element itself when it carries data-pin', () => {
    const root = mount('<button data-pin="e_1">go</button>');
    const btn = root.querySelector('button') as HTMLElement;
    expect(findPinnedAncestor(btn)).toBe(btn);
  });

  it('walks up to the nearest pinned ancestor', () => {
    const root = mount(
      '<button data-pin="e_2"><span><i>x</i></span></button>',
    );
    const inner = root.querySelector('i') as HTMLElement;
    const btn = root.querySelector('button') as HTMLElement;
    expect(findPinnedAncestor(inner)).toBe(btn);
  });

  it('returns null when no ancestor is pinned', () => {
    const root = mount('<div><span>x</span></div>');
    expect(findPinnedAncestor(root.querySelector('span'))).toBeNull();
  });

  it('returns null for a null input', () => {
    expect(findPinnedAncestor(null)).toBeNull();
  });
});

describe('escapeHud (AC-027)', () => {
  it('returns an element outside the HUD unchanged', () => {
    const root = mount('<div data-pin="e_3">x</div>');
    const div = root.querySelector('div[data-pin]') as HTMLElement;
    expect(escapeHud(div)).toBe(div);
  });

  it('walks out of the PinScope HUD subtree', () => {
    mount(
      '<div data-pinscope-ui="root"><button data-pin="e_4">x</button></div>',
    );
    const btn = document.querySelector('button') as HTMLElement;
    const escaped = escapeHud(btn);
    expect(escaped).not.toBeNull();
    expect(escaped?.closest('[data-pinscope-ui]')).toBeNull();
  });

  it('returns null for a null input', () => {
    expect(escapeHud(null)).toBeNull();
  });
});
