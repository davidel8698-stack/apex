/** Operation payload schema — see SPEC.md §9.3. */

export type OperationKind =
  | 'set'
  | 'increment'
  | 'decrement'
  | 'remove'
  | 'add-class'
  | 'remove-class';

export interface OperationItem {
  property: string;
  operation: OperationKind;
  value?: string | number;
  delta?: number;
}

export interface OperationContext {
  tag: string;
  selector: string;
  text_content?: string;
  rect: { x: number; y: number; w: number; h: number };
  parent_pin?: string;
  children_pins: string[];
}

export interface Operation {
  version: '1.0';
  pin: string;
  context: OperationContext;
  current_styles: Record<string, string>;
  request_type: 'operation' | 'annotation' | 'diagnostic';
  operations?: OperationItem[];
  annotation?: string;
  signal?: string;
  meta: {
    viewport: string;
    timestamp: string;
    snapshot_id?: string;
    screenshot_data_url?: string;
  };
}
