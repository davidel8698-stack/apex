/** JSX → JSX + `data-pin` AST transformer — see SPEC.md §6.2. */

import { parse } from '@babel/parser';
import traverseDefault from '@babel/traverse';
import generateDefault from '@babel/generator';
import * as t from '@babel/types';
import type { PinMap } from './pin-map.js';
import { stableKey } from './stable-id-generator.js';

// @babel/traverse and @babel/generator are CJS; under ESM the callable lives
// on `.default`. Resolve it once, type-safely.
const traverse = (
  (traverseDefault as { default?: typeof traverseDefault }).default ??
  traverseDefault
);
const generate = (
  (generateDefault as { default?: typeof generateDefault }).default ??
  generateDefault
);

export interface TransformOptions {
  /** Tag names that must NOT receive a `data-pin` attribute. */
  excludeTags: string[];
}

/** Standard raw source map shape emitted by @babel/generator. */
export interface RawSourceMap {
  version: number;
  sources: string[];
  names: string[];
  mappings: string;
  file?: string;
  sourceRoot?: string;
  sourcesContent?: string[];
}

export interface TransformResult {
  code: string;
  map: RawSourceMap | null;
}

export function transformJSX(
  code: string,
  filePath: string,
  pinMap: PinMap,
  opts: TransformOptions,
): TransformResult {
  const ast = parse(code, {
    sourceType: 'module',
    plugins: ['jsx', 'typescript', 'decorators-legacy'],
    sourceFilename: filePath,
  });

  traverse(ast, {
    JSXOpeningElement(path) {
      const node = path.node;
      const tagName = getElementName(node.name);
      if (opts.excludeTags.includes(tagName)) return;
      if (hasAttribute(node, 'data-pin')) return;
      if (hasAttribute(node, 'data-pin-ignore')) return;

      const loc = node.loc?.start;
      if (!loc) return;

      const key = stableKey(filePath, loc.line, loc.column);
      const pinId = pinMap.getOrAssign(key, tagName);
      node.attributes.push(
        t.jsxAttribute(t.jsxIdentifier('data-pin'), t.stringLiteral(pinId)),
      );
    },
  });

  const output = generate(
    ast,
    { sourceMaps: true, sourceFileName: filePath },
    code,
  );
  // @babel/generator types `map` as `object | null`; at runtime it is a
  // standard raw source map. Narrow it for the Vite boundary.
  return { code: output.code, map: (output.map as RawSourceMap | null) ?? null };
}

/** Resolve a JSX element name across the three JSX name node kinds. */
export function getElementName(
  node: t.JSXIdentifier | t.JSXMemberExpression | t.JSXNamespacedName,
): string {
  if (t.isJSXIdentifier(node)) return node.name;
  if (t.isJSXMemberExpression(node)) return getElementName(node.property);
  if (t.isJSXNamespacedName(node)) return node.name.name;
  return 'unknown';
}

function hasAttribute(node: t.JSXOpeningElement, name: string): boolean {
  return node.attributes.some(
    (attr) =>
      t.isJSXAttribute(attr) &&
      t.isJSXIdentifier(attr.name) &&
      attr.name.name === name,
  );
}
