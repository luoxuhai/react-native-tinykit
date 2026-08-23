import { useEffect } from 'react';
import { getNativeTinykitFeature } from './getNativeTinykit';

/**
 * Prevents the screen from auto-locking.
 */
export function activate(): void {
  getNativeTinykitFeature('KeepAwake').activateKeepAwake();
}

/**
 * Allows the screen to auto-lock again.
 */
export function deactivate(): void {
  getNativeTinykitFeature('KeepAwake').deactivateKeepAwake();
}

/**
 * Keeps the screen awake while the component is mounted.
 */
export function useKeepAwake(): void {
  useEffect(() => {
    activate();
    return deactivate;
  }, []);
}

/**
 * Keeps the screen awake while mounted.
 */
export function KeepAwake(): null {
  useKeepAwake();
  return null;
}
