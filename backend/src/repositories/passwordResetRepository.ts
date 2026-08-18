import { prisma } from '../lib/prisma.js';

export const passwordResetRepository = {
  create: (data: { userId: string; codeHash: string; expiresAt: Date }) =>
    prisma.passwordResetToken.create({ data }),

  // Most recent unconsumed, unexpired token for the user.
  findActiveByUser: (userId: string, now: Date) =>
    prisma.passwordResetToken.findFirst({
      where: { userId, consumedAt: null, expiresAt: { gt: now } },
      orderBy: { createdAt: 'desc' },
    }),

  markConsumed: (id: string, consumedAt: Date) =>
    prisma.passwordResetToken.update({ where: { id }, data: { consumedAt } }),

  incrementFailedAttempts: async (id: string): Promise<number> => {
    const updated = await prisma.passwordResetToken.update({
      where: { id },
      data: { failedAttempts: { increment: 1 } },
      select: { failedAttempts: true },
    });
    return updated.failedAttempts;
  },

  // Invalidate any prior codes before issuing a fresh one.
  deleteByUser: (userId: string) =>
    prisma.passwordResetToken.deleteMany({ where: { userId } }),
};

export type PasswordResetRepository = typeof passwordResetRepository;
