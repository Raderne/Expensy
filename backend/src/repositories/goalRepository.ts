import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';

// Soft-delete filtering and audit stamps are applied automatically by the
// Prisma client extensions (src/lib/prisma.ts), so reads never filter
// `deletedAt` and writes never set `*ById` manually.
export const goalRepository = {
  findByUser: (userId: string) =>
    prisma.goal.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'asc' }],
    }),

  findById: (id: string, userId: string) =>
    prisma.goal.findFirst({
      where: { id, userId },
    }),

  create: (input: {
    userId: string;
    name: string;
    icon: string;
    color: string;
    targetAmount: Prisma.Decimal;
    savedAmount: Prisma.Decimal;
    targetDate: Date | null;
  }) =>
    prisma.goal.create({
      data: input,
    }),

  update: (
    id: string,
    userId: string,
    data: Partial<{
      name: string;
      icon: string;
      color: string;
      targetAmount: Prisma.Decimal;
      savedAmount: Prisma.Decimal;
      targetDate: Date | null;
    }>,
  ) =>
    prisma.goal.updateMany({
      where: { id, userId },
      data,
    }),

  addFunds: (id: string, userId: string, amount: Prisma.Decimal) =>
    prisma.goal.updateMany({
      where: { id, userId },
      data: { savedAmount: { increment: amount } },
    }),

  // Persist the cached AI estimate payload + its freshness timestamp.
  saveEstimate: (id: string, userId: string, estimate: Prisma.InputJsonValue) =>
    prisma.goal.updateMany({
      where: { id, userId },
      data: { aiEstimate: estimate, aiEstimatedAt: new Date() },
    }),

  softDelete: (id: string, userId: string) =>
    prisma.goal.updateMany({
      where: { id, userId },
      data: { deletedAt: new Date() },
    }),
};
