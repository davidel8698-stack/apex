/** CSS-only pin badge styles — see SPEC §7.2, §12. */

export const badgeCss = `
[data-pin] { position: relative; }
[data-pin]::before {
  content: attr(data-pin) !important;
  position: absolute !important; top: 0 !important; left: 0 !important;
  font: 600 10px/1.2 ui-monospace, 'SF Mono', Consolas, monospace;
  background: rgba(59, 130, 246, 0.92) !important;
  color: #fff;
  padding: 1px 4px !important;
  border-radius: 0 0 3px 0 !important;
  pointer-events: none !important;
  z-index: 2147483645 !important;
  user-select: none;
  letter-spacing: 0.02em;
  text-transform: lowercase;
}
[data-pin]:hover::before {
  background: rgba(239, 68, 68, 0.95) !important;
  z-index: 2147483646 !important;
}
[data-pin][data-pin-selected]::before {
  background: rgba(34, 197, 94, 0.95) !important;
  z-index: 2147483647 !important;
}
[data-pin]:hover {
  outline: 2px solid rgba(239, 68, 68, 0.4) !important;
  outline-offset: 2px;
}
[data-pin][data-pin-selected] {
  outline: 2px solid rgba(34, 197, 94, 0.6) !important;
  outline-offset: 2px;
}
[data-pinscope-ui] [data-pin]::before { display: none !important; }
[data-pinscope-ui] { outline: none !important; }
@media print {
  [data-pinscope-ui] { display: none !important; }
  [data-pin]::before { display: none !important; }
}
`;
