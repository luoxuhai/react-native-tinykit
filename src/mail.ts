import { Linking } from 'react-native';
import { getNativeTinykit, getNativeTinykitFeature } from './getNativeTinykit';
import type { MailOptions, MailResult } from './NativeTinykit';

export type { MailAttachment, MailOptions, MailResult } from './NativeTinykit';

/**
 * Returns whether the device is configured to send mail with the native iOS
 * mail composer.
 */
export function canSendMail(): boolean {
  return getNativeTinykit().canSendMail();
}

/**
 * Presents the native iOS mail composer when available, otherwise opens a
 * mailto URL with the first recipient.
 */
export async function openMail(options: MailOptions = {}): Promise<MailResult> {
  if (canSendMail()) {
    return getNativeTinykitFeature('Mail').openMail(options);
  }

  const email = options.recipients?.[0] ?? '';
  const url = `mailto:${email}`;
  const canOpen = await Linking.canOpenURL(url);

  if (!canOpen) {
    throw new Error(`[TinyKit] Unable to open mail URL: ${url}`);
  }

  await Linking.openURL(url);
  return 'opened';
}
