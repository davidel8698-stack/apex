import { describe, it, expect, afterEach, vi } from 'vitest';
import { render, cleanup, fireEvent } from '@testing-library/react';
import { TopBar } from '../../../src/runtime/components/TopBar.js';
import { StatePanel } from '../../../src/runtime/components/StatePanel.js';
import { CommandBar } from '../../../src/runtime/components/CommandBar.js';
import { Crosshair } from '../../../src/runtime/components/Crosshair.js';
import { applyStateOverride } from '../../../src/runtime/components/StatePanel.js';
import { PinScope } from '../../../src/runtime/PinScope.js';
import {
  HistoryManager,
  MemoryHistoryStore,
} from '../../../src/runtime/managers/HistoryManager.js';

afterEach(() => {
  cleanup();
  document.body.innerHTML = '';
  document.documentElement.removeAttribute('data-state-override');
  // Restore any `globalThis.fetch` stub so it never bleeds into sibling tests.
  vi.unstubAllGlobals();
});

describe('TopBar (AC-037)', () => {
  it('shows viewport, grid mode, state, and the live pin count', () => {
    document.body.innerHTML =
      '<i data-pin="e_1"></i><i data-pin="e_2"></i><i data-pin="e_3"></i>';
    const { container } = render(
      <TopBar
        viewport={{ width: 1440, height: 900 }}
        gridMode="pixel"
        stateOverride={null}
      />,
    );
    const field = (name: string): string =>
      container.querySelector(`[data-field="${name}"]`)?.textContent ?? '';
    expect(field('viewport')).toContain('1440');
    expect(field('grid')).toContain('pixel');
    expect(field('state')).toContain('none');
    expect(field('pins')).toContain('3');
  });
});

describe('StatePanel (AC-040)', () => {
  it('sets data-state-override on <html>', () => {
    const { container } = render(<StatePanel />);
    fireEvent.click(
      container.querySelector('[data-state-btn="hover"]') as Element,
    );
    expect(document.documentElement.getAttribute('data-state-override')).toBe(
      'hover',
    );
  });

  it('clears the override when "none" is chosen', () => {
    const { container } = render(<StatePanel />);
    fireEvent.click(
      container.querySelector('[data-state-btn="focus"]') as Element,
    );
    fireEvent.click(
      container.querySelector('[data-state-btn="none"]') as Element,
    );
    expect(
      document.documentElement.hasAttribute('data-state-override'),
    ).toBe(false);
  });
});

describe('TopBar ↔ StatePanel wiring (R-17-03, F-17-03)', () => {
  it('TopBar reflects the live StatePanel override', () => {
    // §8.5 — the TopBar carries a "state-override selector" readout; §8.8 — the
    // StatePanel owns the actual `[data-state-override]` mechanism. The TopBar
    // `[data-field="state"]` span must reflect the live override the StatePanel
    // chose, not a hardcoded `null`. This exercises the now-live non-null
    // `stateOverride` branch (resolving the AC-037 TEST-AUDIT-R17 advisory).
    const { container } = render(<PinScope />);
    const root = document.querySelector(
      '[data-pinscope-ui="root"]',
    ) as HTMLElement;
    const stateField = (): string =>
      root.querySelector('[data-field="state"]')?.textContent ?? '';
    // Before any override is chosen, the readout is `none`.
    expect(stateField()).toContain('none');
    // Choose the `hover` override in the StatePanel.
    fireEvent.click(
      root.querySelector('[data-state-btn="hover"]') as Element,
    );
    // The TopBar state field now reflects the live override.
    expect(stateField()).toContain('hover');
    expect(stateField()).not.toContain('none');
  });
});

describe('StatePanel stylesheet-scan override rules (R-15-04, §8.8)', () => {
  afterEach(() => {
    for (const s of Array.from(
      document.querySelectorAll('[data-pinscope-state-rules]'),
    )) {
      s.remove();
    }
    for (const s of Array.from(document.querySelectorAll('style.host-css'))) {
      s.remove();
    }
  });

  it('generates override rules from host :hover stylesheet rules', () => {
    const host = document.createElement('style');
    host.className = 'host-css';
    host.textContent = '.btn:hover { color: red }';
    document.head.appendChild(host);

    applyStateOverride('hover');

    const gen = document.querySelector(
      '[data-pinscope-state-rules]',
    ) as HTMLStyleElement | null;
    expect(gen).not.toBeNull();
    const css = gen?.textContent ?? '';
    expect(css).toContain('[data-state-override="hover"]');
    expect(css).toContain('.btn');
    expect(css).not.toContain(':hover');
  });

  it('clears the generated rules when the override is "none"', () => {
    const host = document.createElement('style');
    host.className = 'host-css';
    host.textContent = '.link:focus { outline: blue }';
    document.head.appendChild(host);

    applyStateOverride('focus');
    const gen = document.querySelector(
      '[data-pinscope-state-rules]',
    ) as HTMLStyleElement | null;
    expect(gen?.textContent).toContain('[data-state-override="focus"]');

    applyStateOverride('none');
    const cleared = document.querySelector(
      '[data-pinscope-state-rules]',
    ) as HTMLStyleElement | null;
    expect(cleared?.textContent ?? '').toBe('');
  });
});

describe('Crosshair disable conditions — AC-035 (R-15-02, §8.3)', () => {
  it('does not render while in measurement mode', () => {
    const { container } = render(<Crosshair measuring />);
    fireEvent.mouseMove(document.body, { clientX: 200, clientY: 200 });
    expect(container.querySelector('[data-pinscope-crosshair]')).toBeNull();
  });

  it('does not render while the HUD is hidden', () => {
    const { container } = render(<Crosshair hudHidden />);
    fireEvent.mouseMove(document.body, { clientX: 200, clientY: 200 });
    expect(container.querySelector('[data-pinscope-crosshair]')).toBeNull();
  });

  it('renders normally with no disable props (guard is conditional)', () => {
    const { container } = render(<Crosshair />);
    fireEvent.mouseMove(document.body, { clientX: 200, clientY: 200 });
    expect(container.querySelector('[data-pinscope-crosshair]')).not.toBeNull();
  });
});

describe('CommandBar (AC-038)', () => {
  it('focuses on Ctrl+K and blurs on Escape', () => {
    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    expect(document.activeElement).not.toBe(input);
    fireEvent.keyDown(document, { key: 'k', ctrlKey: true });
    expect(document.activeElement).toBe(input);
    fireEvent.keyDown(input, { key: 'Escape' });
    expect(document.activeElement).not.toBe(input);
  });

  it('recalls history with ArrowUp', () => {
    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'e_1.bg → red' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(input.value).toBe('');
    fireEvent.keyDown(input, { key: 'ArrowUp' });
    expect(input.value).toBe('e_1.bg → red');
  });
});

describe('CommandBar §8.6 — focus-expand / Tab autocomplete / history (R-15-07)', () => {
  it('expands to 120px on focus and collapses to 40px on blur', () => {
    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    // Collapsed by default (§8.6 — `height:40px`).
    expect(input.style.height).toBe('40px');
    fireEvent.focus(input);
    // Expanded while focused (§8.6 — "expands to 120px on focus").
    expect(input.style.height).toBe('120px');
    fireEvent.blur(input);
    expect(input.style.height).toBe('40px');
  });

  it('completes a partial pin to a full data-pin id on Tab', () => {
    // Seed the DOM with the pins §8.6 autocomplete scans for.
    const a = document.createElement('div');
    a.setAttribute('data-pin', 'e_47');
    const b = document.createElement('div');
    b.setAttribute('data-pin', 'e_12');
    document.body.append(a, b);

    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'e_4' } });
    fireEvent.keyDown(input, { key: 'Tab' });
    // Tab applies the first `getSuggestions` result — `e_47`.
    expect(input.value).toBe('e_47');
  });

  it('appends a submitted command through the injected HistoryManager', () => {
    const history = new HistoryManager(new MemoryHistoryStore());
    const appendSpy = vi.spyOn(history, 'append');

    const { container } = render(<CommandBar history={history} />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'e_1.bg → red' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    expect(appendSpy).toHaveBeenCalledTimes(1);
    const entry = appendSpy.mock.calls[0]?.[0];
    expect(entry?.raw_input).toBe('e_1.bg → red');
    // The entry landed in the manager's store (last 1000 enforced by §8.6).
    expect(history.list().map((e) => e.raw_input)).toContain('e_1.bg → red');
  });

  it('navigates the HistoryManager store with ArrowUp', () => {
    const history = new HistoryManager(new MemoryHistoryStore());
    const { container } = render(<CommandBar history={history} />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'e_2.fg → blue' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(input.value).toBe('');
    fireEvent.keyDown(input, { key: 'ArrowUp' });
    expect(input.value).toBe('e_2.fg → blue');
  });

  it('fires the §8.6 fetch POST to the /__pinscope/history endpoint on submit', async () => {
    // §8.6 — "History persisted to `.pinscope/history.json` (last 1000)";
    // §10-C — "Operation via CommandBar — … clipboard + history". The browser
    // runtime stays `fs`-free, so the CommandBar persists each appended entry
    // through the dev-server `/__pinscope/history` route. This test stubs
    // `globalThis.fetch` with a spy and asserts the POST actually fires —
    // closing F-16-08. The `persistHistory` guard `typeof fetch !== 'function'`
    // gates this call; the assertions below fail if that guard is flipped
    // (mutant M2 `!==` → `===`) since the spy would never be invoked.
    const fetchSpy = vi
      .fn<typeof fetch>()
      .mockResolvedValue(new Response(null, { status: 200 }));
    vi.stubGlobal('fetch', fetchSpy);

    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'e_5.bg → red' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    // The persistence POST fired exactly once at the history endpoint.
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const [url, init] = fetchSpy.mock.calls[0] ?? [];
    expect(url).toBe('/__pinscope/history');
    expect(init?.method).toBe('POST');

    // The request body parses to a `{ version, entries }` payload, and the
    // submitted command is present in the persisted entries.
    const body = JSON.parse(String(init?.body)) as {
      version: string;
      entries: { raw_input: string }[];
    };
    expect(body.version).toBe('1.0');
    expect(Array.isArray(body.entries)).toBe(true);
    expect(body.entries.map((e) => e.raw_input)).toContain('e_5.bg → red');

    // Drain the resolved fetch promise so no unhandled rejection leaks.
    await Promise.resolve();
    vi.unstubAllGlobals();
  });
});
