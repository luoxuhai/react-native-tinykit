import { TurboModuleRegistry } from 'react-native';
import type { Spec } from './NativeTinykit';

export type TinykitFeature =
  | 'Restart'
  | 'ThermalState'
  | 'Review'
  | 'KeepAwake'
  | 'ColorPicker'
  | 'Haptics'
  | 'Mail';

let nativeTinykit: Spec | undefined;
let enabledFeatures: ReadonlySet<string> | undefined;

export function getNativeTinykit(): Spec {
  nativeTinykit ??= TurboModuleRegistry.getEnforcing<Spec>('Tinykit');
  return nativeTinykit;
}

export function getNativeTinykitFeature(feature: TinykitFeature): Spec {
  const tinykit = getNativeTinykit();
  enabledFeatures ??= new Set(tinykit.getEnabledFeatures());

  if (!enabledFeatures.has(feature)) {
    throw new Error(
      `[TinyKit] The ${feature} feature is not installed. ` +
        `Add '${feature}' to setup_tinykit in your Podfile and run pod install.`
    );
  }

  return tinykit;
}
