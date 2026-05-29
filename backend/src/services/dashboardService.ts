import { budgetRepository } from '../repositories/budgetRepository.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';
import { incomeService } from './incomeService.js';

const parseMonth = (month: string): { from: Date; to: Date } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  return { from: new Date(year, m - 1, 1), to: new Date(year, m, 1) };
};

const toNum = (d: { toNumber(): number } | null | undefined): number =>
  d?.toNumber() ?? 0;

export interface DashboardSummary {
  balance: number;
  net: number;
  income: number;
  expenses: number;
  budget: { amount: number; spent: number; pct: number };
}

export interface CategoryDto {
  id: string;
  key: string;
  label: string;
  abbr: string;
  color: string;
  bgTint: string;
}

export interface RecentTx {
  id: string;
  amount: number;
  note: string | null;
  occurredAt: string;
  category: CategoryDto;
}

export const dashboardService = {
  async getSummary(userId: string, month: string): Promise<DashboardSummary> {
    await incomeService.ensureMaterialized(userId, month);
    const { from, to } = parseMonth(month);

    const [[lifetimeAgg, incomeAgg, expenseAgg], budget] = await Promise.all([
      transactionRepository.summarize(userId, from, to),
      budgetRepository.findByUser(userId),
    ]);

    const balance = toNum(lifetimeAgg._sum.amount);
    const income = toNum(incomeAgg._sum.amount);
    const expenses = Math.abs(toNum(expenseAgg._sum.amount));
    const net = income - expenses;
    const budgetAmount = toNum(budget?.amount);
    const pct = budgetAmount > 0 ? Math.min(100, Math.round((expenses / budgetAmount) * 100)) : 0;

    return { balance, net, income, expenses, budget: { amount: budgetAmount, spent: expenses, pct } };
  },

  async getRecentTransactions(userId: string, limit: number): Promise<RecentTx[]> {
    const rows = await transactionRepository.findRecent(userId, limit);
    return rows.map((t) => ({
      id: t.id,
      amount: t.amount.toNumber(),
      note: t.note,
      occurredAt: t.occurredAt.toISOString(),
      category: {
        id: t.category.id,
        key: t.category.key,
        label: t.category.label,
        abbr: t.category.abbr,
        color: t.category.color,
        bgTint: t.category.bgTint,
      },
    }));
  },

  async getCategories() {
    return categoryRepository.findAll();
  },

  async upsertBudget(userId: string, amount: number) {
    const budget = await budgetRepository.upsert(userId, amount);
    return { amount: budget.amount.toNumber() };
  },
};
