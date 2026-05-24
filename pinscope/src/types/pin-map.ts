/** PinMap persistence schema — see SPEC.md §9.1. */

export interface PinMapEntry {
  /** Stable Pin id, e.g. "e_47". */
  id: string;
  /** Element tag name at assignment time. */
  tag: string;
  /** ISO timestamp of first assignment. */
  created: string;
  /** ISO timestamp of the most recent build that saw this key. */
  last_seen: string;
  /** True when the source location no longer exists. Id is never reused. */
  deleted?: boolean;
}

export interface PinMapData {
  version: 1;
  /** Next Pin id counter; only ever increments. */
  next_id: number;
  /** Map of stable key (`file:line:column`) → entry. */
  entries: Record<string, PinMapEntry>;
}
