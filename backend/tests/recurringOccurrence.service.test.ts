import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';

const INCOME_CATEGORY = {
  id: 'cat_income',
  key: 'income',
  label: 'Income',
  abbr: 'IN',
  color: '#16A34A',
  bgTint: '#DCFCE7',
  isSystem: true,
};

const EXPENSE_CATEGORY = {
  id: 'cat_subs',
  key: 'subscriptions',
  label: 'Subscriptions',
  abbr: 'SB',
  color: '#7C3AED',
  bgTint: '#EDE9FE',
  isSystem: true,
};

type OccRow = {
  id: string;
  userId: string;
  status: 'PENDING' | 'CONFIRMED' | 'POSTPONED';
  recurringIncomeId: string | null;
  recurringExpenseId: string | null;
  scheduledFor: Date;
  dueAt: Date;
  amount: Prisma.Decimal;
  label: string;
  recurringExpense?: {
    categoryId: string;
    category: typeof EXPENSE_CATEGORY;
    shares?: { contactId: string; shareType: 'AMOUNT' | 'PERCENT'; shareValue: Prisma.Decimal }[];
  } | null;
  recurringIncome?: object | null;
};

const occStore = new Map<string, OccRow>();
const createdTx: Array<Record<string, unknown>> = [];
const confirmCalls: Array<{ id: string; transactionId: string }> = [];
const postponeCalls: Array<{ id: string; dueAt: Date }> = [];
const resetCalls: Array<{ id: string; scheduledFor: Date }> = [];
let txCounter = 0;

vi.mock('../src/services/incomeService.js', () => ({
  incomeService: { ensureMaterialized: vi.fn(async () => {}) },
}));
vi.mock('../src/services/recurringExpenseService.js', () => ({
  recurringExpenseService: { ensureMaterialized: vi.fn(async () => {}) },
}));

vi.mock('../src/repositories/categoryRepository.js', () => ({
  categoryRepository: {
    findAll: vi.fn(async () => [INCOME_CATEGORY, EXPENSE_CATEGORY]),
  },
}));

vi.mock('../src/repositories/recurringOccurrenceRepository.js', () => ({
  recurringOccurrenceRepository: {
    findById: vi.fn(async (id: string, userId: string) => {
      const row = occStore.get(id);
      if (!row || row.userId !== userId) return null;
      return row;
    }),
    findDue: vi.fn(async (userId: string, before: Date) =>
      [...occStore.values()].filter(
        (o) =>
          o.userId === userId &&
          (o.status === 'PENDING' || o.status === 'POSTPONED') &&
          o.dueAt <= before,
      ),
    ),
    findPostponed: vi.fn(async (userId: string) =>
      [...occStore.values()]
        .filter((o) => o.userId === userId && o.status === 'POSTPONED')
        .sort((a, b) => a.dueAt.getTime() - b.dueAt.getTime()),
    ),
    markConfirmed: vi.fn(
      async (id: string, _userId: string, transactionId: string, amount?: Prisma.Decimal) => {
        confirmCalls.push({ id, transactionId });
        const row = occStore.get(id);
        if (row) {
          row.status = 'CONFIRMED';
          if (amount != null) row.amount = amount;
        }
        return { count: 1 };
      },
    ),
    postpone: vi.fn(async (id: string, _userId: string, dueAt: Date) => {
      postponeCalls.push({ id, dueAt });
      const row = occStore.get(id);
      if (row) {
        row.status = 'POSTPONED';
        row.dueAt = dueAt;
      }
      return { count: 1 };
    }),
    resetToScheduled: vi.fn(async (id: string, _userId: string, scheduledFor: Date) => {
      resetCalls.push({ id, scheduledFor });
      const row = occStore.get(id);
      if (row) {
        row.status = 'PENDING';
        row.dueAt = scheduledFor;
      }
      return { count: 1 };
    }),
  },
}));

vi.mock('../src/repositories/transactionRepository.js', () => ({
  transactionRepository: {
    create: vi.fn(async (input: Record<string, unknown>) => {
      txCounter += 1;
      createdTx.push(input);
      const isIncome = Boolean(input.recurringIncomeId);
      return {
        id: `tx_${txCounter}`,
        amount: input.amount,
        note: input.note ?? null,
        occurredAt: input.occurredAt,
        category: isIncome ? INCOME_CATEGORY : EXPENSE_CATEGORY,
      };
    }),
  },
}));

const { recurringOccurrenceService } = await import(
  '../src/services/recurringOccurrenceService.js'
);

const addOccurrence = (row: Partial<OccRow> & Pick<OccRow, 'id'>): OccRow => {
  const full: OccRow = {
    userId: 'u1',
    status: 'PENDING',
    recurringIncomeId: null,
    recurringExpenseId: null,
    scheduledFor: new Date(2026, 5, 7),
    dueAt: new Date(2026, 5, 7),
    amount: new Prisma.Decimal(1000),
    label: 'Item',
    ...row,
  };
  occStore.set(full.id, full);
  return full;
};

beforeEach(() => {
  occStore.clear();
  createdTx.length = 0;
  confirmCalls.length = 0;
  postponeCalls.length = 0;
  resetCalls.length = 0;
  txCounter = 0;
  vi.useRealTimers();
});

describe('recurringOccurrenceService.confirm', () => {
  it('creates a positive income transaction and marks the occurrence confirmed', async () => {
    addOccurrence({
      id: 'occ_inc',
      recurringIncomeId: 'rec_1',
      amount: new Prisma.Decimal(5200),
      label: 'Salary',
      dueAt: new Date(2026, 5, 7),
    });

    const tx = await recurringOccurrenceService.confirm('u1', 'occ_inc');

    expect(tx.amount).toBe(5200);
    expect(tx.category.key).toBe('income');
    expect(createdTx).toHaveLength(1);
    expect((createdTx[0]!.amount as Prisma.Decimal).toNumber()).toBe(5200);
    expect(createdTx[0]!.categoryId).toBe(INCOME_CATEGORY.id);
    expect(createdTx[0]!.recurringIncomeId).toBe('rec_1');
    expect(confirmCalls).toEqual([{ id: 'occ_inc', transactionId: 'tx_1' }]);
  });

  it('creates a negated expense transaction with the rule category', async () => {
    addOccurrence({
      id: 'occ_exp',
      recurringExpenseId: 'rex_1',
      amount: new Prisma.Decimal(40),
      label: 'Netflix',
      recurringExpense: { categoryId: EXPENSE_CATEGORY.id, category: EXPENSE_CATEGORY },
    });

    await recurringOccurrenceService.confirm('u1', 'occ_exp');

    expect((createdTx[0]!.amount as Prisma.Decimal).toNumber()).toBe(-40);
    expect(createdTx[0]!.categoryId).toBe(EXPENSE_CATEGORY.id);
    expect(createdTx[0]!.recurringExpenseId).toBe('rex_1');
  });

  it('records an edited amount for an expense and persists it on the occurrence', async () => {
    const occ = addOccurrence({
      id: 'occ_edit',
      recurringExpenseId: 'rex_1',
      amount: new Prisma.Decimal(40),
      label: 'YouTube',
      recurringExpense: { categoryId: EXPENSE_CATEGORY.id, category: EXPENSE_CATEGORY },
    });

    const tx = await recurringOccurrenceService.confirm('u1', 'occ_edit', 65);

    expect(tx.amount).toBe(-65);
    expect((createdTx[0]!.amount as Prisma.Decimal).toNumber()).toBe(-65);
    // Confirmed amount is written back to the occurrence row.
    expect(occ.amount.toNumber()).toBe(65);
  });

  it('records an edited amount for income', async () => {
    addOccurrence({
      id: 'occ_inc_edit',
      recurringIncomeId: 'rec_1',
      amount: new Prisma.Decimal(5200),
      label: 'Salary',
    });

    const tx = await recurringOccurrenceService.confirm('u1', 'occ_inc_edit', 5000);

    expect(tx.amount).toBe(5000);
    expect((createdTx[0]!.amount as Prisma.Decimal).toNumber()).toBe(5000);
  });

  it('scales a percentage split proportionally to the edited amount', async () => {
    addOccurrence({
      id: 'occ_split',
      recurringExpenseId: 'rex_1',
      amount: new Prisma.Decimal(350),
      label: 'Shared bill',
      recurringExpense: {
        categoryId: EXPENSE_CATEGORY.id,
        category: EXPENSE_CATEGORY,
        shares: [
          { contactId: 'c1', shareType: 'PERCENT', shareValue: new Prisma.Decimal(50) },
        ],
      },
    });

    // 350 → 300; a 50% share drops from 175 to 150.
    await recurringOccurrenceService.confirm('u1', 'occ_split', 300);

    expect((createdTx[0]!.amount as Prisma.Decimal).toNumber()).toBe(-300);
    expect((createdTx[0]!.sharedOwedTotal as Prisma.Decimal).toNumber()).toBe(150);
    const splits = createdTx[0]!.splits as { contactId: string; owedAmount: Prisma.Decimal }[];
    expect(splits).toHaveLength(1);
    expect(splits[0]!.owedAmount.toNumber()).toBe(150);
  });

  it('rejects an edited amount too low to cover fixed-amount shares', async () => {
    addOccurrence({
      id: 'occ_low',
      recurringExpenseId: 'rex_1',
      amount: new Prisma.Decimal(100),
      label: 'Shared bill',
      recurringExpense: {
        categoryId: EXPENSE_CATEGORY.id,
        category: EXPENSE_CATEGORY,
        shares: [
          { contactId: 'c1', shareType: 'AMOUNT', shareValue: new Prisma.Decimal(60) },
        ],
      },
    });

    await expect(
      recurringOccurrenceService.confirm('u1', 'occ_low', 50),
    ).rejects.toMatchObject({ status: 400, code: 'INVALID_CONFIRM_AMOUNT' });
    expect(createdTx).toHaveLength(0);
  });

  it('rejects confirming an already-confirmed occurrence', async () => {
    addOccurrence({ id: 'occ_done', recurringIncomeId: 'rec_1', status: 'CONFIRMED' });
    await expect(recurringOccurrenceService.confirm('u1', 'occ_done')).rejects.toMatchObject({
      status: 409,
    });
  });

  it('404s for an unknown occurrence', async () => {
    await expect(recurringOccurrenceService.confirm('u1', 'nope')).rejects.toMatchObject({
      status: 404,
    });
  });
});

describe('recurringOccurrenceService.postpone', () => {
  it('moves dueAt to the future without touching scheduledFor', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 5, 7)); // June 7

    const occ = addOccurrence({
      id: 'occ_p',
      recurringIncomeId: 'rec_1',
      scheduledFor: new Date(2026, 5, 7),
      dueAt: new Date(2026, 5, 7),
    });

    await recurringOccurrenceService.postpone('u1', 'occ_p', new Date(2026, 5, 8).toISOString());

    expect(postponeCalls).toHaveLength(1);
    expect(postponeCalls[0]!.dueAt.getDate()).toBe(8);
    expect(occ.dueAt.getDate()).toBe(8);
    // Schedule identity is unchanged — next month still recurs on the 7th.
    expect(occ.scheduledFor.getDate()).toBe(7);
    expect(createdTx).toHaveLength(0);
  });

  it('rejects a postpone date that is not in the future', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 5, 7));

    addOccurrence({ id: 'occ_today', recurringIncomeId: 'rec_1' });

    await expect(
      recurringOccurrenceService.postpone('u1', 'occ_today', new Date(2026, 5, 7).toISOString()),
    ).rejects.toMatchObject({ status: 400 });
  });

  it('rejects postponing a confirmed occurrence', async () => {
    addOccurrence({ id: 'occ_c', recurringIncomeId: 'rec_1', status: 'CONFIRMED' });
    await expect(
      recurringOccurrenceService.postpone('u1', 'occ_c', new Date(2099, 0, 1).toISOString()),
    ).rejects.toMatchObject({ status: 409 });
  });
});

describe('recurringOccurrenceService.resetPostpone', () => {
  it('restores a postponed occurrence to its scheduled day (PENDING)', async () => {
    const occ = addOccurrence({
      id: 'occ_r',
      recurringIncomeId: 'rec_1',
      status: 'POSTPONED',
      scheduledFor: new Date(2026, 5, 7),
      dueAt: new Date(2026, 5, 20),
    });

    await recurringOccurrenceService.resetPostpone('u1', 'occ_r');

    expect(resetCalls).toHaveLength(1);
    expect(resetCalls[0]!.scheduledFor.getDate()).toBe(7);
    expect(occ.status).toBe('PENDING');
    expect(occ.dueAt.getDate()).toBe(7);
  });

  it('rejects resetting a confirmed occurrence', async () => {
    addOccurrence({ id: 'occ_rc', recurringIncomeId: 'rec_1', status: 'CONFIRMED' });
    await expect(
      recurringOccurrenceService.resetPostpone('u1', 'occ_rc'),
    ).rejects.toMatchObject({ status: 409 });
  });

  it('404s for an unknown occurrence', async () => {
    await expect(
      recurringOccurrenceService.resetPostpone('u1', 'nope'),
    ).rejects.toMatchObject({ status: 404 });
  });
});

describe('recurringOccurrenceService.listPostponed', () => {
  it('returns only postponed occurrences as typed DTOs, soonest first', async () => {
    addOccurrence({
      id: 'occ_due',
      recurringIncomeId: 'rec_1',
      status: 'PENDING',
      dueAt: new Date(2026, 5, 7),
    });
    addOccurrence({
      id: 'occ_late',
      recurringExpenseId: 'rex_1',
      status: 'POSTPONED',
      amount: new Prisma.Decimal(40),
      label: 'Netflix',
      scheduledFor: new Date(2026, 5, 9),
      dueAt: new Date(2026, 5, 25),
      recurringExpense: { categoryId: EXPENSE_CATEGORY.id, category: EXPENSE_CATEGORY },
    });
    addOccurrence({
      id: 'occ_soon',
      recurringIncomeId: 'rec_1',
      status: 'POSTPONED',
      amount: new Prisma.Decimal(5200),
      label: 'Salary',
      scheduledFor: new Date(2026, 5, 7),
      dueAt: new Date(2026, 5, 12),
    });

    const postponed = await recurringOccurrenceService.listPostponed('u1');

    expect(postponed.map((p) => p.id)).toEqual(['occ_soon', 'occ_late']);
    expect(postponed[0]!.type).toBe('income');
    expect(postponed[0]!.amount).toBe(5200);
    expect(postponed[1]!.categoryColor).toBe(EXPENSE_CATEGORY.color);
  });
});

describe('recurringOccurrenceService.listDue', () => {
  it('returns due occurrences as typed DTOs', async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 5, 10));

    addOccurrence({
      id: 'occ_inc',
      recurringIncomeId: 'rec_1',
      amount: new Prisma.Decimal(5200),
      label: 'Salary',
      scheduledFor: new Date(2026, 5, 7),
      dueAt: new Date(2026, 5, 7),
    });
    addOccurrence({
      id: 'occ_exp',
      recurringExpenseId: 'rex_1',
      amount: new Prisma.Decimal(40),
      label: 'Netflix',
      scheduledFor: new Date(2026, 5, 9),
      dueAt: new Date(2026, 5, 9),
      recurringExpense: { categoryId: EXPENSE_CATEGORY.id, category: EXPENSE_CATEGORY },
    });

    const due = await recurringOccurrenceService.listDue('u1');

    expect(due).toHaveLength(2);
    const income = due.find((d) => d.type === 'income')!;
    expect(income.amount).toBe(5200);
    expect(income.categoryKey).toBe('income');
    const expense = due.find((d) => d.type === 'expense')!;
    expect(expense.amount).toBe(40);
    expect(expense.categoryColor).toBe(EXPENSE_CATEGORY.color);
  });
});
