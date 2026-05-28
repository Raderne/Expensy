import { prisma } from '../lib/prisma.js';

export const budgetRepository = {
  findByUser: (userId: string) => prisma.budget.findFirst({ where: { userId } }),

  upsert: (userId: string, amount: number) =>
    prisma.budget.upsert({
      where: { userId },
      create: { userId, amount },
      update: { amount },
    }),
};
