import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Prisma } from '../src/lib/prismaTypes.js';
import { AppError } from '../src/lib/errors.js';

type StoredGoal = {
  id: string;
  userId: string;
  name: string;
  icon: string;
  color: string;
  targetAmount: Prisma.Decimal;
  savedAmount: Prisma.Decimal;
  targetDate: Date | null;
  aiEstimate: unknown;
  aiEstimatedAt: Date | null;
};

const goals = new Map<string, StoredGoal>();

const makeGoal = (over: Partial<StoredGoal> = {}): StoredGoal => ({
  id: 'g1',
  userId: 'u1',
  name: 'New Car',
  icon: 'car',
  color: '#1B45D0',
  targetAmount: new Prisma.Decimal(10_000),
  savedAmount: new Prisma.Decimal(2_000),
  targetDate: null,
  aiEstimate: null,
  aiEstimatedAt: null,
  ...over,
});

vi.mock('../src/repositories/goalRepository.js', () => ({
  goalRepository: {
    findById: vi.fn(async (id: string, userId: string) => {
      const g = goals.get(id);
      if (!g || g.userId !== userId) return null;
      return g;
    }),
    saveEstimate: vi.fn(async (id: string, _userId: string, estimate: unknown) => {
      const g = goals.get(id);
      if (g) {
        g.aiEstimate = estimate;
        g.aiEstimatedAt = new Date();
      }
      return { count: 1 };
    }),
  },
}));

vi.mock('../src/repositories/transactionRepository.js', () => ({
  transactionRepository: {
    findMonths: vi.fn(async () => [{ month: '2026-06' }, { month: '2026-05' }, { month: '2026-04' }]),
    summarize: vi.fn(async () => ({ balance: 5000, income: 3000, expenses: 2000 })),
    groupExpensesByCategory: vi.fn(async () => [{ categoryId: 'cat_food', amount: 1200 }]),
  },
}));

vi.mock('../src/repositories/categoryRepository.js', () => ({
  categoryRepository: {
    findAll: vi.fn(async () => [{ id: 'cat_food', label: 'Food' }]),
  },
}));

const runAiTask = vi.fn();
vi.mock('../src/ai/aiService.js', () => ({
  runAiTask: (...args: unknown[]) => runAiTask(...args),
  defineAiTask: (key: string) => ({ key }),
}));

const { goalService } = await import('../src/services/goalService.js');
const { goalRepository } = await import('../src/repositories/goalRepository.js');

const validAiResponse = {
  reachable: true,
  estimatedMonths: 8,
  monthlyNetSavings: 1000,
  confidence: 'high' as const,
  summary: 'At your current pace you should reach this in about 8 months.',
  tips: ['Trim Food spending', 'Automate a monthly transfer'],
};

beforeEach(() => {
  goals.clear();
  runAiTask.mockReset();
  vi.mocked(goalRepository.saveEstimate).mockClear();
});

describe('goalService.estimate', () => {
  it('serves the cached estimate when it is still fresh', async () => {
    const cached = { ...validAiResponse, estimatedDate: null, generatedAt: '2026-06-27T00:00:00.000Z' };
    goals.set('g1', makeGoal({ aiEstimate: cached, aiEstimatedAt: new Date() }));

    const result = await goalService.estimate('u1', 'g1', {});

    expect(result).toEqual(cached);
    expect(runAiTask).not.toHaveBeenCalled();
  });

  it('recomputes and persists when the cache is stale', async () => {
    const stale = new Date(Date.now() - 48 * 3_600_000);
    goals.set('g1', makeGoal({ aiEstimate: { old: true }, aiEstimatedAt: stale }));
    runAiTask.mockResolvedValue(validAiResponse);

    const result = await goalService.estimate('u1', 'g1', {});

    expect(runAiTask).toHaveBeenCalledOnce();
    expect(goalRepository.saveEstimate).toHaveBeenCalledOnce();
    expect(result.estimatedMonths).toBe(8);
    expect(result.estimatedDate).not.toBeNull();
    expect(result.generatedAt).toEqual(expect.any(String));
  });

  it('recomputes when refresh is requested even if the cache is fresh', async () => {
    goals.set('g1', makeGoal({ aiEstimate: { old: true }, aiEstimatedAt: new Date() }));
    runAiTask.mockResolvedValue(validAiResponse);

    await goalService.estimate('u1', 'g1', { refresh: true });

    expect(runAiTask).toHaveBeenCalledOnce();
  });

  it('throws INSUFFICIENT_DATA when the user has no transaction history', async () => {
    const { transactionRepository } = await import('../src/repositories/transactionRepository.js');
    vi.mocked(transactionRepository.findMonths).mockResolvedValueOnce([]);
    goals.set('g1', makeGoal());

    await expect(goalService.estimate('u1', 'g1', {})).rejects.toMatchObject({
      status: 422,
      code: 'INSUFFICIENT_DATA',
    });
    expect(runAiTask).not.toHaveBeenCalled();
  });

  it('throws GOAL_NOT_FOUND for an unknown goal', async () => {
    await expect(goalService.estimate('u1', 'missing', {})).rejects.toMatchObject({
      status: 404,
      code: 'GOAL_NOT_FOUND',
    });
  });

  it('propagates AI_UNAVAILABLE when the model call fails', async () => {
    goals.set('g1', makeGoal());
    runAiTask.mockRejectedValue(
      new AppError({ status: 503, code: 'AI_UNAVAILABLE', message: 'down' }),
    );

    await expect(goalService.estimate('u1', 'g1', {})).rejects.toMatchObject({
      status: 503,
      code: 'AI_UNAVAILABLE',
    });
  });
});
