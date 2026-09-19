import { Platform, UIManager, type NativeMethods } from 'react-native';
import {
  getNativeTinykit,
  getNativeTinykitFeature,
} from '../utils/getNativeTinykit';
import type {
  NativeTranslationOptions,
  TranslationAnchor,
  TranslationResult,
} from '../utils/NativeTinykit';

export type {
  TranslationAnchor,
  TranslationResult,
} from '../utils/NativeTinykit';

export type TranslationOptions = NativeTranslationOptions & {
  /** Native view ref.current or React tag, measured before opening on iPad. */
  targetViewNode?: Pick<NativeMethods, 'measureInWindow'> | number | null;
};

function translationError(code: string, message: string): Error {
  return Object.assign(new Error(`[TinyKit] ${message}`), { code });
}

function validateAnchor(anchor: TranslationAnchor): void {
  if (
    !anchor ||
    ![anchor.x, anchor.y, anchor.width, anchor.height].every(Number.isFinite) ||
    anchor.width <= 0 ||
    anchor.height <= 0
  ) {
    throw translationError(
      'E_TRANSLATION_INVALID_ANCHOR',
      'Translation anchor must be a finite rectangle with positive dimensions.'
    );
  }
}

function measureAnchor(
  target: NonNullable<TranslationOptions['targetViewNode']>
): Promise<TranslationAnchor> {
  return new Promise((resolve, reject) => {
    // Unmounted native refs may never invoke their measurement callback.
    const timeout = setTimeout(() => {
      reject(
        translationError(
          'E_TRANSLATION_INVALID_ANCHOR',
          'Unable to measure the translation target. Use a mounted native view.'
        )
      );
    }, 1000);
    const measured = (x: number, y: number, width: number, height: number) => {
      clearTimeout(timeout);
      try {
        const anchor = { x, y, width, height };
        validateAnchor(anchor);
        resolve(anchor);
      } catch (error) {
        reject(error);
      }
    };
    try {
      if (
        typeof target === 'number' &&
        Number.isInteger(target) &&
        target > 0
      ) {
        UIManager.measureInWindow(target, measured);
      } else if (typeof target === 'object' && target?.measureInWindow) {
        target.measureInWindow(measured);
      } else {
        throw translationError(
          'E_TRANSLATION_INVALID_ANCHOR',
          'targetViewNode must be a native view ref.current or a React tag.'
        );
      }
    } catch (error) {
      clearTimeout(timeout);
      reject(error);
    }
  });
}

/** Whether the installed feature can present on this device (iOS 17.4+). */
export function isTranslationSupported(): boolean {
  if (Platform.OS !== 'ios') return false;
  const native = getNativeTinykit();
  return (
    native.getEnabledFeatures().includes('Translation') &&
    native.isTranslationSupported()
  );
}

/** Resolves after dismissal, or with text when the user chooses Replace. */
export async function showTranslation(
  options: TranslationOptions
): Promise<TranslationResult> {
  if (Platform.OS !== 'ios') {
    throw translationError(
      'E_TRANSLATION_UNAVAILABLE',
      'Translation requires a physical iOS device running iOS 17.4 or later.'
    );
  }
  const native = getNativeTinykitFeature('Translation');
  if (typeof options?.text !== 'string' || !options.text.trim()) {
    throw translationError(
      'E_TRANSLATION_INVALID_TEXT',
      'Translation text must be a non-empty string.'
    );
  }
  if (
    options.arrowEdge !== undefined &&
    !['top', 'bottom', 'leading', 'trailing'].includes(options.arrowEdge)
  ) {
    throw translationError(
      'E_TRANSLATION_INVALID_OPTIONS',
      'Invalid translation arrowEdge.'
    );
  }
  if (
    options.allowsReplacement !== undefined &&
    typeof options.allowsReplacement !== 'boolean'
  ) {
    throw translationError(
      'E_TRANSLATION_INVALID_OPTIONS',
      'allowsReplacement must be a boolean.'
    );
  }
  if (options.anchor !== undefined && options.targetViewNode != null) {
    throw translationError(
      'E_TRANSLATION_INVALID_ANCHOR',
      'Specify either anchor or targetViewNode, not both.'
    );
  }
  let anchor = options.anchor;
  if (anchor !== undefined) validateAnchor(anchor);
  if (!native.isTranslationSupported()) {
    throw translationError(
      'E_TRANSLATION_UNAVAILABLE',
      'Translation requires a physical iOS device running iOS 17.4 or later.'
    );
  }
  if (options.targetViewNode != null) {
    anchor = await measureAnchor(options.targetViewNode);
  }
  return native.showTranslation({
    text: options.text,
    anchor,
    arrowEdge: options.arrowEdge,
    allowsReplacement: options.allowsReplacement,
  });
}

/** Closes the current panel; resolves immediately if none is open. */
export async function dismissTranslation(): Promise<void> {
  if (Platform.OS !== 'ios') return;
  return getNativeTinykitFeature('Translation').dismissTranslation();
}

/** Compatibility with react-native-ios-translation's named import. */
export const present = showTranslation;

export const Translation = {
  present: showTranslation,
  dismiss: dismissTranslation,
  isSupported: isTranslationSupported,
};
