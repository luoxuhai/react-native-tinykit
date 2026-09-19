import { getNativeTinykitFeature } from '../utils/getNativeTinykit';
import type {
  ImpactFeedbackStyle,
  NotificationFeedbackType,
} from '../utils/NativeTinykit';

export type {
  ImpactFeedbackStyle,
  NotificationFeedbackType,
} from '../utils/NativeTinykit';

/**
 * Triggers an impact haptic feedback.
 */
export function impact(style: ImpactFeedbackStyle): void {
  getNativeTinykitFeature('Haptics').impact(style);
}

/**
 * Triggers a selection haptic feedback.
 */
export function selection(): void {
  getNativeTinykitFeature('Haptics').selection();
}

/**
 * Triggers a notification haptic feedback.
 */
export function notification(type: NotificationFeedbackType): void {
  getNativeTinykitFeature('Haptics').notification(type);
}
