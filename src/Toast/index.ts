import { getNativeTinykitFeature } from '../utils/getNativeTinykit';
import type { ToastOptions } from '../utils/NativeTinykit';

export type { ToastOptions } from '../utils/NativeTinykit';

async function show(options: ToastOptions = {}): Promise<void> {
  return getNativeTinykitFeature('Toast').showToast(options);
}

/** Presents an SPIndicator toast. Resolves when presentation is requested. */
export const Toast = { show };
