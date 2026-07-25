import { AppError } from '../lib/errors.js';
import { hashPassword, verifyPassword } from '../lib/password.js';
import { userRepository } from '../repositories/userRepository.js';
import { authService, type PublicUser } from './authService.js';

const toPublic = (u: {
  id: string;
  email: string;
  name: string;
  openingBalance: { toNumber(): number };
}): PublicUser => ({
  id: u.id,
  email: u.email,
  name: u.name,
  openingBalance: u.openingBalance.toNumber(),
});

export const userService = {
  async updateProfile(userId: string, input: { name: string }): Promise<PublicUser> {
    const updated = await userRepository.updateName(userId, input.name);
    return toPublic(updated);
  },

  async updateOpeningBalance(
    userId: string,
    amount: number,
  ): Promise<{ openingBalance: number }> {
    const updated = await userRepository.updateOpeningBalance(userId, amount);
    return { openingBalance: updated.openingBalance.toNumber() };
  },

  async changePassword(
    userId: string,
    input: { currentPassword: string; newPassword: string },
  ): Promise<void> {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new AppError({ status: 404, code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    const ok = await verifyPassword(input.currentPassword, user.passwordHash);
    if (!ok) {
      throw new AppError({
        status: 401,
        code: 'INVALID_PASSWORD',
        message: 'Current password is incorrect',
      });
    }
    const newHash = await hashPassword(input.newPassword);
    await userRepository.updatePasswordHash(userId, newHash);
    await authService.revokeAllRefreshTokens(userId);
  },
};
