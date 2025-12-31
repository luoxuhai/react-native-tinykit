import { TurboModuleRegistry, type TurboModule } from 'react-native';

export interface Spec extends TurboModule {
  restart(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Tinykit');
