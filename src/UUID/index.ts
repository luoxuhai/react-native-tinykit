import { getNativeTinykitFeature } from '../utils/getNativeTinykit';

/**
 * Generates a random RFC 4122 version 4 UUID.
 */
export function uuid(): string {
  return getNativeTinykitFeature('UUID').uuid();
}
