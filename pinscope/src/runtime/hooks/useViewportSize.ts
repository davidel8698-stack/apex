/** Viewport size hook — see SPEC §8.2. */

import { useEffect, useState } from 'react';

export interface ViewportSize {
  width: number;
  height: number;
}

function read(): ViewportSize {
  if (typeof window === 'undefined') return { width: 0, height: 0 };
  return { width: window.innerWidth, height: window.innerHeight };
}

/** Track the window inner size, updating on resize. */
export function useViewportSize(): ViewportSize {
  const [size, setSize] = useState<ViewportSize>(read);
  useEffect(() => {
    const onResize = (): void => setSize(read());
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);
  return size;
}
