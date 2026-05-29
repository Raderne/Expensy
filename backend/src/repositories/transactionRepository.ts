import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';

// Page size for paginated transaction list (Phase 05).
// We over-fetch by 1 to know whether a next page exists without a second count.
export const PAGE_SIZE = 30;

export interface ListFilters {
  userId: string;
  from?: Date;
  to?: Date;
  categoryId?: string;
  type?: 'income' | 'expense';
  cursor?: { occurredAt: Date; id: string };
}

const buildListWhere = (f: ListFilters): Prisma.TransactionWhereInput => {
  const where: Prisma.TransactionWhereInput = { userId: f.userId };

  if (f.from && f.to) {
    where.occurredAt = { gte: f.from, lt: f.to };
  }
  if (f.categoryId) {
    where.categoryId = f.categoryId;
  }
  if (f.type === 'income') {
    where.amount = { gt: 0 };
  } else if (f.type === 'expense') {
    where.amount = { lt: 0 };
  }

  // Cursor: keyset on (occurredAt DESC, id DESC). Strictly past the cursor.
  if (f.cursor) {
    where.OR = [
      { occurredAt: { lt: f.cursor.occurredAt } },
      { occurredAt: f.cursor.occurredAt, id: { lt: f.cursor.id } },
    ];
  }

  return where;
};

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

  create: (input: {
    userId: string;
    categoryId: string;
    amount: Prisma.Decimal;
    note?: string;
    occurredAt: Date;
    recurringIncomeId?: string;
    recurringExpenseId?: string;
  }) =>
    prisma.transaction.create({
      data: {
        userId: input.userId,
        categoryId: input.categoryId,
        amount: input.amount,
        note: input.note,
        occurredAt: input.occurredAt,
        recurringIncomeId: input.recurringIncomeId,
        recurringExpenseId: input.recurringExpenseId,
      },
      include: { category: true },
    }),

  findByRecurringExpenseOnDay: (
    recurringExpenseId: string,
    userId: string,
    dayStart: Date,
    dayEnd: Date,
  ) =>
    prisma.transaction.findFirst({
      where: {
        userId,
        recurringExpenseId,
        occurredAt: { gte: dayStart, lt: dayEnd },
      },
    }),

  findByRecurringInMonth: (recurringIncomeId: string, userId: string, month: string) => {
    const sep = month.indexOf('-');
    const year = parseInt(month.slice(0, sep), 10);
    const m = parseInt(month.slice(sep + 1), 10);
    const from = new Date(year, m - 1, 1);
    const to = new Date(year, m, 1);
    return prisma.transaction.findFirst({
      where: {
        userId,
        recurringIncomeId,
        occurredAt: { gte: from, lt: to },
      },
    });
  },

  update: (
    id: string,
    userId: string,
    data: Partial<{ amount: Prisma.Decimal; note: string; occurredAt: Date }>,
  ) =>
    prisma.transaction.updateMany({
      where: { id, userId },
      data,
    }),

  findById: (id: string, userId: string) =>
    prisma.transaction.findFirst({
      where: { id, userId },
      include: { category: true },
    }),

  softDelete: (id: string, userId: string) =>
    prisma.transaction.updateMany({
      where: { id, userId },
      data: { deletedAt: new Date() },
    }),

  list: (filters: ListFilters) =>
    prisma.transaction.findMany({
      where: buildListWhere(filters),
      orderBy: [{ occurredAt: 'desc' }, { id: 'desc' }],
      take: PAGE_SIZE + 1,
      include: { category: true },
    }),

  // Distinct YYYY-MM month buckets the user has transactions in, newest first.
  // Raw query because the soft-delete extension doesn't cover $queryRaw — we
  // add `deletedAt IS NULL` manually.
  findMonths: (userId: string): Promise<{ month: string }[]> =>
    prisma.$queryRaw<{ month: string }[]>`
      SELECT to_char(date_trunc('month', "occurredAt"), 'YYYY-MM') AS month
      FROM "Transaction"
      WHERE "userId" = ${userId} AND "deletedAt" IS NULL
      GROUP BY 1
      ORDER BY 1 DESC
    `,

  // Phase 06 — group expense rows by category for the donut + breakdown bars.
  // amount < 0 selects expenses only; the absolute sum is computed in the
  // service so we can keep returning a Decimal here.
  groupExpensesByCategory: (userId: string, from: Date, to: Date) =>
    prisma.transaction.groupBy({
      by: ['categoryId'],
      where: {
        userId,
        amount: { lt: 0 },
        occurredAt: { gte: from, lt: to },
      },
      _sum: { amount: true },
    }),
};
