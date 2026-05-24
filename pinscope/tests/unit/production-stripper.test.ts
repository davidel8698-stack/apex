import { describe, it, expect } from 'vitest';
import { stripPins } from '../../src/plugin/production-stripper.js';

describe('production stripper (AC-009)', () => {
  it('removes a single data-pin attribute', () => {
    expect(stripPins('<button data-pin="e_1">Go</button>')).toBe(
      '<button>Go</button>',
    );
  });

  it('removes every data-pin attribute', () => {
    const html = '<div data-pin="e_1"><span data-pin="e_2">x</span></div>';
    expect(stripPins(html)).toBe('<div><span>x</span></div>');
  });

  it('leaves other attributes intact', () => {
    expect(stripPins('<a href="/x" data-pin="e_9">L</a>')).toBe(
      '<a href="/x">L</a>',
    );
  });

  it('is a no-op when there is no data-pin', () => {
    const html = '<main><h1>Title</h1></main>';
    expect(stripPins(html)).toBe(html);
  });
});
