import {
  TurboModuleRegistry,
  type TurboModule,
  type CodegenTypes,
} from 'react-native';

/**
 * Thermal state values that indicate the current thermal condition of the device.
 * - 'nominal': The thermal state is within normal limits.
 * - 'fair': The thermal state is slightly elevated.
 * - 'serious': The thermal state is high.
 * - 'critical': The thermal state is critically high.
 */
export type ThermalState = 'nominal' | 'fair' | 'serious' | 'critical';

/**
 * Event payload for thermal state change events.
 */
export type ThermalStateChangeEvent = {
  thermalState: ThermalState;
};

export interface Spec extends TurboModule {
  restart(): void;
  getThermalState(): ThermalState;
  readonly onThermalStateChange: CodegenTypes.EventEmitter<ThermalStateChangeEvent>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('Tinykit');
