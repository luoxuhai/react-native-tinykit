import { getNativeTinykitFeature } from './getNativeTinykit';

/**
 * Restarts the React Native application.
 */
export function restart(): void {
  getNativeTinykitFeature('Restart').restart();
}
