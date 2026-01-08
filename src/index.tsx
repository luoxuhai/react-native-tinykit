import Tinykit, {
  type ThermalState,
  type ThermalStateChangeEvent,
} from './NativeTinykit';

export type { ThermalState, ThermalStateChangeEvent } from './NativeTinykit';

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
 * Callback function type for thermal state change events.
 */
export type ThermalStateListener = (state: ThermalState) => void;

/**
 * Adds a listener that will be called when the thermal state changes.
 *
 * @param listener - Callback function that receives the new thermal state
 * @returns A subscription object with a remove method to stop listening
 */
export function addThermalStateListener(listener: ThermalStateListener): {
  remove: () => void;
} {
  const subscription = Tinykit.onThermalStateDidChange(
    (event: ThermalStateChangeEvent) => {
      listener(event.thermalState);
    }
  );
  return subscription;
}
