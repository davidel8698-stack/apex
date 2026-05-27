/** PinScope public API — see SPEC.md §15. */

export { pinscope } from './plugin/index.js';
export type { PinScopeOptions } from './plugin/index.js';

export { withPinScope } from './plugin/next.js';

export { PinScope } from './runtime/PinScope.js';
export type { PinScopeProps } from './runtime/PinScope.js';
export { useDevState } from './runtime/hooks/useDevState.js';

export type {
  Operation,
  Snapshot,
  ElementSnapshot,
} from './types/index.js';
