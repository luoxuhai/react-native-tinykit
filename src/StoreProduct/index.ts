import { getNativeTinykitFeature } from '../utils/getNativeTinykit';
import type { StoreProductOptions } from '../utils/NativeTinykit';
import { validateStoreOptions } from '../utils/validateStoreOptions';

export type { StoreProductOptions } from '../utils/NativeTinykit';

/** Loads and presents an App Store page; resolves when the page closes. */
export async function showStoreProduct(
  options: StoreProductOptions
): Promise<void> {
  validateStoreOptions(
    options,
    ['affiliateToken', 'campaignToken', 'providerToken'],
    'E_STORE_PRODUCT_INVALID_OPTIONS'
  );
  return getNativeTinykitFeature('StoreProduct').showStoreProduct({
    appId: options.appId,
    affiliateToken: options.affiliateToken,
    campaignToken: options.campaignToken,
    providerToken: options.providerToken,
  });
}

/** Closes the current page or cancels loading; safe if none is open. */
export async function dismissStoreProduct(): Promise<void> {
  return getNativeTinykitFeature('StoreProduct').dismissStoreProduct();
}

export const StoreProduct = {
  present: showStoreProduct,
  dismiss: dismissStoreProduct,
};
