/**
 * Stable key strategy — see SPEC.md §6.4.
 *
 * The key is `file:line:column`. The PinMap maps a key to a stable `e_N` id.
 * Moving an element in source produces a new key (and therefore a new id),
 * which is intentional: it prevents stale references.
 */
export function stableKey(
  filePath: string,
  line: number,
  column: number,
): string {
  return `${filePath}:${line}:${column}`;
}
