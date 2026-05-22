/** Command input bar — see SPEC §8.6. */

import { useEffect, useMemo, useRef, useState } from 'react';
import type {
  CSSProperties,
  KeyboardEvent as ReactKeyboardEvent,
  ReactElement,
} from 'react';
import { Z_SELECTED } from '../constants.js';
import { getSuggestions } from '../parsers/autocomplete.js';
import { SHORTCUT_PROPERTIES } from '../parsers/property-shortcuts.js';
import {
  HistoryManager,
  MemoryHistoryStore,
  type HistoryEntry,
} from '../managers/HistoryManager.js';

/** Dev-server route the command history is persisted through (§8.6). */
const HISTORY_ENDPOINT = '/__pinscope/history';

export interface CommandBarProps {
  onSubmit?: (command: string) => void;
  /**
   * Command-history backing manager (§8.6). Injectable for tests; defaults to
   * an in-memory store. The CommandBar additionally persists each append to
   * `.pinscope/history.json` via the dev-server endpoint.
   */
  history?: HistoryManager;
}

/** Read the current set of `data-pin` ids from the document. */
function readPins(): string[] {
  return Array.from(document.querySelectorAll('[data-pin]'))
    .map((el) => el.getAttribute('data-pin') ?? '')
    .filter((id) => id !== '');
}

/**
 * POST the full history list to the dev-server so it lands in
 * `.pinscope/history.json` (§8.6). The browser runtime stays `fs`-free; the
 * file write happens server-side. A failed persist is surfaced on the console
 * rather than silently swallowed — the in-memory history is unaffected.
 */
function persistHistory(entries: readonly HistoryEntry[]): void {
  if (typeof fetch !== 'function') return;
  try {
    void fetch(HISTORY_ENDPOINT, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ version: '1.0', entries }),
    }).catch((cause: unknown) => {
      // Dev-only endpoint — log instead of failing the command flow.
      console.warn('[pinscope] history persist failed', cause);
    });
  } catch (cause) {
    // Some environments throw synchronously (e.g. an unsupported relative
    // URL outside a dev server) — never let it break the command flow.
    console.warn('[pinscope] history persist failed', cause);
  }
}

export function CommandBar({
  onSubmit,
  history: injectedHistory,
}: CommandBarProps = {}): ReactElement {
  const inputRef = useRef<HTMLInputElement>(null);
  const cursor = useRef(-1);
  const [value, setValue] = useState('');
  const [focused, setFocused] = useState(false);

  // Command history (§8.6) — an injectable HistoryManager so callers/tests
  // control the backing store; the default is in-memory.
  const history = useMemo(
    () => injectedHistory ?? new HistoryManager(new MemoryHistoryStore()),
    [injectedHistory],
  );

  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      const isFocused = document.activeElement === inputRef.current;
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
      } else if (e.key === '/' && !isFocused) {
        e.preventDefault();
        inputRef.current?.focus();
      }
    };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, []);

  const onInputKey = (e: ReactKeyboardEvent<HTMLInputElement>): void => {
    if (e.key === 'Escape') {
      inputRef.current?.blur();
    } else if (e.key === 'Tab') {
      // §8.6 Tab autocomplete — apply the first suggestion for pins/properties.
      e.preventDefault();
      const suggestion = getSuggestions(value, readPins(), SHORTCUT_PROPERTIES)[0];
      if (suggestion !== undefined) {
        const dot = value.lastIndexOf('.');
        // After a `.` the suggestion completes the property fragment; before
        // any `.` it completes the last whitespace-separated pin token.
        if (dot !== -1) {
          setValue(`${value.slice(0, dot + 1)}${suggestion}`);
        } else {
          const head = value.slice(0, value.length - lastToken(value).length);
          setValue(`${head}${suggestion}`);
        }
      }
    } else if (e.key === 'Enter') {
      const command = value.trim();
      if (command) {
        const entry: HistoryEntry = {
          timestamp: new Date().toISOString(),
          raw_input: command,
          parsed: null,
          result: 'sent',
        };
        history.append(entry);
        persistHistory(history.list());
        cursor.current = -1;
        onSubmit?.(command);
        setValue('');
      }
    } else if (e.key === 'ArrowUp') {
      const list = history.list();
      if (list.length > 0) {
        cursor.current = Math.min(cursor.current + 1, list.length - 1);
        setValue(list[list.length - 1 - cursor.current]?.raw_input ?? '');
      }
    } else if (e.key === 'ArrowDown') {
      const list = history.list();
      if (cursor.current > 0) {
        cursor.current -= 1;
        setValue(list[list.length - 1 - cursor.current]?.raw_input ?? '');
      } else {
        cursor.current = -1;
        setValue('');
      }
    }
  };

  const style: CSSProperties = {
    position: 'fixed',
    bottom: 0,
    left: 0,
    right: 0,
    // §8.6 — `height:40px`, expands to 120px on focus.
    height: focused ? 120 : 40,
    padding: '0 12px',
    background: '#0f172a',
    color: '#e5e7eb',
    font: '13px ui-monospace, monospace',
    border: 'none',
    zIndex: Z_SELECTED,
  };
  return (
    <input
      ref={inputRef}
      data-pinscope-command=""
      value={value}
      placeholder="Command — e_47.padding → 12px"
      onChange={(e) => setValue(e.target.value)}
      onKeyDown={onInputKey}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
      style={style}
    />
  );
}

/** The trailing whitespace-separated token of an input (the autocomplete head). */
function lastToken(input: string): string {
  return input.split(/\s+/).pop() ?? '';
}
