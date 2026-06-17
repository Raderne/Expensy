import { z } from 'zod';

export const createReimbursementBodySchema = z.object({
  amount: z.number().positive().max(1_000_000),
  occurredAt: z.string().datetime().optional(),
});

export const splitIdParamsSchema = z.object({
  id: z.string().cuid(),
});

export const reimbursementIdParamsSchema = z.object({
  id: z.string().cuid(),
});

export type CreateReimbursementBody = z.infer<typeof createReimbursementBodySchema>;
