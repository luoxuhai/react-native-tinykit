import { getNativeTinykitFeature } from './getNativeTinykit';
import type { ThermalState } from './NativeTinykit';

export type { ThermalState } from './NativeTinykit';

export type ThermalStateListener = (state: ThermalState) => void;

let listenerCount = 0;

/**
 * Gets the current thermal state of the device.
 */
export function getThermalState(): ThermalState {
  return getNativeTinykitFeature('ThermalState').getThermalState();
}

/**
 * Adds a listener that will be called when the thermal state changes.
 */
export function onThermalStateChange(listener: ThermalStateListener): {
  remove: () => void;
} {
  const tinykit = getNativeTinykitFeature('ThermalState');

  if (listenerCount === 0) {
    tinykit.startThermalStateMonitoring();
  }

  let subscription: { remove: () => void };
  try {
    subscription = tinykit.onThermalStateChange(listener);
    listenerCount += 1;
  } catch (error) {
    if (listenerCount === 0) {
      tinykit.stopThermalStateMonitoring();
    }
    throw error;
  }

  let removed = false;

  return {
    remove: () => {
      if (removed) {
        return;
      }

      removed = true;
      subscription.remove();
      listenerCount -= 1;

      if (listenerCount === 0) {
        tinykit.stopThermalStateMonitoring();
      }
    },
  };
}
