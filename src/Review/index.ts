import { getNativeTinykitFeature } from '../utils/getNativeTinykit';

/**
 * Requests a review of the app.
 */
export function requestReview(): Promise<void> {
  return getNativeTinykitFeature('Review').requestReview();
}
