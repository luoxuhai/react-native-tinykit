import { useEffect } from 'react';
import Tinykit, {
  type ColorPickerOptions,
  type ColorPickerResult,
  type ThermalState,
  type ImpactFeedbackStyle,
  type NotificationFeedbackType,
} from './NativeTinykit';

export type {
  ColorPickerOptions,
  ColorPickerResult,
  ThermalState,
  ImpactFeedbackStyle,
  NotificationFeedbackType,
} from './NativeTinykit';

/**
 * Restarts the React Native application.
 */
export function restart(): void {
  return Tinykit.restart();
}

/**
 * Gets the current thermal state of the device.
 *
 * @returns The current thermal state: 'nominal', 'fair', 'serious', or 'critical'
 */
export function getThermalState(): ThermalState {
  return Tinykit.getThermalState();
}

/**
 * Requests a review of the app.
 *
 * @returns A promise that resolves when the review request is processed.
 */
export function requestReview(): Promise<void> {
  return Tinykit.requestReview();
}

/**
 * Shows the native iOS color picker.
 *
 * @param options - Color picker configuration
 * @returns A promise that resolves with the selected color when the picker finishes.
 */
export function showColorPicker(
  options: ColorPickerOptions = {}
): Promise<ColorPickerResult> {
  return Tinykit.showColorPicker(options);
}

/**
 * Callback function type for thermal state change events.
 */
export type ThermalStateListener = (state: ThermalState) => void;

/**
 * Adds a listener that will be called when the thermal state changes.
 *
 * @param listener - Callback function that receives the new thermal state
 * @returns A subscription object with a remove method to stop listening
 */
export function onThermalStateChange(listener: ThermalStateListener): {
  remove: () => void;
} {
  return Tinykit.onThermalStateChange(listener);
}

/**
 * Activates the keep-awake feature, preventing the screen from auto-locking.
 */
export function activate(): void {
  Tinykit.activateKeepAwake();
}

/**
 * Deactivates the keep-awake feature, allowing the screen to auto-lock.
 */
export function deactivate(): void {
  Tinykit.deactivateKeepAwake();
}

/**
 * A hook that keeps the screen awake while the component is mounted.
 */
export function useKeepAwake(): void {
  useEffect(() => {
    activate();
    return () => {
      deactivate();
    };
  }, []);
}

/**
 * A component that keeps the screen awake while mounted.
 *
 * @example
 * ```tsx
 * <KeepAwake />
 * ```
 */
export function KeepAwake(): null {
  useKeepAwake();
  return null;
}

/**
 * Triggers an impact haptic feedback.
 *
 * @param style - The style of the impact: 'light', 'medium', 'heavy', 'soft', or 'rigid'
 */
export function impact(style: ImpactFeedbackStyle): void {
  Tinykit.impact(style);
}

/**
 * Triggers a selection haptic feedback.
 */
export function selection(): void {
  Tinykit.selection();
}

/**
 * Triggers a notification haptic feedback.
 *
 * @param type - The type of notification: 'success', 'warning', or 'error'
 */
export function notification(type: NotificationFeedbackType): void {
  Tinykit.notification(type);
}
