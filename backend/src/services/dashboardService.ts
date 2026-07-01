import { Prisma } from '../lib/prismaTypes.js';
import { budgetRepository } from '../repositories/budgetRepository.js';
import { categoryRepository } from '../repositories/categoryRepository.js';
import { monthlyBudgetRepository } from '../repositories/monthlyBudgetRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';
import { userRepository } from '../repositories/userRepository.js';
import { incomeService } from './incomeService.js';
import { recurringExpenseService } from './recurringExpenseService.js';

const parseMonth = (month: string): { from: Date; to: Date } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  // UTC bounds so month filtering aligns with UTC-midnight stored dates,
  // independent of server timezone.
  return { from: new Date(Date.UTC(year, m - 1, 1)), to: new Date(Date.UTC(year, m, 1)) };
};

// Current calendar month in UTC ('YYYY-MM'), matching the UTC month bounds.
const currentMonth = (): string => {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
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
  isSystem: boolean;
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
    await incomeService.ensureMaterialized(userId);
    await recurringExpenseService.ensureMaterialized(userId);
    const { from, to } = parseMonth(month);

    const [totals, monthly, template, openingBalance] = await Promise.all([
      transactionRepository.summarize(userId, from, to),
      monthlyBudgetRepository.findByUserMonth(userId, month),
      budgetRepository.findByUser(userId),
      userRepository.getOpeningBalance(userId),
    ]);

    // Flat offset: the user's starting bank balance plus their lifetime ledger.
    const balance = openingBalance + totals.balance;
    const income = totals.income;
    const expenses = totals.expenses;
    const net = income - expenses;

    // Past months report their own recorded budget; the current month falls
    // back to the recurring template (and carries it into the record on first
    // read, idempotently). Pre-feature months with no record report 0 until the
    // backfill fills them.
    let budgetAmount: number;
    if (monthly) {
      budgetAmount = toNum(monthly.amount);
    } else if (month === currentMonth() && template) {
      budgetAmount = toNum(template.amount);
      await monthlyBudgetRepository.upsertAmount(userId, month, template.amount);
    } else {
      budgetAmount = 0;
    }

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
        isSystem: t.category.isSystem,
      },
    }));
  },

  async getCategories(userId?: string) {
    return categoryRepository.findAll(userId);
  },

  async upsertBudget(userId: string, amount: number) {
    const budget = await budgetRepository.upsert(userId, amount);
    // Record the change against the live month so the current month reflects it
    // and it enters the historical record.
    await monthlyBudgetRepository.upsertAmount(
      userId,
      currentMonth(),
      new Prisma.Decimal(amount),
    );
    return { amount: budget.amount.toNumber() };
  },
};
