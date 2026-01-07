import Tinykit from './NativeTinykit';

/**
 * Restarts the React Native application.
 */
export function restart(): void {
  return Tinykit.restart();
}

/**
 * Gets the current battery level as a percentage (0-100).
 * @returns The battery level percentage, or -1 if unavailable.
 */
export function getBatteryLevel(): number {
  return Tinykit.getBatteryLevel();
}

/**
 * Checks if Low Power Mode is currently enabled.
 * @returns true if Low Power Mode is enabled, false otherwise.
 */
export function isLowPowerModeEnabled(): boolean {
  return Tinykit.isLowPowerModeEnabled();
}
