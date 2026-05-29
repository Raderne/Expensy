import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';

export const recurringIncomeRepository = {
  findByUser: (userId: string) =>
    prisma.recurringIncome.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'asc' }],
    }),

  findById: (id: string, userId: string) =>
    prisma.recurringIncome.findFirst({
      where: { id, userId },
    }),

  create: (input: {
    userId: string;
    label: string;
    amount: Prisma.Decimal;
    dayOfMonth: number;
  }) =>
    prisma.recurringIncome.create({
      data: input,
    }),

  update: (
    id: string,
    userId: string,
    data: Partial<{ label: string; amount: Prisma.Decimal; dayOfMonth: number; isActive: boolean }>,
  ) =>
    prisma.recurringIncome.updateMany({
      where: { id, userId },
      data,
    }),

  softDelete: (id: string, userId: string) =>
    prisma.recurringIncome.updateMany({
      where: { id, userId },
      data: { deletedAt: new Date(), isActive: false },
    }),
};
