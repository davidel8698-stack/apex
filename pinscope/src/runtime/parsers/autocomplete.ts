/** CommandBar autocomplete — see SPEC §8.6. */

/**
 * Suggest completions for a partial command: pin ids while typing a target,
 * property names after a `.`. Returns at most 10 suggestions.
 */
export function getSuggestions(
  input: string,
  pins: readonly string[],
  properties: readonly string[],
): string[] {
  const text = input.trimStart();

  const dot = text.lastIndexOf('.');
  if (dot !== -1) {
    const fragment = text.slice(dot + 1).trimStart();
    return properties.filter((p) => p.startsWith(fragment)).slice(0, 10);
  }

  const lastToken = text.split(/\s+/).pop() ?? '';
  if (lastToken === '' || /^e_?\d*$/.test(lastToken)) {
    return pins.filter((p) => p.startsWith(lastToken)).slice(0, 10);
  }

  return [];
}
