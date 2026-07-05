import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';

// Selected-month + trend totals. Overridable per test via mockResolvedValueOnce.
vi.mock('../src/repositories/transactionRepository.js', () => ({
  transactionRepository: {
    summarize: vi.fn(async () => ({ balance: 8000, income: 3000, expenses: 2000 })),
    findMonths: vi.fn(async () => [{ month: '2026-06' }, { month: '2026-05' }]),
  },
}));

vi.mock('../src/repositories/budgetRepository.js', () => ({
  budgetRepository: {
    findByUser: vi.fn(async () => ({ amount: new Prisma.Decimal(2_500) })),
  },
}));

vi.mock('../src/repositories/monthlyBudgetRepository.js', () => ({
  monthlyBudgetRepository: {
    findByUserMonth: vi.fn(async () => ({ amount: new Prisma.Decimal(2_400) })),
  },
}));

vi.mock('../src/services/analyticsService.js', () => ({
  analyticsService: {
    getBreakdown: vi.fn(async (_userId: string, month: string) => ({
      month,
      total: 2000,
      breakdown: [
        { categoryId: 'c1', key: 'food', label: 'Food', color: '#000', amount: 1200, pct: 0.6 },
        { categoryId: 'c2', key: 'fun', label: 'Fun', color: '#111', amount: 800, pct: 0.4 },
      ],
    })),
  },
}));

vi.mock('../src/services/recurringExpenseService.js', () => ({
  recurringExpenseService: {
    list: vi.fn(async () => [
      {
        label: 'Rent',
        amount: 1200,
        frequency: 'MONTHLY',
        intervalDays: null,
        isActive: true,
      },
      {
        label: 'Gym',
        amount: 40,
        frequency: 'WEEKLY',
        intervalDays: null,
        isActive: true,
      },
      {
        label: 'Old plan',
        amount: 99,
        frequency: 'MONTHLY',
        intervalDays: null,
        isActive: false,
      },
    ],
  ),
  },
}));

vi.mock('../src/services/incomeService.js', () => ({
  incomeService: {
    listRecurring: vi.fn(async () => [
      { label: 'Salary', amount: 3000, dayOfMonth: 25, isActive: true },
    ]),
  },
}));

const runAiTask = vi.fn();
vi.mock('../src/ai/aiService.js', () => ({
  runAiTask: (...args: unknown[]) => runAiTask(...args),
  defineAiTask: (key: string) => ({ key }),
}));

const { insightsService } = await import('../src/services/insightsService.js');
const { transactionRepository } = await import(
  '../src/repositories/transactionRepository.js'
);

const validAiResponse = {
  headline: 'You saved 33% this month.',
  summary: 'Income 3000, spend 2000 — a healthy month.',
  insights: [
    { sentiment: 'positive', title: 'Under budget', detail: 'Spent 2000 of a 2400 budget.' },
    { sentiment: 'neutral', title: 'Food leads', detail: 'Food was 60% of spending.' },
  ],
  suggestions: ['Automate a transfer to savings.'],
  savingsRatePct: 33,
};

beforeEach(() => {
  runAiTask.mockReset();
  runAiTask.mockResolvedValue(validAiResponse);
  vi.mocked(transactionRepository.summarize).mockClear();
});

describe('insightsService.getInsights', () => {
  it('feeds budget, trend, and recurring summaries to the model', async () => {
    const dto = await insightsService.getInsights('u_vars', '2026-06', {});

    expect(runAiTask).toHaveBeenCalledOnce();
    const vars = runAiTask.mock.calls[0]![1] as Record<string, unknown>;
    expect(vars.income).toBe(3000);
    expect(vars.expenses).toBe(2000);
    expect(vars.net).toBe(1000);
    // Recorded MonthlyBudget wins over the template.
    expect(vars.budgetAmount).toBe(2400);
    expect(vars.budgetPct).toBe(Math.round((2000 / 2400) * 100));
    expect(vars.topCategories).toContain('Food');
    // Trend has one line per month returned by findMonths.
    expect(vars.monthlyTrend).toContain('2026-06');
    expect(vars.monthlyTrend).toContain('2026-05');
    // Active recurring only (excludes the inactive 'Old plan'); Gym normalised weekly→monthly.
    expect(vars.recurringExpensesSummary).toContain('Rent');
    expect(vars.recurringExpensesSummary).toContain('Gym');
    expect(vars.recurringExpensesSummary).not.toContain('Old plan');
    expect(vars.recurringIncomeSummary).toContain('Salary');

    expect(dto.month).toBe('2026-06');
    expect(dto.headline).toBe(validAiResponse.headline);
    expect(dto.generatedAt).toEqual(expect.any(String));
  });

  it('serves the cached insight on a second call without hitting the model', async () => {
    await insightsService.getInsights('u_cache', '2026-06', {});
    await insightsService.getInsights('u_cache', '2026-06', {});
    expect(runAiTask).toHaveBeenCalledOnce();
  });

  it('recomputes when refresh is requested', async () => {
    await insightsService.getInsights('u_refresh', '2026-06', {});
    await insightsService.getInsights('u_refresh', '2026-06', { refresh: true });
    expect(runAiTask).toHaveBeenCalledTimes(2);
  });

  it('throws INSUFFICIENT_DATA when the month has no activity', async () => {
    vi.mocked(transactionRepository.summarize).mockResolvedValueOnce({
      balance: 0,
      income: 0,
      expenses: 0,
    });

    await expect(
      insightsService.getInsights('u_empty', '2026-06', {}),
    ).rejects.toMatchObject({ status: 422, code: 'INSUFFICIENT_DATA' });
    expect(runAiTask).not.toHaveBeenCalled();
  });
});
