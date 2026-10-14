import { getNativeTinykitFeature } from '../utils/getNativeTinykit';
import type { StoreOverlayOptions } from '../utils/NativeTinykit';
import {
  storeOptionsError,
  validateStoreOptions,
} from '../utils/validateStoreOptions';

export type { StoreOverlayOptions } from '../utils/NativeTinykit';

/** Presents an app promotion overlay; resolves after presentation succeeds. */
export async function showStoreOverlay(
  options: StoreOverlayOptions
): Promise<void> {
  const code = 'E_STORE_OVERLAY_INVALID_OPTIONS';
  validateStoreOptions(options, ['campaignToken', 'providerToken'], code);
  if (
    options.position !== undefined &&
    !['bottom', 'bottomRaised'].includes(options.position)
  ) {
    throw storeOptionsError(code, 'position must be bottom or bottomRaised.');
  }
  if (
    options.userDismissible !== undefined &&
    typeof options.userDismissible !== 'boolean'
  ) {
    throw storeOptionsError(code, 'userDismissible must be a boolean.');
  }
  return getNativeTinykitFeature('StoreOverlay').showStoreOverlay({
    appId: options.appId,
    position: options.position ?? 'bottom',
    userDismissible: options.userDismissible ?? true,
    campaignToken: options.campaignToken,
    providerToken: options.providerToken,
  });
}

/** Requests dismissal of the current overlay; safe if none is open. */
export async function dismissStoreOverlay(): Promise<void> {
  return getNativeTinykitFeature('StoreOverlay').dismissStoreOverlay();
}

export const StoreOverlay = {
  present: showStoreOverlay,
  dismiss: dismissStoreOverlay,
};
