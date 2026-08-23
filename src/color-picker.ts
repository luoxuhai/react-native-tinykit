import { getNativeTinykitFeature } from './getNativeTinykit';
import type { ColorPickerOptions, ColorPickerResult } from './NativeTinykit';

export type {
  ColorPickerDetent,
  ColorPickerOptions,
  ColorPickerResult,
} from './NativeTinykit';

/**
 * Shows the native iOS color picker.
 */
export function showColorPicker(
  options: ColorPickerOptions = {}
): Promise<ColorPickerResult> {
  return getNativeTinykitFeature('ColorPicker').showColorPicker(options);
}
