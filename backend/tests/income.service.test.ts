import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';

type StoredRecurring = {
  id: string;
  userId: string;
  label: string;
  amount: Prisma.Decimal;
  dayOfMonth: number;
  isActive: boolean;
  createdAt: Date;
  deletedAt: Date | null;
};

type StoredTx = {
  id: string;
  userId: string;
  categoryId: string;
  amount: Prisma.Decimal;
  note: string | null;
  occurredAt: Date;
  recurringIncomeId: string | null;
};

const recurringStore = new Map<string, StoredRecurring>();
const txStore = new Map<string, StoredTx>();
let txCounter = 0;
let recurringCounter = 0;

const INCOME_CATEGORY_ID = 'cat_income';

vi.mock('../src/repositories/budgetRepository.js', () => ({
  budgetRepository: {
    findByUser: vi.fn(async () => null),
  },
}));

vi.mock('../src/repositories/categoryRepository.js', () => ({
  categoryRepository: {
    findAll: vi.fn(async () => [
      {
        id: INCOME_CATEGORY_ID,
        key: 'income',
        label: 'Income',
        abbr: 'IN',
        color: '#16A34A',
        bgTint: '#DCFCE7',
      },
    ]),
  },
}));

vi.mock('../src/repositories/recurringIncomeRepository.js', () => ({
  recurringIncomeRepository: {
    findByUser: vi.fn(async (userId: string) =>
      [...recurringStore.values()].filter((r) => r.userId === userId && r.deletedAt == null),
    ),
    findById: vi.fn(async (id: string, userId: string) => {
      const row = recurringStore.get(id);
      if (!row || row.userId !== userId || row.deletedAt) return null;
      return row;
    }),
    create: vi.fn(
      async (input: {
        userId: string;
        label: string;
        amount: Prisma.Decimal;
        dayOfMonth: number;
      }) => {
        recurringCounter += 1;
        const row: StoredRecurring = {
          id: `rec_${recurringCounter}`,
          userId: input.userId,
          label: input.label,
          amount: input.amount,
          dayOfMonth: input.dayOfMonth,
          isActive: true,
          createdAt: new Date(),
          deletedAt: null,
        };
        recurringStore.set(row.id, row);
        return row;
      },
    ),
    update: vi.fn(async (id: string, userId: string, data: Partial<StoredRecurring>) => {
      const row = recurringStore.get(id);
      if (!row || row.userId !== userId) return { count: 0 };
      Object.assign(row, data);
      return { count: 1 };
    }),
    softDelete: vi.fn(async (id: string, userId: string) => {
      const row = recurringStore.get(id);
      if (!row || row.userId !== userId) return { count: 0 };
      row.deletedAt = new Date();
      row.isActive = false;
      return { count: 1 };
    }),
  },
}));

vi.mock('../src/repositories/transactionRepository.js', () => ({
  transactionRepository: {
    findByRecurringInMonth: vi.fn(
      async (recurringIncomeId: string, userId: string, month: string) => {
        const sep = month.indexOf('-');
        const year = parseInt(month.slice(0, sep), 10);
        const m = parseInt(month.slice(sep + 1), 10);
        const from = new Date(year, m - 1, 1);
        const to = new Date(year, m, 1);
        for (const tx of txStore.values()) {
          if (
            tx.userId === userId &&
            tx.recurringIncomeId === recurringIncomeId &&
            tx.occurredAt >= from &&
            tx.occurredAt < to
          ) {
            return tx;
          }
        }
        return null;
      },
    ),
    create: vi.fn(
      async (input: {
        userId: string;
        categoryId: string;
        amount: Prisma.Decimal;
        note?: string;
        occurredAt: Date;
        recurringIncomeId?: string;
      }) => {
        txCounter += 1;
        const tx: StoredTx = {
          id: `tx_${txCounter}`,
          userId: input.userId,
          categoryId: input.categoryId,
          amount: input.amount,
          note: input.note ?? null,
          occurredAt: input.occurredAt,
          recurringIncomeId: input.recurringIncomeId ?? null,
        };
        txStore.set(tx.id, tx);
        return { ...tx, category: { id: INCOME_CATEGORY_ID, key: 'income' } };
      },
    ),
    update: vi.fn(async (id: string, userId: string, data: Partial<StoredTx>) => {
      const tx = txStore.get(id);
      if (!tx || tx.userId !== userId) return { count: 0 };
      Object.assign(tx, data);
      return { count: 1 };
    }),
    summarize: vi.fn(async (userId: string, from: Date, to: Date) => {
      let lifetime = new Prisma.Decimal(0);
      let income = new Prisma.Decimal(0);
      let expenses = new Prisma.Decimal(0);
      for (const tx of txStore.values()) {
        if (tx.userId !== userId) continue;
        lifetime = lifetime.add(tx.amount);
        if (tx.occurredAt >= from && tx.occurredAt < to) {
          if (tx.amount.gt(0)) income = income.add(tx.amount);
          else expenses = expenses.add(tx.amount);
        }
      }
      return [
        { _sum: { amount: lifetime } },
        { _sum: { amount: income } },
        { _sum: { amount: expenses } },
      ];
    }),
  },
}));

const { incomeService } = await import('../src/services/incomeService.js');
const { dashboardService } = await import('../src/services/dashboardService.js');

const monthString = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

beforeEach(() => {
  recurringStore.clear();
  txStore.clear();
  txCounter = 0;
  recurringCounter = 0;
  vi.useRealTimers();
});

describe('incomeService.createSideIncome', () => {
  it('creates a positive income transaction', async () => {
    const result = await incomeService.createSideIncome('u1', {
      amount: 250,
      note: 'Freelance',
    });
    expect(result.amount).toBe(250);
    expect(result.note).toBe('Freelance');
    expect([...txStore.values()]).toHaveLength(1);
    expect([...txStore.values()][0]!.amount.toNumber()).toBe(250);
  });
});

describe('incomeService.ensureMaterialized', () => {
  it('creates recurring income on or after payday', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 25)); // May 25, 2026

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 20,
    });

    await incomeService.ensureMaterialized('u1', '2026-05');

    const txs = [...txStore.values()];
    expect(txs).toHaveLength(1);
    expect(txs[0]!.amount.toNumber()).toBe(5200);
    expect(txs[0]!.recurringIncomeId).toBeTruthy();
    expect(txs[0]!.occurredAt.getDate()).toBe(20);
  });

  it('skips materialization before payday in current month', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 10)); // May 10

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 20,
    });

    await incomeService.ensureMaterialized('u1', '2026-05');
    expect([...txStore.values()]).toHaveLength(0);
  });
});

describe('dashboardService.getSummary net balance', () => {
  it('returns net as income minus expenses for the month', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 25));

    await incomeService.createSideIncome('u1', { amount: 5000 });
    txStore.set('tx_exp', {
      id: 'tx_exp',
      userId: 'u1',
      categoryId: 'cat_food',
      amount: new Prisma.Decimal(-1200),
      note: null,
      occurredAt: new Date(2026, 4, 15),
      recurringIncomeId: null,
    });

    const month = monthString(new Date());
    const summary = await dashboardService.getSummary('u1', month);

    expect(summary.income).toBe(5000);
    expect(summary.expenses).toBe(1200);
    expect(summary.net).toBe(3800);
    expect(summary.balance).toBe(3800);
  });
});
