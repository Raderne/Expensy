import { AppError } from '../lib/errors.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../lib/jwt.js';
import { hashPassword, verifyPassword } from '../lib/password.js';
import { userRepository } from '../repositories/userRepository.js';
import type { LoginInput, SignupInput } from '../schemas/auth.js';

export interface PublicUser {
  id: string;
  email: string;
  name: string;
}

export interface AuthResult {
  user: PublicUser;
  accessToken: string;
  refreshToken: string;
}

const toPublic = (u: { id: string; email: string; name: string }): PublicUser => ({
  id: u.id,
  email: u.email,
  name: u.name,
});

const issueTokens = (userId: string) => ({
  accessToken: signAccessToken(userId),
  refreshToken: signRefreshToken(userId),
});

export const authService = {
  async signup(input: SignupInput): Promise<AuthResult> {
    const existing = await userRepository.findByEmail(input.email);
    if (existing) {
      throw new AppError({
        status: 409,
        code: 'EMAIL_TAKEN',
        message: 'Email already registered',
      });
    }
    const passwordHash = await hashPassword(input.password);
    const user = await userRepository.create({
      email: input.email,
      passwordHash,
      name: input.name,
    });
    return { user: toPublic(user), ...issueTokens(user.id) };
  },

  async login(input: LoginInput): Promise<AuthResult> {
    const user = await userRepository.findByEmail(input.email);
    if (!user) {
      throw new AppError({
        status: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }
    const ok = await verifyPassword(input.password, user.passwordHash);
    if (!ok) {
      throw new AppError({
        status: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }
    return { user: toPublic(user), ...issueTokens(user.id) };
  },

  async refresh(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    let payload;
    try {
      payload = verifyRefreshToken(refreshToken);
    } catch {
      throw new AppError({
        status: 401,
        code: 'INVALID_REFRESH',
        message: 'Invalid or expired refresh token',
      });
    }
    const user = await userRepository.findById(payload.sub);
    if (!user) {
      throw new AppError({
        status: 401,
        code: 'INVALID_REFRESH',
        message: 'User no longer exists',
      });
    }
    return issueTokens(user.id);
  },

  async me(userId: string): Promise<PublicUser> {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new AppError({ status: 404, code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    return toPublic(user);
  },
};
