import { prisma } from '../lib/prisma.js';

export const transactionRepository = {
  summarize: (userId: string, from: Date, to: Date) =>
    Promise.all([
      prisma.transaction.aggregate({
        where: { userId },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: { userId, occurredAt: { gte: from, lt: to }, amount: { gt: 0 } },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: { userId, occurredAt: { gte: from, lt: to }, amount: { lt: 0 } },
        _sum: { amount: true },
      }),
    ]),

  findRecent: (userId: string, limit: number) =>
    prisma.transaction.findMany({
      where: { userId },
      orderBy: [{ occurredAt: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      include: { category: true },
    }),
};
