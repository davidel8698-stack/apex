/** Input/output fixture table for the AST transformer suite (AC-080). */

export interface TransformerCase {
  name: string;
  /** A JSX element expression. */
  jsx: string;
  /** Whether the element should receive a `data-pin` attribute. */
  expectPin: boolean;
}

const HTML_TAGS = [
  'div', 'span', 'p', 'a', 'button', 'section', 'article', 'nav',
  'header', 'footer', 'main', 'aside', 'ul', 'ol', 'li', 'form',
  'label', 'input', 'select', 'textarea', 'table', 'thead', 'tbody',
  'tr', 'td', 'th', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'img',
  'figure', 'figcaption', 'small', 'strong', 'em', 'picture', 'video',
  'canvas', 'details', 'summary', 'dialog',
];

const COMPONENT_TAGS = [
  'Button', 'Card', 'Modal', 'Layout', 'Hero', 'Navbar', 'Sidebar', 'Avatar',
];

export const transformerCases: TransformerCase[] = [
  ...HTML_TAGS.map((tag): TransformerCase => ({
    name: `injects data-pin on <${tag}>`,
    jsx: `<${tag} />`,
    expectPin: true,
  })),
  ...COMPONENT_TAGS.map((tag): TransformerCase => ({
    name: `injects data-pin on component <${tag}>`,
    jsx: `<${tag} />`,
    expectPin: true,
  })),
  { name: 'skips <Fragment>', jsx: '<Fragment />', expectPin: false },
  { name: 'skips <Suspense>', jsx: '<Suspense />', expectPin: false },
  {
    name: 'resolves member-expression tag <Ns.Item>',
    jsx: '<Ns.Item />',
    expectPin: true,
  },
  {
    name: 'resolves deep member-expression tag <A.B.C>',
    jsx: '<A.B.C />',
    expectPin: true,
  },
];
