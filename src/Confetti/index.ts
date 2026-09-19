import { getNativeTinykitFeature } from '../utils/getNativeTinykit';
import type { ConfettiOptions } from '../utils/NativeTinykit';

export type { ConfettiOptions } from '../utils/NativeTinykit';

async function start(options: ConfettiOptions = {}): Promise<void> {
  if (
    options.duration !== undefined &&
    (!Number.isFinite(options.duration) || options.duration < 0)
  ) {
    throw new Error(
      '[TinyKit] Confetti duration must be a finite, non-negative number.'
    );
  }
  return getNativeTinykitFeature('Confetti').startConfetti(options);
}

async function stop(): Promise<void> {
  return getNativeTinykitFeature('Confetti').stopConfetti();
}

/** Starts and stops the original SPConfetti animation. */
export const Confetti = { start, stop };
