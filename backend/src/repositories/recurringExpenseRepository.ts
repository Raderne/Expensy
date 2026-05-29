import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';
import type { RecurrenceFrequency } from '../lib/recurrence.js';

export interface CreateRecurringExpenseInput {
  userId: string;
  categoryId: string;
  label: string;
  amount: Prisma.Decimal;
  frequency: RecurrenceFrequency;
  intervalDays: number | null;
  anchorDate: Date;
}

export type UpdateRecurringExpenseData = Partial<{
  categoryId: string;
  label: string;
  amount: Prisma.Decimal;
  frequency: RecurrenceFrequency;
  intervalDays: number | null;
  anchorDate: Date;
  isActive: boolean;
}>;

export const recurringExpenseRepository = {
  findByUser: (userId: string) =>
    prisma.recurringExpense.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'asc' }],
      include: { category: true },
    }),

  findActiveByUser: (userId: string) =>
    prisma.recurringExpense.findMany({
      where: { userId, isActive: true },
      orderBy: [{ createdAt: 'asc' }],
      include: { category: true },
    }),

  findById: (id: string, userId: string) =>
    prisma.recurringExpense.findFirst({
      where: { id, userId },
      include: { category: true },
    }),

  create: (input: CreateRecurringExpenseInput) =>
    prisma.recurringExpense.create({
      data: input,
      include: { category: true },
    }),

  update: (id: string, userId: string, data: UpdateRecurringExpenseData) =>
    prisma.recurringExpense.updateMany({
      where: { id, userId },
      data,
    }),

  softDelete: (id: string, userId: string) =>
    prisma.recurringExpense.updateMany({
      where: { id, userId },
      data: { deletedAt: new Date(), isActive: false },
    }),
};
