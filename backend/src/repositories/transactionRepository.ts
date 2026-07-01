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
  // Raw query (the soft-delete extension doesn't cover $queryRaw, so we add
  // `deletedAt IS NULL` manually) computing three figures in one pass:
  //   balance  — lifetime SUM(amount), real cash incl. reimbursements
  //   income   — month inflows, EXCLUDING reimbursements (not real income)
  //   expenses — month spending as a positive magnitude, counting only the
  //              user's own share: SUM(amount + sharedOwedTotal) for amount < 0
  summarize: async (
    userId: string,
    from: Date,
    to: Date,
  ): Promise<{ balance: number; income: number; expenses: number }> => {
    const rows = await prisma.$queryRaw<{ balance: number; income: number; expenses: number }[]>`
      SELECT
        COALESCE(SUM("amount"), 0)::float8 AS balance,
        COALESCE(SUM("amount") FILTER (
          WHERE "occurredAt" >= ${from} AND "occurredAt" < ${to}
            AND "amount" > 0 AND "isReimbursement" = false
        ), 0)::float8 AS income,
        COALESCE(-SUM("amount" + "sharedOwedTotal") FILTER (
          WHERE "occurredAt" >= ${from} AND "occurredAt" < ${to} AND "amount" < 0
        ), 0)::float8 AS expenses
      FROM "Transaction"
      WHERE "userId" = ${userId} AND "deletedAt" IS NULL
    `;
    return rows[0] ?? { balance: 0, income: 0, expenses: 0 };
  },

  findRecent: (userId: string, limit: number) =>
    prisma.transaction.findMany({
      where: { userId },
      orderBy: [{ occurredAt: 'desc' }, { createdAt: 'desc' }],
      take: limit,
      include: { category: true, splits: { include: { contact: true } } },
    }),

  // Creates a transaction and, when `splits` are provided, its TransactionSplit
  // rows atomically. `sharedOwedTotal` should equal the sum of split owedAmounts
  // so spending aggregations can subtract the portion owed by others.
  create: (input: {
    userId: string;
    categoryId: string;
    amount: Prisma.Decimal;
    note?: string;
    occurredAt: Date;
    recurringIncomeId?: string;
    recurringExpenseId?: string;
    sharedOwedTotal?: Prisma.Decimal;
    isReimbursement?: boolean;
    splits?: { contactId: string; owedAmount: Prisma.Decimal }[];
  }) => {
    const data = {
      userId: input.userId,
      categoryId: input.categoryId,
      amount: input.amount,
      note: input.note,
      occurredAt: input.occurredAt,
      recurringIncomeId: input.recurringIncomeId,
      recurringExpenseId: input.recurringExpenseId,
      sharedOwedTotal: input.sharedOwedTotal,
      isReimbursement: input.isReimbursement,
    };

    if (!input.splits || input.splits.length === 0) {
      return prisma.transaction.create({
        data,
        include: { category: true, splits: { include: { contact: true } } },
      });
    }

    return prisma.$transaction(async (tx) => {
      const created = await tx.transaction.create({ data, include: { category: true } });
      await tx.transactionSplit.createMany({
        data: input.splits!.map((s) => ({
          userId: input.userId,
          transactionId: created.id,
          contactId: s.contactId,
          owedAmount: s.owedAmount,
        })),
      });
      return tx.transaction.findFirstOrThrow({
        where: { id: created.id },
        include: { category: true, splits: { include: { contact: true } } },
      });
    });
  },

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
    const from = new Date(Date.UTC(year, m - 1, 1));
    const to = new Date(Date.UTC(year, m, 1));
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
      include: { category: true, splits: { include: { contact: true } } },
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
      include: { category: true, splits: { include: { contact: true } } },
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

  countByCategory: (categoryId: string, userId: string) =>
    prisma.transaction.count({ where: { categoryId, userId } }),

  // Phase 06 — group expense rows by category for the donut + breakdown bars.
  // Counts only the user's own share: SUM(amount + sharedOwedTotal), negated to
  // a positive magnitude. Raw query so the shared-owed offset is applied inside
  // the aggregate (and `deletedAt IS NULL` added manually).
  groupExpensesByCategory: (
    userId: string,
    from: Date,
    to: Date,
  ): Promise<{ categoryId: string; amount: number }[]> =>
    prisma.$queryRaw`
      SELECT "categoryId", (-SUM("amount" + "sharedOwedTotal"))::float8 AS amount
      FROM "Transaction"
      WHERE "userId" = ${userId} AND "deletedAt" IS NULL AND "amount" < 0
        AND "occurredAt" >= ${from} AND "occurredAt" < ${to}
      GROUP BY "categoryId"
    `,
};
