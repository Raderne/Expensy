import { categoryRepository } from '../repositories/categoryRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';

const parseMonth = (month: string): { from: Date; to: Date } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  // UTC bounds so month filtering aligns with UTC-midnight stored dates.
  return { from: new Date(Date.UTC(year, m - 1, 1)), to: new Date(Date.UTC(year, m, 1)) };
};

export interface BreakdownItem {
  categoryId: string;
  key: string;
  label: string;
  color: string;
  amount: number;
  pct: number; // 0..1, rounded to 4 decimals
}

export interface AnalyticsResponse {
  month: string;
  total: number;
  breakdown: BreakdownItem[];
}

export const analyticsService = {
  async getBreakdown(userId: string, month: string): Promise<AnalyticsResponse> {
    const { from, to } = parseMonth(month);

    // Fetch grouped sums and the category metadata in parallel. Pass userId so
    // the user's own custom categories are included — without it findAll returns
    // only system categories and every custom-category expense gets dropped.
    const [groups, categories] = await Promise.all([
      transactionRepository.groupExpensesByCategory(userId, from, to),
      categoryRepository.findAll(userId),
    ]);

    const byId = new Map(categories.map((c) => [c.id, c]));

    // Amounts arrive as positive magnitudes (already net of shared-owed); drop
    // unknown categories and any non-positive residuals defensively.
    const rows = groups
      .map((g) => {
        const cat = byId.get(g.categoryId);
        if (!cat) return null;
        const amount = Math.max(0, g.amount ?? 0);
        return { cat, amount };
      })
      .filter((r): r is { cat: (typeof categories)[number]; amount: number } => r !== null)
      .filter((r) => r.amount > 0);

    const total = rows.reduce((acc, r) => acc + r.amount, 0);

    const breakdown: BreakdownItem[] = rows
      .map(({ cat, amount }) => ({
        categoryId: cat.id,
        key: cat.key,
        label: cat.label,
        color: cat.color,
        amount,
        pct: total > 0 ? Math.round((amount / total) * 10_000) / 10_000 : 0,
      }))
      .sort((a, b) => b.amount - a.amount);

    return { month, total, breakdown };
  },
};
