/** Command input bar — see SPEC §8.6. */

import { useEffect, useRef, useState } from 'react';
import type {
  CSSProperties,
  KeyboardEvent as ReactKeyboardEvent,
  ReactElement,
} from 'react';
import { Z_SELECTED } from '../constants.js';

export interface CommandBarProps {
  onSubmit?: (command: string) => void;
}

export function CommandBar({ onSubmit }: CommandBarProps = {}): ReactElement {
  const inputRef = useRef<HTMLInputElement>(null);
  const history = useRef<string[]>([]);
  const cursor = useRef(-1);
  const [value, setValue] = useState('');

  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      const focused = document.activeElement === inputRef.current;
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
      } else if (e.key === '/' && !focused) {
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
    } else if (e.key === 'Enter') {
      const command = value.trim();
      if (command) {
        history.current.push(command);
        cursor.current = -1;
        onSubmit?.(command);
        setValue('');
      }
    } else if (e.key === 'ArrowUp') {
      const h = history.current;
      if (h.length > 0) {
        cursor.current = Math.min(cursor.current + 1, h.length - 1);
        setValue(h[h.length - 1 - cursor.current] ?? '');
      }
    } else if (e.key === 'ArrowDown') {
      const h = history.current;
      if (cursor.current > 0) {
        cursor.current -= 1;
        setValue(h[h.length - 1 - cursor.current] ?? '');
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
    height: 40,
    padding: '0 12px',
    background: '#0f172a',
    color: '#e5e7eb',
    font: "13px ui-monospace, monospace",
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
      style={style}
    />
  );
}
