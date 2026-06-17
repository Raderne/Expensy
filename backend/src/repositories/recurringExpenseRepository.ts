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

const withShares = {
  category: true,
  shares: { include: { contact: true } },
} as const;

export interface ShareInput {
  contactId: string;
  shareType: 'AMOUNT' | 'PERCENT';
  shareValue: Prisma.Decimal;
}

export const recurringExpenseRepository = {
  findByUser: (userId: string) =>
    prisma.recurringExpense.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'asc' }],
      include: withShares,
    }),

  findActiveByUser: (userId: string) =>
    prisma.recurringExpense.findMany({
      where: { userId, isActive: true },
      orderBy: [{ createdAt: 'asc' }],
      include: withShares,
    }),

  findById: (id: string, userId: string) =>
    prisma.recurringExpense.findFirst({
      where: { id, userId },
      include: withShares,
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

  // Replace the rule's split template: soft-delete the current shares, then
  // create the new set. Reads filter out soft-deleted rows, so old templates
  // never resurface. Pass an empty array to simply clear all shares.
  replaceShares: (recurringExpenseId: string, userId: string, shares: ShareInput[]) =>
    prisma.$transaction(async (tx) => {
      await tx.recurringExpenseShare.updateMany({
        where: { recurringExpenseId, userId, deletedAt: null },
        data: { deletedAt: new Date() },
      });
      if (shares.length > 0) {
        await tx.recurringExpenseShare.createMany({
          data: shares.map((s) => ({
            userId,
            recurringExpenseId,
            contactId: s.contactId,
            shareType: s.shareType,
            shareValue: s.shareValue,
          })),
        });
      }
    }),
};
