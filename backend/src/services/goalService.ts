import { Prisma } from '../lib/prismaTypes.js';
import { AppError } from '../lib/errors.js';
import { env } from '../config/env.js';
import { defineAiTask, runAiTask } from '../ai/aiService.js';
import { goalRepository } from '../repositories/goalRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import type {
  CreateGoalBody,
  UpdateGoalBody,
  AddFundsBody,
} from '../schemas/goals.js';

// Raw AI output for the goal-estimate task (validated against
// ai/tasks/goalEstimate/schema.json inside runAiTask). estimatedDate/generatedAt
// are derived server-side and are NOT part of the model output.
interface GoalEstimateAi {
  reachable: boolean;
  estimatedMonths: number | null;
  monthlyNetSavings: number;
  confidence: 'low' | 'medium' | 'high';
  summary: string;
  tips: string[];
}

const goalEstimateTask = defineAiTask<GoalEstimateAi>('goalEstimate', {
  // Compact task: a short prompt and a small fixed-shape response (summary +
  // up to 3 tips). Keep the budget tight to bound cost/latency.
  maxInputTokens: 2000,
  maxOutputTokens: 512,
  // Pure structured extraction — no reasoning needed. Disabling thinking keeps
  // the 512 output cap meaningful (2.5 models otherwise spend it on thinking).
  thinkingBudget: 0,
});

export interface GoalDto {
  id: string;
  name: string;
  icon: string;
  color: string;
  targetAmount: number;
  savedAmount: number;
  targetDate: string | null;
}

export interface GoalEstimateDto {
  reachable: boolean;
  estimatedMonths: number | null;
  estimatedDate: string | null;
  monthlyNetSavings: number;
  confidence: 'low' | 'medium' | 'high';
  summary: string;
  tips: string[];
  generatedAt: string;
}

// Number of trailing months of history we average to model the savings rate.
const ESTIMATE_WINDOW_MONTHS = 6;
const ESTIMATE_TOP_CATEGORIES = 5;

const round2 = (n: number): number => Math.round(n * 100) / 100;

const parseMonth = (month: string): { from: Date; to: Date } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  return { from: new Date(year, m - 1, 1), to: new Date(year, m, 1) };
};

const addMonths = (date: Date, months: number): Date => {
  const d = new Date(date);
  d.setMonth(d.getMonth() + months);
  return d;
};

const toDto = (row: {
  id: string;
  name: string;
  icon: string;
  color: string;
  targetAmount: Prisma.Decimal;
  savedAmount: Prisma.Decimal;
  targetDate: Date | null;
}): GoalDto => ({
  id: row.id,
  name: row.name,
  icon: row.icon,
  color: row.color,
  targetAmount: row.targetAmount.toNumber(),
  savedAmount: row.savedAmount.toNumber(),
  targetDate: row.targetDate ? row.targetDate.toISOString() : null,
});

const notFound = (): never => {
  throw new AppError({
    status: 404,
    code: 'GOAL_NOT_FOUND',
    message: 'Goal not found',
  });
};

export const goalService = {
  async list(userId: string): Promise<GoalDto[]> {
    const rows = await goalRepository.findByUser(userId);
    return rows.map(toDto);
  },

  async create(userId: string, input: CreateGoalBody): Promise<GoalDto> {
    const row = await goalRepository.create({
      userId,
      name: input.name,
      icon: input.icon,
      color: input.color,
      targetAmount: new Prisma.Decimal(input.targetAmount),
      savedAmount: new Prisma.Decimal(input.savedAmount ?? 0),
      targetDate: input.targetDate ? new Date(input.targetDate) : null,
    });
    return toDto(row);
  },

  async update(
    userId: string,
    id: string,
    input: UpdateGoalBody,
  ): Promise<GoalDto> {
    const existing = await goalRepository.findById(id, userId);
    if (!existing) notFound();

    const data: Partial<{
      name: string;
      icon: string;
      color: string;
      targetAmount: Prisma.Decimal;
      savedAmount: Prisma.Decimal;
      targetDate: Date | null;
    }> = {};
    if (input.name !== undefined) data.name = input.name;
    if (input.icon !== undefined) data.icon = input.icon;
    if (input.color !== undefined) data.color = input.color;
    if (input.targetAmount !== undefined) {
      data.targetAmount = new Prisma.Decimal(input.targetAmount);
    }
    if (input.savedAmount !== undefined) {
      data.savedAmount = new Prisma.Decimal(input.savedAmount);
    }
    // `targetDate` present (even as null) means set/clear it; absent means leave.
    if ('targetDate' in input) {
      data.targetDate = input.targetDate ? new Date(input.targetDate) : null;
    }

    await goalRepository.update(id, userId, data);
    const updated = await goalRepository.findById(id, userId);
    return toDto(updated!);
  },

  async addFunds(
    userId: string,
    id: string,
    input: AddFundsBody,
  ): Promise<GoalDto> {
    const existing = await goalRepository.findById(id, userId);
    if (!existing) notFound();
    await goalRepository.addFunds(id, userId, new Prisma.Decimal(input.amount));
    const updated = await goalRepository.findById(id, userId);
    return toDto(updated!);
  },

  async delete(userId: string, id: string): Promise<void> {
    const existing = await goalRepository.findById(id, userId);
    if (!existing) notFound();
    await goalRepository.softDelete(id, userId);
  },

  // AI time-to-reach estimate. Serves the persisted estimate within the TTL,
  // otherwise builds a spending profile from the user's recent transactions and
  // asks Gemini for a fresh, schema-constrained forecast, then caches it.
  async estimate(
    userId: string,
    id: string,
    opts: { refresh?: boolean } = {},
  ): Promise<GoalEstimateDto> {
    const goal = await goalRepository.findById(id, userId);
    if (!goal) notFound();

    // Serve cache when fresh (skips the Gemini call entirely).
    if (!opts.refresh && goal!.aiEstimate && goal!.aiEstimatedAt) {
      const ageMs = Date.now() - goal!.aiEstimatedAt.getTime();
      if (ageMs < env.GOAL_ESTIMATE_TTL_HOURS * 3_600_000) {
        return goal!.aiEstimate as unknown as GoalEstimateDto;
      }
    }

    // Build the spending profile from the most recent months that have data.
    const months = (await transactionRepository.findMonths(userId)).slice(
      0,
      ESTIMATE_WINDOW_MONTHS,
    );
    if (months.length === 0) {
      throw new AppError({
        status: 422,
        code: 'INSUFFICIENT_DATA',
        message: 'Not enough transaction history to estimate this goal',
      });
    }

    let incomeSum = 0;
    let expenseSum = 0;
    for (const { month } of months) {
      const { from, to } = parseMonth(month);
      const totals = await transactionRepository.summarize(userId, from, to);
      incomeSum += totals.income;
      expenseSum += totals.expenses;
    }
    const n = months.length;
    const avgIncome = incomeSum / n;
    const avgExpenses = expenseSum / n;
    const avgNet = avgIncome - avgExpenses;

    // Top spending categories across the same window, for richer tips.
    const windowFrom = parseMonth(months[n - 1]!.month).from;
    const windowTo = parseMonth(months[0]!.month).to;
    const [grouped, categories] = await Promise.all([
      transactionRepository.groupExpensesByCategory(userId, windowFrom, windowTo),
      categoryRepository.findAll(userId),
    ]);
    const labelById = new Map(categories.map((c) => [c.id, c.label]));
    const topCategories =
      grouped
        .slice()
        .sort((a, b) => b.amount - a.amount)
        .slice(0, ESTIMATE_TOP_CATEGORIES)
        .map((g) => `${labelById.get(g.categoryId) ?? 'Other'} (${Math.round(g.amount)})`)
        .join(', ') || 'none';

    const targetAmount = goal!.targetAmount.toNumber();
    const savedAmount = goal!.savedAmount.toNumber();
    const remaining = Math.max(0, targetAmount - savedAmount);

    const ai = await runAiTask(goalEstimateTask, {
      goalName: goal!.name,
      targetAmount: round2(targetAmount),
      savedAmount: round2(savedAmount),
      remaining: round2(remaining),
      currency: '',
      targetDate: goal!.targetDate
        ? goal!.targetDate.toISOString().slice(0, 10)
        : 'none set',
      monthsOfHistory: n,
      avgIncome: round2(avgIncome),
      avgExpenses: round2(avgExpenses),
      avgNetSavings: round2(avgNet),
      topCategories,
    });

    const estimatedDate =
      ai.reachable && ai.estimatedMonths != null
        ? addMonths(new Date(), ai.estimatedMonths).toISOString()
        : null;

    const dto: GoalEstimateDto = {
      ...ai,
      estimatedDate,
      generatedAt: new Date().toISOString(),
    };

    await goalRepository.saveEstimate(
      id,
      userId,
      dto as unknown as Prisma.InputJsonValue,
    );

    return dto;
  },
};
