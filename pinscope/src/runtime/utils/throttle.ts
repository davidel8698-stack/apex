/** Throttling + heavy-page heuristics — see SPEC §12. */

/** Above this pinned-element count, hover handling throttles to ~30fps. */
export const HEAVY_PAGE_THRESHOLD = 500;

/** Throttle interval used on heavy pages (~30fps). */
export const HEAVY_PAGE_INTERVAL_MS = 33;

/** Badges narrower or shorter than this (px) are skipped on heavy pages. */
export const MIN_BADGE_SIZE = 16;

/**
 * Throttle `fn` to at most one call per `intervalMs`, leading + trailing —
 * the trailing call replays the most recent arguments.
 */
export function throttle<A extends unknown[]>(
  fn: (...args: A) => void,
  intervalMs: number,
): (...args: A) => void {
  let last = 0;
  let timer: ReturnType<typeof setTimeout> | null = null;
  let pending: A | null = null;

  return (...args: A): void => {
    const now = Date.now();
    const remaining = intervalMs - (now - last);
    if (remaining <= 0) {
      last = now;
      fn(...args);
      return;
    }
    pending = args;
    if (timer === null) {
      timer = setTimeout(() => {
        last = Date.now();
        timer = null;
        if (pending) {
          const next = pending;
          pending = null;
          fn(...next);
        }
      }, remaining);
    }
  };
}

/** Whether a badge of this size is too small to render on a heavy page. */
export function shouldSkipBadge(width: number, height: number): boolean {
  return width < MIN_BADGE_SIZE || height < MIN_BADGE_SIZE;
}

/** Whether a page with `pinCount` elements should throttle hover handling. */
export function isHeavyPage(pinCount: number): boolean {
  return pinCount > HEAVY_PAGE_THRESHOLD;
}
