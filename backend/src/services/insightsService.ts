import { AppError } from '../lib/errors.js';
import { env } from '../config/env.js';
import { monthRange, monthLabel } from '../lib/month.js';
import { defineAiTask, runAiTask } from '../ai/aiService.js';
import { transactionRepository } from '../repositories/transactionRepository.js';
import { budgetRepository } from '../repositories/budgetRepository.js';
import { monthlyBudgetRepository } from '../repositories/monthlyBudgetRepository.js';
import { analyticsService } from './analyticsService.js';
import { recurringExpenseService } from './recurringExpenseService.js';
import { incomeService } from './incomeService.js';

// Raw AI output for the spending-insights task (validated against
// ai/tasks/spendingInsights/schema.json inside runAiTask). month/generatedAt are
// added server-side and are NOT part of the model output.
interface SpendingInsightsAi {
  headline: string;
  summary: string;
  insights: {
    sentiment: 'positive' | 'warning' | 'neutral';
    title: string;
    detail: string;
  }[];
  suggestions: string[];
  savingsRatePct: number | null;
}

export interface InsightsDto extends SpendingInsightsAi {
  month: string;
  generatedAt: string;
}

const spendingInsightsTask = defineAiTask<SpendingInsightsAi>('spendingInsights', {
  // Richer prompt than the goal estimate (trend + recurring summaries) and a
  // larger response (up to 5 insight objects), so give it more room.
  maxInputTokens: 3000,
  maxOutputTokens: 1024,
  // Pure structured analysis — no reasoning tokens needed. Keeps the output cap
  // meaningful on 2.5+ thinking models.
  thinkingBudget: 0,
});

// Trailing months of history summarised for trend context.
const TREND_WINDOW_MONTHS = 6;
const TOP_CATEGORIES = 5;
const TOP_RECURRING = 6;

// Approximate days per month, for normalising non-monthly recurring cadences.
const DAYS_PER_MONTH = 365.25 / 12;

const round2 = (n: number): number => Math.round(n * 100) / 100;

// Convert a recurring expense's per-occurrence amount to an equivalent monthly
// figure so committed outflow is comparable across cadences.
const toMonthly = (
  amount: number,
  frequency: string,
  intervalDays: number | null,
): number => {
  switch (frequency) {
    case 'WEEKLY':
      return amount * (52 / 12);
    case 'BIWEEKLY':
      return amount * (26 / 12);
    case 'CUSTOM':
      return intervalDays && intervalDays > 0
        ? amount * (DAYS_PER_MONTH / intervalDays)
        : amount;
    case 'MONTHLY':
    default:
      return amount;
  }
};

// Simple per-user+month TTL cache. Insights are moderately expensive (a Gemini
// call), so within the TTL we serve the last result. Module-level like the
// idempotency store — lost on restart, which only forces one recompute.
const cache = new Map<string, { dto: InsightsDto; at: number }>();
const cacheKey = (userId: string, month: string): string => `${userId}:${month}`;

export const insightsService = {
  async getInsights(
    userId: string,
    month: string,
    opts: { refresh?: boolean } = {},
  ): Promise<InsightsDto> {
    const key = cacheKey(userId, month);
    if (!opts.refresh) {
      const hit = cache.get(key);
      if (hit && Date.now() - hit.at < env.INSIGHTS_TTL_HOURS * 3_600_000) {
        return hit.dto;
      }
    }

    // Selected-month totals. No activity → nothing worth analysing.
    const { from, to } = monthRange(month);
    const totals = await transactionRepository.summarize(userId, from, to);
    const income = totals.income;
    const expenses = totals.expenses;
    if (income === 0 && expenses === 0) {
      throw new AppError({
        status: 422,
        code: 'INSUFFICIENT_DATA',
        message: 'No activity in this month to analyse',
      });
    }
    const net = income - expenses;
    const savingsRatePct = income > 0 ? Math.round((net / income) * 100) : null;

    // Budget cap for the month: recorded MonthlyBudget wins, else the template
    // Budget (same fallback as dashboardService).
    const [monthlyBudget, template, breakdown, recurringExpenses, recurringIncome] =
      await Promise.all([
        monthlyBudgetRepository.findByUserMonth(userId, month),
        budgetRepository.findByUser(userId),
        analyticsService.getBreakdown(userId, month),
        recurringExpenseService.list(userId),
        incomeService.listRecurring(userId),
      ]);

    const budgetAmount = monthlyBudget
      ? monthlyBudget.amount.toNumber()
      : template
        ? template.amount.toNumber()
        : null;
    const budgetPct =
      budgetAmount && budgetAmount > 0
        ? Math.round((expenses / budgetAmount) * 100)
        : null;

    const topCategories =
      breakdown.breakdown
        .slice(0, TOP_CATEGORIES)
        .map((b) => `${b.label} ${Math.round(b.amount)} (${Math.round(b.pct * 100)}%)`)
        .join(', ') || 'none';

    // Per-month trend across the most recent months with data (newest first).
    const trendMonths = (await transactionRepository.findMonths(userId)).slice(
      0,
      TREND_WINDOW_MONTHS,
    );
    const trendLines: string[] = [];
    for (const { month: m } of trendMonths) {
      const range = monthRange(m);
      const t = await transactionRepository.summarize(userId, range.from, range.to);
      trendLines.push(
        `${m}: income ${Math.round(t.income)}, spent ${Math.round(t.expenses)}, net ${Math.round(
          t.income - t.expenses,
        )}`,
      );
    }
    const monthlyTrend = trendLines.join('; ') || 'none';

    // Active recurring commitments, normalised to a monthly figure.
    const activeExpenses = recurringExpenses.filter((r) => r.isActive);
    const recurringExpenseTotal = activeExpenses.reduce(
      (sum, r) => sum + toMonthly(r.amount, r.frequency, r.intervalDays),
      0,
    );
    const recurringExpensesSummary =
      activeExpenses.length === 0
        ? 'none'
        : `total ~${Math.round(recurringExpenseTotal)}/mo across ${activeExpenses.length} — ` +
          activeExpenses
            .map((r) => ({
              label: r.label,
              monthly: toMonthly(r.amount, r.frequency, r.intervalDays),
            }))
            .sort((a, b) => b.monthly - a.monthly)
            .slice(0, TOP_RECURRING)
            .map((r) => `${r.label} ${Math.round(r.monthly)}/mo`)
            .join(', ');

    const activeIncome = recurringIncome.filter((r) => r.isActive);
    const recurringIncomeTotal = activeIncome.reduce((sum, r) => sum + r.amount, 0);
    const recurringIncomeSummary =
      activeIncome.length === 0
        ? 'none'
        : `total ~${Math.round(recurringIncomeTotal)}/mo across ${activeIncome.length} — ` +
          activeIncome
            .slice()
            .sort((a, b) => b.amount - a.amount)
            .slice(0, TOP_RECURRING)
            .map((r) => `${r.label} ${Math.round(r.amount)}/mo`)
            .join(', ');

    const ai = await runAiTask(spendingInsightsTask, {
      monthLabel: monthLabel(month),
      income: round2(income),
      expenses: round2(expenses),
      net: round2(net),
      savingsRatePct: savingsRatePct ?? 'n/a',
      budgetAmount: budgetAmount != null ? round2(budgetAmount) : 'none set',
      budgetSpent: round2(expenses),
      budgetPct: budgetPct != null ? budgetPct : 'n/a',
      topCategories,
      monthlyTrend,
      recurringExpensesSummary,
      recurringIncomeSummary,
      currency: '',
    });

    const dto: InsightsDto = {
      ...ai,
      month,
      generatedAt: new Date().toISOString(),
    };
    cache.set(key, { dto, at: Date.now() });
    return dto;
  },
};
