import {
  TurboModuleRegistry,
  type TurboModule,
  type CodegenTypes,
} from 'react-native';

/**
 * Thermal state values that indicate the current thermal condition of the device.
 * - 'nominal': The thermal state is within normal limits.
 * - 'fair': The thermal state is slightly elevated.
 * - 'serious': The thermal state is high.
 * - 'critical': The thermal state is critically high.
 */
export type ThermalState = 'nominal' | 'fair' | 'serious' | 'critical';

export type ImpactFeedbackStyle =
  | 'light'
  | 'medium'
  | 'heavy'
  | 'soft'
  | 'rigid';

export type NotificationFeedbackType = 'success' | 'warning' | 'error';

export type ColorPickerDetent = {
  /**
   * Detent type. Use 'medium' or 'large' for system detents, or 'custom' with height or fraction.
   */
  type: 'medium' | 'large' | 'custom';
  /**
   * Optional identifier for a custom detent. Used by selectedDetentIdentifier.
   */
  identifier?: string;
  /**
   * Fixed custom detent height in points.
   */
  height?: CodegenTypes.Double;
  /**
   * Custom detent height as a fraction of the maximum sheet height.
   */
  fraction?: CodegenTypes.Double;
};

export type ColorPickerOptions = {
  /**
   * Initial selected color. Supports #RGB, #RGBA, #RRGGBB, and #RRGGBBAA.
   */
  selectedColor?: string;
  /**
   * Whether the picker shows the alpha slider. Defaults to true.
   */
  supportsAlpha?: boolean;
  /**
   * Whether the picker supports the eyedropper when available on the OS.
   */
  supportsEyedropper?: boolean;
  /**
   * Maximum exposure applied to colors returned by the picker when available on the OS.
   */
  maximumLinearExposure?: CodegenTypes.Double;
  /**
   * Optional navigation title shown by the color picker.
   */
  title?: string;
  /**
   * Shows a Done button in the top-right corner.
   */
  showDoneButton?: boolean;
  /**
   * Custom text for the top-right Done button.
   */
  doneButtonTitle?: string;
  /**
   * Sheet detents used when presenting the picker. Supports medium/large and custom height/fraction detents.
   */
  detents?: ReadonlyArray<ColorPickerDetent>;
  /**
   * Initially selected sheet detent identifier. Use 'medium', 'large', or a custom detent identifier.
   */
  selectedDetentIdentifier?: string;
  /**
   * Largest detent that keeps the presenting view undimmed. Use 'medium', 'large', or a custom detent identifier.
   */
  largestUndimmedDetentIdentifier?: string;
  /**
   * Whether the sheet grabber is visible.
   */
  prefersGrabberVisible?: boolean;
};

export type ColorPickerResult = {
  /**
   * Selected color returned as #RRGGBBAA.
   */
  color: string;
  red: CodegenTypes.Double;
  green: CodegenTypes.Double;
  blue: CodegenTypes.Double;
  alpha: CodegenTypes.Double;
};

export interface Spec extends TurboModule {
  restart(): void;
  getThermalState(): ThermalState;
  requestReview(): Promise<void>;
  activateKeepAwake(): void;
  deactivateKeepAwake(): void;
  showColorPicker(options: ColorPickerOptions): Promise<ColorPickerResult>;
  readonly onThermalStateChange: CodegenTypes.EventEmitter<ThermalState>;
  impact(style: string): void;
  selection(): void;
  notification(type: string): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Tinykit');
