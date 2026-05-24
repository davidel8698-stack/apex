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
    // R-18-01 — the CommandBar appends its own recall entry only for local-only
    // command kinds (`select`/`measure`/`snapshot`), which never reach
    // `ClaudeBridge`. Operation-kind recall is covered end-to-end (via the
    // shared manager `ClaudeBridge` appends to) by the R-18-01 ownership test.
    const { container } = render(<CommandBar />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'select e_1' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(input.value).toBe('');
    fireEvent.keyDown(input, { key: 'ArrowUp' });
    expect(input.value).toBe('select e_1');
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
    // R-18-01 — the CommandBar appends its own history row only for local-only
    // command kinds. An `operation`/`class`/`query` submit gets its single
    // real `parsed: <Operation>` row from `ClaudeBridge.send` instead, so the
    // CommandBar does not append for it (no `parsed: null` placeholder).
    const history = new HistoryManager(new MemoryHistoryStore());
    const appendSpy = vi.spyOn(history, 'append');

    const { container } = render(<CommandBar history={history} />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'select e_1' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    expect(appendSpy).toHaveBeenCalledTimes(1);
    const entry = appendSpy.mock.calls[0]?.[0];
    expect(entry?.raw_input).toBe('select e_1');
    // The entry landed in the manager's store (last 1000 enforced by §8.6).
    expect(history.list().map((e) => e.raw_input)).toContain('select e_1');

    // An operation-kind submit does NOT add a CommandBar placeholder row.
    appendSpy.mockClear();
    fireEvent.change(input, { target: { value: 'e_1.bg → red' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(appendSpy).not.toHaveBeenCalled();
  });

  it('appends a snapshot-kind command through the local-only path (R-20-05)', () => {
    // R-20-05 — exercises the `snapshot` disjunct of `isLocalOnlyCommand`
    // (CommandBar.tsx L49), which prior R-19 coverage left unexercised: every
    // CommandBar Enter-path test fed `select e_1` (1st disjunct) or
    // `measure e_2 e_3` (invalid grammar → catch branch). A VALID
    // `snapshot foo` parses to `kind: 'snapshot'` and must produce exactly
    // one local-only `parsed: null` history entry — killing the R18
    // `or-to-and` mutant on the disjunction.
    const history = new HistoryManager(new MemoryHistoryStore());
    const appendSpy = vi.spyOn(history, 'append');
    const { container } = render(<CommandBar history={history} />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'snapshot foo' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    expect(appendSpy).toHaveBeenCalledTimes(1);
    const entry = appendSpy.mock.calls[0]?.[0];
    expect(entry?.raw_input).toBe('snapshot foo');
    expect(entry?.parsed).toBe(null);
    expect(entry?.result).toBe('applied');
    expect(history.list().map((e) => e.raw_input)).toContain('snapshot foo');
  });

  it('appends a measure-kind command through the local-only path (R-20-05)', () => {
    // R-20-05 — exercises the `measure` disjunct of `isLocalOnlyCommand`
    // (CommandBar.tsx L49). The valid grammar is `measure e_N to e_M`
    // (operation-parser RE_MEASURE: /^measure\s+(e_\d+)\s+to\s+(e_\d+)$/i).
    // A valid `measure e_2 to e_3` parses to `kind: 'measure'` and must
    // produce exactly one local-only `parsed: null` history entry — the
    // second arm killing the R18 `or-to-and` mutant on the disjunction.
    const history = new HistoryManager(new MemoryHistoryStore());
    const appendSpy = vi.spyOn(history, 'append');
    const { container } = render(<CommandBar history={history} />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'measure e_2 to e_3' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    expect(appendSpy).toHaveBeenCalledTimes(1);
    const entry = appendSpy.mock.calls[0]?.[0];
    expect(entry?.raw_input).toBe('measure e_2 to e_3');
    expect(entry?.parsed).toBe(null);
    expect(entry?.result).toBe('applied');
    expect(history.list().map((e) => e.raw_input)).toContain(
      'measure e_2 to e_3',
    );
  });

  it('navigates the HistoryManager store with ArrowUp', () => {
    // R-18-01 — recall via the CommandBar's own append covers local-only kinds.
    const history = new HistoryManager(new MemoryHistoryStore());
    const { container } = render(<CommandBar history={history} />);
    const input = container.querySelector(
      '[data-pinscope-command]',
    ) as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'measure e_2 e_3' } });
    fireEvent.keyDown(input, { key: 'Enter' });
    expect(input.value).toBe('');
    fireEvent.keyDown(input, { key: 'ArrowUp' });
    expect(input.value).toBe('measure e_2 e_3');
  });

  it('persists history through a single owner — the HistoryManager hook (R-18-01)', async () => {
    // §8.6 — "History persisted to `.pinscope/history.json` (last 1000)";
    // §10-C — "Operation via CommandBar — … clipboard + history". R-18-01
    // moved persistence off the CommandBar onto the `HistoryManager` persist
    // hook wired in `PinScope.tsx`: every append (CommandBar's and
    // `ClaudeBridge.send`'s) POSTs through exactly one `/__pinscope/history`
    // site. This test renders the real `<PinScope/>`, submits an operation,
    // and asserts the POST fires once with a `{ version, entries }` body.
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText: (): Promise<void> => Promise.resolve() },
    });
    const fetchSpy = vi
      .fn<typeof fetch>()
      .mockResolvedValue(new Response(null, { status: 200 }));
    vi.stubGlobal('fetch', fetchSpy);

    const pin = document.createElement('div');
    pin.setAttribute('data-pin', 'e_5');
    document.body.appendChild(pin);
    render(<PinScope />);
    const input = document
      .querySelector('[data-pinscope-ui="root"]')
      ?.querySelector('[data-pinscope-command]') as HTMLInputElement;
    fireEvent.change(input, { target: { value: 'e_5.bg → red' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    await vi.waitFor(() => {
      const historyCalls = fetchSpy.mock.calls.filter(
        ([url]) => url === '/__pinscope/history',
      );
      expect(historyCalls.length).toBe(1);
    });

    const historyCall = fetchSpy.mock.calls.find(
      ([url]) => url === '/__pinscope/history',
    );
    const init = historyCall?.[1];
    expect(init?.method).toBe('POST');
    const body = JSON.parse(String(init?.body)) as {
      version: string;
      entries: { raw_input: string }[];
    };
    expect(body.version).toBe('1.0');
    expect(Array.isArray(body.entries)).toBe(true);
    expect(body.entries.map((e) => e.raw_input)).toContain('e_5.bg → red');

    await Promise.resolve();
    vi.unstubAllGlobals();
  });
});
