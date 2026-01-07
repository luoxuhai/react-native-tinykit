import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  restart(): void;
  getBatteryLevel(): number;
  isLowPowerModeEnabled(): boolean;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Tinykit');
