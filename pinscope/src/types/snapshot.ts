/** Snapshot schema — see SPEC.md §9.2. */

export interface ElementRect {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface ElementSnapshot {
  tag: string;
  classes: string[];
  attributes: Record<string, string>;
  text_content?: string;
  rect: ElementRect;
  computed_styles: Record<string, string>;
  parent_pin?: string;
  children_pins: string[];
  visible: boolean;
  in_viewport: boolean;
}

export interface Snapshot {
  version: '1.0';
  id: string;
  name?: string;
  created: string;
  viewport: { width: number; height: number };
  url: string;
  user_agent: string;
  device_pixel_ratio: number;
  elements: Record<string, ElementSnapshot>;
  summary: {
    total_elements: number;
    visible_elements: number;
    in_viewport: number;
  };
}
