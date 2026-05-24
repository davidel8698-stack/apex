import { describe, it, expect, afterEach } from 'vitest';
import { RuntimePinObserver } from '../../../src/runtime/managers/RuntimePinObserver.js';
import {
  markShadowHosts,
  isShadowLimited,
} from '../../../src/runtime/utils/shadow-dom.js';

afterEach(() => {
  document.body.innerHTML = '';
});

describe('RuntimePinObserver (AC-025)', () => {
  it('assigns e_r ids to an element and its descendants', () => {
    const observer = new RuntimePinObserver();
    const el = document.createElement('div');
    el.innerHTML = '<span></span>';
    observer.assign(el);
    expect(el.getAttribute('data-pin')).toMatch(/^e_r\d+$/);
    expect(el.querySelector('span')?.getAttribute('data-pin')).toMatch(
      /^e_r\d+$/,
    );
  });

  it('never overwrites an existing build-time pin', () => {
    const observer = new RuntimePinObserver();
    const el = document.createElement('div');
    el.setAttribute('data-pin', 'e_5');
    observer.assign(el);
    expect(el.getAttribute('data-pin')).toBe('e_5');
  });

  it('assigns e_r ids to elements added at runtime', async () => {
    const observer = new RuntimePinObserver();
    observer.start(document.body);
    const added = document.createElement('button');
    document.body.appendChild(added);
    await new Promise((resolve) => setTimeout(resolve, 50));
    observer.stop();
    expect(added.getAttribute('data-pin')).toMatch(/^e_r\d+$/);
  });
});

describe('Shadow DOM marking (AC-060)', () => {
  it('marks shadow hosts with data-pin-shadow', () => {
    const host = document.createElement('div');
    host.attachShadow({ mode: 'open' });
    document.body.appendChild(host);
    const count = markShadowHosts(document);
    expect(count).toBe(1);
    expect(host.hasAttribute('data-pin-shadow')).toBe(true);
    expect(isShadowLimited(host)).toBe(true);
  });

  it('reports a plain element as not shadow-limited', () => {
    const el = document.createElement('div');
    document.body.appendChild(el);
    markShadowHosts(document);
    expect(isShadowLimited(el)).toBe(false);
  });
});
