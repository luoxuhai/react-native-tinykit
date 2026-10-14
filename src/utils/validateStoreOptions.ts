export function storeOptionsError(code: string, message: string): Error {
  return Object.assign(new Error(`[TinyKit] ${message}`), { code });
}

export function validateStoreOptions(
  options: { appId: string },
  tokenNames: ReadonlyArray<string>,
  code: string
): void {
  if (!options || typeof options !== 'object' || Array.isArray(options)) {
    throw storeOptionsError(code, 'Store options must be an object.');
  }
  if (
    typeof options.appId !== 'string' ||
    options.appId.length === 0 ||
    /[^0-9]/.test(options.appId) ||
    !/[1-9]/.test(options.appId)
  ) {
    throw storeOptionsError(
      code,
      'appId must be a positive numeric App Store ID string without the "id" prefix.'
    );
  }
  const significantDigits = options.appId.replace(/^0+/, '');
  const maximumAppId = '18446744073709551615';
  if (
    significantDigits.length > maximumAppId.length ||
    (significantDigits.length === maximumAppId.length &&
      significantDigits > maximumAppId)
  ) {
    throw storeOptionsError(
      code,
      'appId exceeds the supported App Store ID range.'
    );
  }
  for (const name of tokenNames) {
    const value = (options as Record<string, unknown>)[name];
    if (value !== undefined && (typeof value !== 'string' || !value.trim())) {
      throw storeOptionsError(code, `${name} must be a non-empty string.`);
    }
  }
}
