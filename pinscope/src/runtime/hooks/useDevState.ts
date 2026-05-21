/** Dev-state override hook — see SPEC §8.8. */

/**
 * Returns `true` when the global PinScope state override (the
 * `data-state-override` attribute on `<html>`) matches `state`; otherwise
 * returns the real `actual` value. Lets non-CSS component states (loading,
 * error, empty) be forced for inspection during development.
 */
export function useDevState(state: string, actual: boolean): boolean {
  if (typeof document === 'undefined') return actual;
  const override = document.documentElement.getAttribute(
    'data-state-override',
  );
  return override === state ? true : actual;
}
