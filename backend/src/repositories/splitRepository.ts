import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';
import { deriveSplitStatus } from '../services/splitMapper.js';

export const splitRepository = {
  // Splits with money still owed, plus everything needed to render the
  // "who owes me" surface. Only splits on live (non-deleted) transactions count.
  findOutstanding: (userId: string) =>
    prisma.transactionSplit.findMany({
      where: {
        userId,
        status: { in: ['OWED', 'PARTIAL'] },
        transaction: { deletedAt: null },
      },
      orderBy: [{ contactId: 'asc' }, { createdAt: 'asc' }],
      include: {
        contact: true,
        transaction: { include: { category: true } },
        reimbursements: {
          where: { deletedAt: null },
          orderBy: { occurredAt: 'desc' },
        },
      },
    }),

  findById: (id: string, userId: string) =>
    prisma.transactionSplit.findFirst({
      where: { id, userId },
      include: { contact: true },
    }),

  // Soft-delete every split attached to a transaction (called when the parent
  // expense is deleted) so phantom debt never lingers on the owed surface.
  cancelForTransaction: (transactionId: string, userId: string) =>
    prisma.transactionSplit.updateMany({
      where: { transactionId, userId, deletedAt: null },
      data: { deletedAt: new Date() },
    }),

  // Record a (partial) repayment: create the Reimbursement, the matching inflow
  // Transaction (excluded from income, counted in balance), and advance the
  // split's settled total — all atomically.
  settle: (input: {
    userId: string;
    splitId: string;
    contactId: string;
    incomeCategoryId: string;
    note: string;
    amount: Prisma.Decimal;
    owedAmount: Prisma.Decimal;
    currentSettled: Prisma.Decimal;
    occurredAt: Date;
  }) =>
    prisma.$transaction(async (tx) => {
      const inflow = await tx.transaction.create({
        data: {
          userId: input.userId,
          categoryId: input.incomeCategoryId,
          amount: input.amount,
          note: input.note,
          occurredAt: input.occurredAt,
          isReimbursement: true,
        },
      });

      await tx.reimbursement.create({
        data: {
          userId: input.userId,
          splitId: input.splitId,
          contactId: input.contactId,
          amount: input.amount,
          occurredAt: input.occurredAt,
          transactionId: inflow.id,
        },
      });

      const newSettled = input.currentSettled.plus(input.amount);
      await tx.transactionSplit.update({
        where: { id: input.splitId },
        data: {
          settledAmount: newSettled,
          status: deriveSplitStatus(input.owedAmount, newSettled),
        },
      });
    }),

  findReimbursementById: (id: string, userId: string) =>
    prisma.reimbursement.findFirst({
      where: { id, userId },
      include: { split: true },
    }),

  // Reverse a repayment: soft-delete the reimbursement and its inflow
  // transaction, then roll the split's settled total back.
  reverse: (input: {
    reimbursementId: string;
    userId: string;
    transactionId: string | null;
    splitId: string;
    owedAmount: Prisma.Decimal;
    amount: Prisma.Decimal;
    currentSettled: Prisma.Decimal;
  }) =>
    prisma.$transaction(async (tx) => {
      const now = new Date();
      await tx.reimbursement.update({
        where: { id: input.reimbursementId },
        data: { deletedAt: now },
      });
      if (input.transactionId) {
        await tx.transaction.update({
          where: { id: input.transactionId },
          data: { deletedAt: now },
        });
      }
      const newSettled = Prisma.Decimal.max(0, input.currentSettled.minus(input.amount));
      await tx.transactionSplit.update({
        where: { id: input.splitId },
        data: {
          settledAmount: newSettled,
          status: deriveSplitStatus(input.owedAmount, newSettled),
        },
      });
    }),
};
