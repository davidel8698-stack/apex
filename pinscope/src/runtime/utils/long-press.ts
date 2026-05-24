/** Touch gesture + responsive helpers — see SPEC §12. */

/** Viewport widths below this collapse the HUD. */
export const MOBILE_BREAKPOINT = 768;

/** Long-press threshold in ms. */
export const LONG_PRESS_MS = 500;

export type Gesture = 'tap' | 'long-press';

/**
 * Distinguishes a tap from a long-press by the dwell time between `start`
 * and `end`. A press held `LONG_PRESS_MS` or longer is a long-press (lock);
 * anything shorter is a tap (select).
 */
export class LongPressDetector {
  private startedAt = 0;

  constructor(private readonly thresholdMs: number = LONG_PRESS_MS) {}

  start(now: number = Date.now()): void {
    this.startedAt = now;
  }

  end(now: number = Date.now()): Gesture {
    return now - this.startedAt >= this.thresholdMs ? 'long-press' : 'tap';
  }
}

/** Whether a viewport of this width should collapse the HUD. */
export function isCompactViewport(width: number): boolean {
  return width < MOBILE_BREAKPOINT;
}
