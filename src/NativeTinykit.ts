import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  restart(): void;
  getBatteryLevel(): Promise<number>;
  isLowPowerModeEnabled(): Promise<boolean>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Tinykit');
