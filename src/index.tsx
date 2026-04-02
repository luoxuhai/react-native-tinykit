import { useEffect } from 'react';
import Tinykit, { type ThermalState } from './NativeTinykit';

export type { ThermalState } from './NativeTinykit';

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
