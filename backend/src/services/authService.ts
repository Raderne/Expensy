import { randomUUID } from 'node:crypto';
import { AppError } from '../lib/errors.js';
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../lib/jwt.js';
import { hashPassword, verifyPassword } from '../lib/password.js';
import { refreshTokenRepository } from '../repositories/refreshTokenRepository.js';
import { userRepository } from '../repositories/userRepository.js';
import type { LoginInput, SignupInput } from '../schemas/auth.js';

export interface PublicUser {
  id: string;
  email: string;
  name: string;
  openingBalance: number;
}

export interface AuthResult {
  user: PublicUser;
  accessToken: string;
  refreshToken: string;
}

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

const invalidRefresh = () =>
  new AppError({
    status: 401,
    code: 'INVALID_REFRESH',
    message: 'Invalid or expired refresh token',
  });

const issueTokens = async (userId: string): Promise<{ accessToken: string; refreshToken: string }> => {
  const jti = randomUUID();
  const refreshToken = signRefreshToken(userId, jti);
  const payload = verifyRefreshToken(refreshToken);
  if (!payload.exp) throw new Error('Refresh token missing exp');

  await refreshTokenRepository.create({
    id: jti,
    userId,
    tokenHash: refreshTokenRepository.hash(refreshToken),
    expiresAt: new Date(payload.exp * 1000),
  });

  return {
    accessToken: signAccessToken(userId),
    refreshToken,
  };
};

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
    return { user: toPublic(user), ...(await issueTokens(user.id)) };
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
    return { user: toPublic(user), ...(await issueTokens(user.id)) };
  },

  async refresh(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    let payload;
    try {
      payload = verifyRefreshToken(refreshToken);
    } catch {
      throw invalidRefresh();
    }

    const stored = await refreshTokenRepository.findById(payload.jti);
    if (!stored || stored.userId !== payload.sub) {
      throw invalidRefresh();
    }

    const tokenHash = refreshTokenRepository.hash(refreshToken);
    if (stored.tokenHash !== tokenHash) {
      throw invalidRefresh();
    }

    // Reuse of an already-rotated token → revoke all sessions for this user.
    if (stored.revokedAt) {
      if (stored.replacedById) {
        await refreshTokenRepository.revokeAllForUser(stored.userId, new Date());
      }
      throw invalidRefresh();
    }

    if (stored.expiresAt.getTime() <= Date.now()) {
      await refreshTokenRepository.revoke(stored.id, new Date());
      throw invalidRefresh();
    }

    const user = await userRepository.findById(payload.sub);
    if (!user) {
      throw new AppError({
        status: 401,
        code: 'INVALID_REFRESH',
        message: 'User no longer exists',
      });
    }

    const next = await issueTokens(user.id);
    const nextJti = verifyRefreshToken(next.refreshToken).jti;
    await refreshTokenRepository.revoke(stored.id, new Date(), nextJti);
    return next;
  },

  async revokeAllRefreshTokens(userId: string): Promise<void> {
    await refreshTokenRepository.revokeAllForUser(userId, new Date());
  },

  async me(userId: string): Promise<PublicUser> {
    const user = await userRepository.findById(userId);
    if (!user) {
      throw new AppError({ status: 404, code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    return toPublic(user);
  },
};
