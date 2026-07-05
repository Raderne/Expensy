import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';

// Soft-delete filtering and audit stamps are applied automatically by the
// Prisma client extensions (src/lib/prisma.ts).
export const monthlyBudgetRepository = {
  findByUserMonth: (userId: string, month: string) =>
    prisma.monthlyBudget.findFirst({ where: { userId, month } }),

  // Batch fetch of the recorded budgets for a set of months (one query instead
  // of N). Used by the goal estimate to attach each analysed month's cap.
  findByUserMonths: (userId: string, months: string[]) =>
    prisma.monthlyBudget.findMany({ where: { userId, month: { in: months } } }),

  // Create or update the recorded budget amount for a month. Used when the user
  // edits their budget (current month) and by carry-forward on a new month.
  upsertAmount: (userId: string, month: string, amount: Prisma.Decimal) =>
    prisma.monthlyBudget.upsert({
      where: { userId_month: { userId, month } },
      create: { userId, month, amount },
      update: { amount },
    }),

  // Snapshot a finished month: record its computed spend and mark it closed.
  // Preserves an existing recorded amount; creates the row with `amount` when
  // the month was never persisted.
  upsertClose: (
    userId: string,
    month: string,
    amount: Prisma.Decimal,
    spent: Prisma.Decimal,
  ) =>
    prisma.monthlyBudget.upsert({
      where: { userId_month: { userId, month } },
      create: { userId, month, amount, spent, closed: true },
      update: { spent, closed: true },
    }),

  incrementAllocated: (userId: string, month: string, amount: Prisma.Decimal) =>
    prisma.monthlyBudget.updateMany({
      where: { userId, month },
      data: { allocated: { increment: amount } },
    }),

  // Closed months for a user that still have an unconsumed, unallocated
  // remainder (amount − spent − allocated > 0), newest first.
  listAllocatable: async (userId: string) => {
    const rows = await prisma.monthlyBudget.findMany({
      where: { userId, closed: true },
      orderBy: [{ month: 'desc' }],
    });
    return rows.filter((r) =>
      r.amount.minus(r.spent).minus(r.allocated).greaterThan(0),
    );
  },
};
