/** Viewport-space rect math, SVG-aware — see SPEC §12. */

export interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}

interface SvgGraphics {
  getBBox(): { x: number; y: number; width: number; height: number };
  getCTM(): {
    a: number;
    b: number;
    c: number;
    d: number;
    e: number;
    f: number;
  } | null;
}

const SVG_NS = 'http://www.w3.org/2000/svg';

function isSvgGraphics(el: Element): el is Element & SvgGraphics {
  return (
    el.namespaceURI === SVG_NS &&
    typeof (el as Partial<SvgGraphics>).getBBox === 'function' &&
    typeof (el as Partial<SvgGraphics>).getCTM === 'function'
  );
}

/**
 * Return an element's viewport-space rect. For SVG graphics elements
 * `getBoundingClientRect` is unreliable, so the local `getBBox` is mapped
 * into viewport space through the current transform matrix (`getCTM`).
 */
export function elementRect(el: Element): Rect {
  if (isSvgGraphics(el)) {
    const bbox = el.getBBox();
    const ctm = el.getCTM();
    if (ctm) {
      return {
        x: ctm.a * bbox.x + ctm.c * bbox.y + ctm.e,
        y: ctm.b * bbox.x + ctm.d * bbox.y + ctm.f,
        w: bbox.width * ctm.a,
        h: bbox.height * ctm.d,
      };
    }
    return { x: bbox.x, y: bbox.y, w: bbox.width, h: bbox.height };
  }
  const r = el.getBoundingClientRect();
  return { x: r.x, y: r.y, w: r.width, h: r.height };
}
