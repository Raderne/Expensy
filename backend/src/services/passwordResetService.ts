import { createHash, randomInt, timingSafeEqual } from 'node:crypto';
import { env } from '../config/env.js';
import { AppError } from '../lib/errors.js';
import { sendMail } from '../lib/mailer.js';
import { hashPassword } from '../lib/password.js';
import { passwordResetRepository } from '../repositories/passwordResetRepository.js';
import { userRepository } from '../repositories/userRepository.js';
import type { ForgotPasswordInput, ResetPasswordInput } from '../schemas/auth.js';

const sha256 = (value: string): string => createHash('sha256').update(value).digest('hex');

const hashesMatch = (a: string, b: string): boolean => {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  return bufA.length === bufB.length && timingSafeEqual(bufA, bufB);
};

const invalidCodeError = () =>
  new AppError({
    status: 400,
    code: 'INVALID_RESET_CODE',
    message: 'Invalid or expired reset code',
  });

export const passwordResetService = {
  /**
   * Issues a one-time reset code and emails it. Resolves silently whether or
   * not the email belongs to a real account, so callers can respond identically
   * and never leak which addresses are registered.
   */
  async requestReset(input: ForgotPasswordInput): Promise<void> {
    const user = await userRepository.findByEmail(input.email);
    if (!user) return;

    // Invalidate any outstanding codes before issuing a new one.
    await passwordResetRepository.deleteByUser(user.id);

    const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
    const expiresAt = new Date(Date.now() + env.RESET_CODE_TTL_MIN * 60_000);
    await passwordResetRepository.create({
      userId: user.id,
      codeHash: sha256(code),
      expiresAt,
    });

    await sendMail({
      to: user.email,
      subject: 'Your Expensy password reset code',
      text:
        `Hi ${user.name},\n\n` +
        `Your password reset code is ${code}. ` +
        `It expires in ${env.RESET_CODE_TTL_MIN} minutes.\n\n` +
        `If you didn't request this, you can safely ignore this email.`,
    });
  },

  /**
   * Verifies the code and sets the new password. Throws INVALID_RESET_CODE for
   * any failure (unknown email, wrong/expired/used code) so nothing is leaked.
   */
  async resetPassword(input: ResetPasswordInput): Promise<void> {
    const user = await userRepository.findByEmail(input.email);
    if (!user) throw invalidCodeError();

    const token = await passwordResetRepository.findActiveByUser(user.id, new Date());
    if (!token) throw invalidCodeError();

    if (!hashesMatch(token.codeHash, sha256(input.code))) throw invalidCodeError();

    const passwordHash = await hashPassword(input.newPassword);
    await userRepository.updatePasswordHash(user.id, passwordHash);
    await passwordResetRepository.markConsumed(token.id, new Date());
  },
};
