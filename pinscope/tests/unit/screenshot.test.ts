import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const source = fs.readFileSync(
  path.join(root, 'src/runtime/utils/screenshot.ts'),
  'utf-8',
);

describe('screenshot — lazy html2canvas (AC-076)', () => {
  it('imports html2canvas dynamically', () => {
    expect(source).toMatch(/import\(\s*['"]html2canvas['"]\s*\)/);
  });

  it('never imports html2canvas with a static import', () => {
    expect(source).not.toMatch(/^\s*import\s[^()]*from\s+['"]html2canvas['"]/m);
  });
});
