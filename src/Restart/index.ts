import { getNativeTinykitFeature } from '../utils/getNativeTinykit';

/**
 * Restarts the React Native application.
 */
export function restart(): void {
  getNativeTinykitFeature('Restart').restart();
}
