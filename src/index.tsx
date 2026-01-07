import { NativeEventEmitter } from 'react-native';
import Tinykit, { type ThermalState } from './NativeTinykit';

export type { ThermalState } from './NativeTinykit';

/**
 * Event payload for thermal state change events.
 */
interface ThermalStateChangeEvent {
  thermalState: ThermalState;
}

const TinykitEventEmitter = new NativeEventEmitter(Tinykit);

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
  const subscription = TinykitEventEmitter.addListener(
    'thermalStateDidChange',
    (event) => {
      const thermalEvent = event as ThermalStateChangeEvent;
      listener(thermalEvent.thermalState);
    }
  );
  return subscription;
}
