import { getNativeTinykitFeature } from '../utils/getNativeTinykit';
import type {
  ColorPickerOptions,
  ColorPickerResult,
} from '../utils/NativeTinykit';

export type {
  ColorPickerDetent,
  ColorPickerOptions,
  ColorPickerResult,
} from '../utils/NativeTinykit';

/**
 * Shows the native iOS color picker.
 */
export function showColorPicker(
  options: ColorPickerOptions = {}
): Promise<ColorPickerResult> {
  return getNativeTinykitFeature('ColorPicker').showColorPicker(options);
}
