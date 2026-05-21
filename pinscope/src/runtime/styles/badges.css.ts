/** CSS-only pin badge styles — see SPEC §7.2. */

export const badgeCss = `
[data-pin] { position: relative; }
[data-pin]::before {
  content: attr(data-pin);
  position: absolute; top: 0; left: 0;
  font: 600 10px/1.2 ui-monospace, 'SF Mono', Consolas, monospace;
  background: rgba(59, 130, 246, 0.92);
  color: #fff;
  padding: 1px 4px;
  border-radius: 0 0 3px 0;
  pointer-events: none;
  z-index: 2147483645;
  user-select: none;
  letter-spacing: 0.02em;
  text-transform: lowercase;
}
[data-pin]:hover::before {
  background: rgba(239, 68, 68, 0.95);
  z-index: 2147483646;
}
[data-pin][data-pin-selected]::before {
  background: rgba(34, 197, 94, 0.95);
  z-index: 2147483647;
}
[data-pin]:hover {
  outline: 2px solid rgba(239, 68, 68, 0.4);
  outline-offset: 2px;
}
[data-pin][data-pin-selected] {
  outline: 2px solid rgba(34, 197, 94, 0.6);
  outline-offset: 2px;
}
[data-pinscope-ui] [data-pin]::before { display: none; }
[data-pinscope-ui] { outline: none !important; }
@media print {
  [data-pinscope-ui] { display: none; }
  [data-pin]::before { display: none; }
}
`;
