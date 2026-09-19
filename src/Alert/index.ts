import { getNativeTinykitFeature } from '../utils/getNativeTinykit';
import type { AlertOptions } from '../utils/NativeTinykit';

export type { AlertOptions } from '../utils/NativeTinykit';

async function show(options: AlertOptions = {}): Promise<void> {
  if (options.duration !== undefined && !Number.isFinite(options.duration)) {
    throw new Error('[TinyKit] Alert duration must be a finite number.');
  }
  return getNativeTinykitFeature('Alert').showAlert(options);
}

export async function dismissAll(): Promise<void> {
  return getNativeTinykitFeature('Alert').dismissAllAlerts();
}

/** An SPAlert status overlay; distinct from React Native's Alert dialog. */
export const Alert = { show, dismissAll };
