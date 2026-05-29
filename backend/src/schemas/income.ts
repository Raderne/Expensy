import { z } from 'zod';

const amountSchema = z.number().positive().max(1_000_000);
const dayOfMonthSchema = z.number().int().min(1).max(28);
const labelSchema = z.string().trim().min(1).max(40);

export const createRecurringIncomeBodySchema = z.object({
  label: labelSchema,
  amount: amountSchema,
  dayOfMonth: dayOfMonthSchema,
});

export const updateRecurringIncomeBodySchema = z
  .object({
    label: labelSchema.optional(),
    amount: amountSchema.optional(),
    dayOfMonth: dayOfMonthSchema.optional(),
    isActive: z.boolean().optional(),
  })
  .refine((body) => Object.keys(body).length > 0, {
    message: 'At least one field is required',
  });

export const recurringIncomeIdParamsSchema = z.object({
  id: z.string().min(1),
});

export const createSideIncomeBodySchema = z.object({
  amount: amountSchema,
  note: z.string().trim().max(200).optional(),
  occurredAt: z.string().datetime().optional(),
});

export type CreateRecurringIncomeBody = z.infer<typeof createRecurringIncomeBodySchema>;
export type UpdateRecurringIncomeBody = z.infer<typeof updateRecurringIncomeBodySchema>;
export type CreateSideIncomeBody = z.infer<typeof createSideIncomeBodySchema>;
