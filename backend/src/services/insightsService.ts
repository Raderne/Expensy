import { AppError } from '../lib/errors.js';
import { env } from '../config/env.js';
import { logger } from '../lib/logger.js';
import { monthRange } from '../lib/month.js';
import { defineAiTask, runAiTask } from '../ai/aiService.js';
import { transactionRepository } from '../repositories/transactionRepository.js';
import { budgetRepository } from '../repositories/budgetRepository.js';
import { monthlyBudgetRepository } from '../repositories/monthlyBudgetRepository.js';
import { goalRepository } from '../repositories/goalRepository.js';
import { analyticsService } from './analyticsService.js';
import { recurringExpenseService } from './recurringExpenseService.js';
import { incomeService } from './incomeService.js';
import {
  assembleReport,
  buildFinancialSnapshot,
  contiguousMonthsEnding,
  fallbackNarrative,
  INSIGHTS_HISTORY_MONTHS,
  resolveNarrative,
  snapshotFingerprint,
  toAnalysisPacket,
  type AiNarrative,
  type InsightsReport,
  type SnapshotCategoryInput,
} from './financialSnapshot.js';

export type { InsightsReport };

const spendingInsightsTask = defineAiTask<AiNarrative>('spendingInsights', {
  maxInputTokens: 4500,
  maxOutputTokens: 1536,
  thinkingBudget: 0,
});

const DAYS_PER_MONTH = 365.25 / 12;
const UPCOMING_DAYS = 30;
const UPCOMING_FETCH = 12;

const toMonthly = (amount: number, frequency: string, intervalDays: number | null): number => {
  switch (frequency) {
    case 'WEEKLY':
      return amount * (52 / 12);
    case 'BIWEEKLY':
      return amount * (26 / 12);
    case 'CUSTOM':
      return intervalDays && intervalDays > 0 ? amount * (DAYS_PER_MONTH / intervalDays) : amount;
    case 'MONTHLY':
    default:
      return amount;
  }
};

const cache = new Map<string, { report: InsightsReport; at: number }>();
const cacheKey = (userId: string, month: string, fingerprint: string): string =>
  `${userId}:${month}:v${fingerprint}`;

const withinDays = (iso: string, now: Date, days: number): boolean => {
  const at = Date.parse(iso);
  if (Number.isNaN(at)) return false;
  const delta = at - now.getTime();
  return delta >= 0 && delta <= days * 86_400_000;
};

export const insightsService = {
  async getInsights(
    userId: string,
    month: string,
    opts: { refresh?: boolean } = {},
  ): Promise<InsightsReport> {
    const window = contiguousMonthsEnding(month, INSIGHTS_HISTORY_MONTHS);
    const focalRange = monthRange(month);
    const focalTotals = await transactionRepository.summarize(
      userId,
      focalRange.from,
      focalRange.to,
    );
    if (focalTotals.income === 0 && focalTotals.expenses === 0) {
      throw new AppError({
        status: 422,
        code: 'INSUFFICIENT_DATA',
        message: 'No activity in this month to analyse',
      });
    }

    const priorMonths = window.slice(0, -1);
    const now = new Date();
    const [priorSummaries, budgets, template, breakdowns, recurringExpenses, recurringIncome, upcoming, goals] =
      await Promise.all([
        Promise.all(
          priorMonths.map(async (m) => {
            const range = monthRange(m);
            const totals = await transactionRepository.summarize(userId, range.from, range.to);
            return { month: m, income: totals.income, expenses: totals.expenses };
          }),
        ),
        monthlyBudgetRepository.findByUserMonths(userId, window),
        budgetRepository.findByUser(userId),
        Promise.all(window.map((m) => analyticsService.getBreakdown(userId, m))),
        recurringExpenseService.list(userId),
        incomeService.listRecurring(userId),
        recurringExpenseService.listUpcoming(userId, UPCOMING_FETCH),
        goalRepository.findByUser(userId),
      ]);

    const budgetByMonth = new Map(budgets.map((row) => [row.month, row.amount.toNumber()]));
    const templateAmount = template ? template.amount.toNumber() : null;
    const budgetFor = (m: string): number | null => {
      const recorded = budgetByMonth.get(m);
      if (recorded != null && recorded > 0) return recorded;
      if (m === month && templateAmount != null && templateAmount > 0) return templateAmount;
      return null;
    };

    const categoriesByMonth: Record<string, SnapshotCategoryInput[]> = {};
    for (const breakdown of breakdowns) {
      categoriesByMonth[breakdown.month] = breakdown.breakdown.map((item) => ({
        categoryId: item.categoryId,
        label: item.label,
        amount: item.amount,
      }));
    }

    const snapshot = buildFinancialSnapshot({
      month,
      months: [
        ...priorSummaries.map((row) => ({
          month: row.month,
          income: row.income,
          expenses: row.expenses,
          budgetAmount: budgetFor(row.month),
        })),
        {
          month,
          income: focalTotals.income,
          expenses: focalTotals.expenses,
          budgetAmount: budgetFor(month),
        },
      ],
      categoriesByMonth,
      recurringExpenses: recurringExpenses
        .filter((row) => row.isActive)
        .map((row) => ({
          label: row.label,
          monthlyAmount: toMonthly(row.amount, row.frequency, row.intervalDays),
        })),
      recurringIncome: recurringIncome
        .filter((row) => row.isActive)
        .map((row) => ({ label: row.label, monthlyAmount: row.amount })),
      upcoming: upcoming
        .filter((row) => withinDays(row.occurredAt, now, UPCOMING_DAYS))
        .map((row) => ({ label: row.label, amount: row.amount, dueAt: row.occurredAt })),
      goals: goals.map((row) => ({
        name: row.name,
        savedAmount: row.savedAmount.toNumber(),
        targetAmount: row.targetAmount.toNumber(),
        targetDate: row.targetDate ? row.targetDate.toISOString() : null,
      })),
    });

    const fingerprint = snapshotFingerprint(snapshot);
    const key = cacheKey(userId, month, fingerprint);
    if (!opts.refresh) {
      const hit = cache.get(key);
      if (hit && Date.now() - hit.at < env.INSIGHTS_TTL_HOURS * 3_600_000) {
        return hit.report;
      }
    }

    const generatedAt = new Date().toISOString();
    let report: InsightsReport;
    try {
      const ai = await runAiTask(spendingInsightsTask, {
        analysisPacket: JSON.stringify(toAnalysisPacket(snapshot)),
      });
      const narrative = resolveNarrative(ai, snapshot);
      if (!narrative) {
        logger.warn({ month }, 'AI insights failed grounding; using calculated report');
        report = assembleReport(snapshot, fallbackNarrative(snapshot), 'unavailable', generatedAt);
      } else {
        report = assembleReport(snapshot, narrative, 'generated', generatedAt);
      }
    } catch (err) {
      if (!(err instanceof AppError) || err.code !== 'AI_UNAVAILABLE') throw err;
      logger.warn({ err, month }, 'AI insights unavailable; using calculated report');
      report = assembleReport(snapshot, fallbackNarrative(snapshot), 'unavailable', generatedAt);
    }

    if (report.aiStatus === 'generated') {
      cache.set(key, { report, at: Date.now() });
    }
    return report;
  },
};
