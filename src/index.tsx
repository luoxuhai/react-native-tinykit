import Tinykit from './NativeTinykit';

/**
 * Restarts the React Native application.
 */
export function restart(): void {
  return Tinykit.restart();
}

/**
 * Gets the current battery level as a percentage (0-100).
 * @returns A promise that resolves to the battery level percentage.
 * @throws {Error} If battery level is unavailable.
 */
export function getBatteryLevel(): Promise<number> {
  return Tinykit.getBatteryLevel();
}

/**
 * Checks if Low Power Mode is currently enabled.
 * @returns A promise that resolves to true if Low Power Mode is enabled, false otherwise.
 */
export function isLowPowerModeEnabled(): Promise<boolean> {
  return Tinykit.isLowPowerModeEnabled();
}
