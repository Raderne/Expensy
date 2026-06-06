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
  deletedAt?: Date | null;
};

type StoredOccurrence = {
  userId: string;
  recurringIncomeId?: string;
  recurringExpenseId?: string;
  scheduledFor: Date;
  amount: Prisma.Decimal;
  label: string;
};

const recurringStore = new Map<string, StoredRecurring>();
const txStore = new Map<string, StoredTx>();
const occurrenceStore = new Map<string, StoredOccurrence>();
let txCounter = 0;
let recurringCounter = 0;

const INCOME_CATEGORY_ID = 'cat_income';

const occurrenceKey = (o: {
  recurringIncomeId?: string;
  recurringExpenseId?: string;
  scheduledFor: Date;
}) => `${o.recurringIncomeId ?? o.recurringExpenseId}|${o.scheduledFor.getTime()}`;

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

vi.mock('../src/repositories/recurringExpenseRepository.js', () => ({
  recurringExpenseRepository: {
    findActiveByUser: vi.fn(async () => []),
  },
}));

vi.mock('../src/repositories/recurringOccurrenceRepository.js', () => ({
  recurringOccurrenceRepository: {
    upsertScheduled: vi.fn(async (input: StoredOccurrence) => {
      const key = occurrenceKey(input);
      if (!occurrenceStore.has(key)) occurrenceStore.set(key, input);
    }),
    updateSnapshotForRule: vi.fn(async () => ({ count: 0 })),
  },
}));

vi.mock('../src/repositories/transactionRepository.js', () => ({
  transactionRepository: {
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
    summarize: vi.fn(async (userId: string, from: Date, to: Date) => {
      let lifetime = new Prisma.Decimal(0);
      let income = new Prisma.Decimal(0);
      let expenses = new Prisma.Decimal(0);
      for (const tx of txStore.values()) {
        if (tx.userId !== userId || tx.deletedAt) continue;
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

const occurrences = () => [...occurrenceStore.values()];

beforeEach(() => {
  recurringStore.clear();
  txStore.clear();
  occurrenceStore.clear();
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
  it('creates a PENDING occurrence on or after payday when source existed by then', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 15)); // May 15 — before payday

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 20,
    });
    // Nothing yet — payday hasn't arrived.
    expect(occurrences()).toHaveLength(0);

    vi.setSystemTime(new Date(2026, 4, 25)); // May 25 — after payday
    await incomeService.ensureMaterialized('u1');

    const occ = occurrences();
    expect(occ).toHaveLength(1);
    expect(occ[0]!.amount.toNumber()).toBe(5200);
    expect(occ[0]!.recurringIncomeId).toBeTruthy();
    expect(occ[0]!.scheduledFor.getDate()).toBe(20);
    // Confirmation, not materialization, creates the money.
    expect([...txStore.values()]).toHaveLength(0);
  });

  it('skips occurrence generation before payday in current month', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 10)); // May 10

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 20,
    });

    await incomeService.ensureMaterialized('u1');
    expect(occurrences()).toHaveLength(0);
  });

  it('does not backfill a payday that passed before the source was created', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 29)); // May 29

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 1,
    });

    await incomeService.ensureMaterialized('u1');
    expect(occurrences()).toHaveLength(0);
  });

  it('generates next month once payday arrives', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 29)); // May 29

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 1,
    });

    vi.setSystemTime(new Date(2026, 5, 1)); // June 1
    await incomeService.ensureMaterialized('u1');

    const occ = occurrences();
    expect(occ).toHaveLength(1);
    expect(occ[0]!.scheduledFor.getMonth()).toBe(5); // June
    expect(occ[0]!.scheduledFor.getDate()).toBe(1);
  });

  it('is idempotent across repeated runs', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 15)); // May 15 — before payday

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 20,
    });

    vi.setSystemTime(new Date(2026, 4, 25)); // May 25 — after payday
    await incomeService.ensureMaterialized('u1');
    await incomeService.ensureMaterialized('u1');

    expect(occurrences()).toHaveLength(1);
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

  it('excludes unconfirmed recurring income from the summary', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 4, 15)); // May 15 — before payday

    await incomeService.createRecurring('u1', {
      label: 'Salary',
      amount: 5200,
      dayOfMonth: 20,
    });

    vi.setSystemTime(new Date(2026, 4, 25)); // May 25 — payday passed
    const summary = await dashboardService.getSummary('u1', monthString(new Date()));

    // The payday occurrence exists but is unconfirmed, so it must not count.
    expect(occurrences()).toHaveLength(1);
    expect(summary.income).toBe(0);
    expect(summary.balance).toBe(0);
  });
});
