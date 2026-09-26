import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';
import { AppError } from '../src/lib/errors.js';

vi.mock('../src/repositories/transactionRepository.js', () => ({
  transactionRepository: {
    summarize: vi.fn(async () => ({ balance: 8000, income: 3000, expenses: 2000 })),
  },
}));

vi.mock('../src/repositories/budgetRepository.js', () => ({
  budgetRepository: {
    findByUser: vi.fn(async () => ({ amount: new Prisma.Decimal(2_500) })),
  },
}));

vi.mock('../src/repositories/monthlyBudgetRepository.js', () => ({
  monthlyBudgetRepository: {
    findByUserMonths: vi.fn(async () => [{ month: '2026-06', amount: new Prisma.Decimal(2_400) }]),
  },
}));

vi.mock('../src/repositories/goalRepository.js', () => ({
  goalRepository: {
    findByUser: vi.fn(async () => [
      {
        name: 'Trip',
        savedAmount: new Prisma.Decimal(200),
        targetAmount: new Prisma.Decimal(1_000),
        targetDate: new Date('2026-12-01T00:00:00.000Z'),
      },
    ]),
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
      { label: 'Rent', amount: 1200, frequency: 'MONTHLY', intervalDays: null, isActive: true },
      { label: 'Gym', amount: 40, frequency: 'WEEKLY', intervalDays: null, isActive: true },
      { label: 'Old plan', amount: 99, frequency: 'MONTHLY', intervalDays: null, isActive: false },
    ]),
    listUpcoming: vi.fn(async () => []),
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
const { transactionRepository } = await import('../src/repositories/transactionRepository.js');

const validAiResponse = {
  headline: 'You saved this month.',
  summary: 'Income covered spending with room left over.',
  insights: [
    { factId: 'savings_rate', sentiment: 'positive', title: 'Saving', detail: 'Net is positive.' },
    { factId: 'top_category', sentiment: 'neutral', title: 'Food leads', detail: 'Food is the largest category.' },
  ],
  actions: [
    { candidateId: 'review_category', title: 'Look at Food', detail: 'It is most of the month.' },
  ],
  notes: [],
};

beforeEach(() => {
  runAiTask.mockReset();
  runAiTask.mockResolvedValue(validAiResponse);
  vi.mocked(transactionRepository.summarize).mockReset();
  vi.mocked(transactionRepository.summarize).mockResolvedValue({
    balance: 8000,
    income: 3000,
    expenses: 2000,
  });
});

describe('insightsService.getInsights', () => {
  it('sends a privacy-minimized packet and keeps the server savings rate', async () => {
    const report = await insightsService.getInsights('u_vars', '2026-06', {});

    expect(runAiTask).toHaveBeenCalledOnce();
    const vars = runAiTask.mock.calls[0]![1] as { analysisPacket: string };
    const packet = JSON.parse(vars.analysisPacket) as {
      facts: { id: string; text: string }[];
      candidates: { id: string }[];
    };
    expect(packet.facts.find((f) => f.id === 'income')?.text).toContain('3000');
    expect(packet.facts.find((f) => f.id === 'budget')?.text).toContain('2400');
    expect(packet.facts.find((f) => f.id === 'top_category')?.text).toContain('Food');
    expect(packet.facts.find((f) => f.id === 'recurring_coverage')?.text).toContain('Rent');
    expect(packet.facts.find((f) => f.id === 'recurring_coverage')?.text).toContain('Gym');
    expect(packet.facts.find((f) => f.id === 'goals')?.text).toContain('Trip');
    expect(vars.analysisPacket).not.toContain('Old plan');
    expect(vars.analysisPacket).not.toContain('c1');
    expect(vars.analysisPacket).not.toContain('email');
    expect(packet.candidates.map((c) => c.id)).toContain('review_category');
    expect(report.scorecard.savingsRatePct).toBe(33);
    expect(report.aiStatus).toBe('generated');
    expect(report.currencyCode).toBe('USD');
    expect(report.actions[0]?.categoryId).toBe('c1');
    expect(report.generatedAt).toEqual(expect.any(String));

    const froms = vi.mocked(transactionRepository.summarize).mock.calls.map((call) => call[1] as Date);
    expect(froms.some((d) => d.toISOString().startsWith('2026-01'))).toBe(true);
    expect(froms.some((d) => d.toISOString().startsWith('2025-12'))).toBe(false);
  });

  it('serves the cached insight when the snapshot is unchanged', async () => {
    await insightsService.getInsights('u_cache', '2026-06', {});
    await insightsService.getInsights('u_cache', '2026-06', {});
    expect(runAiTask).toHaveBeenCalledOnce();
  });

  it('recomputes when the underlying figures change, without an explicit refresh', async () => {
    await insightsService.getInsights('u_hash', '2026-06', {});
    vi.mocked(transactionRepository.summarize).mockResolvedValue({
      balance: 1000,
      income: 5000,
      expenses: 1000,
    });
    await insightsService.getInsights('u_hash', '2026-06', {});
    expect(runAiTask).toHaveBeenCalledTimes(2);
  });

  it('recomputes when refresh is requested', async () => {
    await insightsService.getInsights('u_refresh', '2026-06', {});
    await insightsService.getInsights('u_refresh', '2026-06', { refresh: true });
    expect(runAiTask).toHaveBeenCalledTimes(2);
  });

  it('throws INSUFFICIENT_DATA when the focal month has no activity', async () => {
    vi.mocked(transactionRepository.summarize).mockResolvedValueOnce({
      balance: 0,
      income: 0,
      expenses: 0,
    });

    await expect(insightsService.getInsights('u_empty', '2026-06', {})).rejects.toMatchObject({
      status: 422,
      code: 'INSUFFICIENT_DATA',
    });
    expect(runAiTask).not.toHaveBeenCalled();
  });

  it('falls back to calculated copy when the model cites an unknown id', async () => {
    runAiTask.mockResolvedValueOnce({
      ...validAiResponse,
      headline: 'Invented takeaway.',
      insights: [
        { factId: 'made_up', sentiment: 'warning', title: 'Nope', detail: 'Not real.' },
        { factId: 'income', sentiment: 'neutral', title: 'Income', detail: 'Recorded.' },
      ],
    });

    const report = await insightsService.getInsights('u_ground', '2026-06', {});
    expect(report.aiStatus).toBe('unavailable');
    expect(report.headline).not.toBe('Invented takeaway.');
    expect(report.scorecard.income).toBe(3000);
    expect(report.insights.length).toBeGreaterThanOrEqual(2);
    expect(report.insights.every((item) => item.evidence.length > 0)).toBe(true);
  });

  it('falls back when Gemini is unavailable and does not cache that failure', async () => {
    runAiTask.mockRejectedValueOnce(
      new AppError({ status: 503, code: 'AI_UNAVAILABLE', message: 'down' }),
    );
    const first = await insightsService.getInsights('u_down', '2026-06', {});
    expect(first.aiStatus).toBe('unavailable');
    expect(first.scorecard.expenses).toBe(2000);

    runAiTask.mockResolvedValueOnce(validAiResponse);
    const second = await insightsService.getInsights('u_down', '2026-06', {});
    expect(second.aiStatus).toBe('generated');
    expect(runAiTask).toHaveBeenCalledTimes(2);
  });
});
