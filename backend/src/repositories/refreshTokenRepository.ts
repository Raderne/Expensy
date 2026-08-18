import { createHash } from 'node:crypto';
import { prisma } from '../lib/prisma.js';

const sha256 = (value: string): string => createHash('sha256').update(value).digest('hex');

export const refreshTokenRepository = {
  hash: sha256,

  create: (data: { id: string; userId: string; tokenHash: string; expiresAt: Date }) =>
    prisma.refreshToken.create({ data }),

  findById: (id: string) => prisma.refreshToken.findFirst({ where: { id } }),

  findByTokenHash: (tokenHash: string) =>
    prisma.refreshToken.findFirst({ where: { tokenHash } }),

  revoke: (id: string, revokedAt: Date, replacedById?: string) =>
    prisma.refreshToken.update({
      where: { id },
      data: { revokedAt, ...(replacedById ? { replacedById } : {}) },
    }),

  revokeAllForUser: (userId: string, revokedAt: Date) =>
    prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt },
    }),
};

export type RefreshTokenRepository = typeof refreshTokenRepository;
