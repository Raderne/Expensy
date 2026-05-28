import { z } from 'zod';

const currentMonth = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
};

export const summaryQuerySchema = z.object({
  month: z
    .string()
    .regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'month must be YYYY-MM')
    .default(currentMonth),
});

export const recentQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(20).default(4),
});

export const budgetBodySchema = z.object({
  amount: z.number().positive(),
});

export type SummaryQuery = z.infer<typeof summaryQuerySchema>;
export type RecentQuery = z.infer<typeof recentQuerySchema>;
export type BudgetBody = z.infer<typeof budgetBodySchema>;
