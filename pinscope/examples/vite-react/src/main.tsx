import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App.js';

const container = document.getElementById('root');
if (container) {
  createRoot(container).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
}

// Dev-only: load the PinScope HUD. `import.meta.env.DEV` is statically false
// in a production build, so this branch — and the `pinscope/runtime` chunk —
// is tree-shaken away entirely.
if (import.meta.env.DEV) {
  void import('pinscope/runtime').then(({ PinScope }) => {
    const host = document.createElement('div');
    document.body.appendChild(host);
    createRoot(host).render(<PinScope />);
  });
}
