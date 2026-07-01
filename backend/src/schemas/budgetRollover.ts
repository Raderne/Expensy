import { z } from 'zod';

export const rolloverMonthParamsSchema = z.object({
  month: z.string().regex(/^\d{4}-\d{2}$/),
});

export const allocateBodySchema = z.object({
  goalId: z.string().min(1),
  amount: z.number().positive().max(1_000_000),
});

export type AllocateBody = z.infer<typeof allocateBodySchema>;
