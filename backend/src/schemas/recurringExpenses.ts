import { z } from 'zod';

const amountSchema = z.number().positive().max(1_000_000);
const labelSchema = z.string().trim().min(1).max(40);
const frequencySchema = z.enum(['WEEKLY', 'BIWEEKLY', 'MONTHLY', 'CUSTOM']);
const intervalDaysSchema = z.number().int().min(1).max(365);
const anchorDateSchema = z
  .string()
  .refine((s) => !Number.isNaN(Date.parse(s)), { message: 'anchorDate must be ISO date or datetime' });

export const createRecurringExpenseBodySchema = z
  .object({
    label: labelSchema,
    amount: amountSchema,
    categoryId: z.string().min(1).optional(),
    frequency: frequencySchema,
    intervalDays: intervalDaysSchema.optional(),
    anchorDate: anchorDateSchema,
  })
  .superRefine((body, ctx) => {
    if (body.frequency === 'CUSTOM' && body.intervalDays === undefined) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['intervalDays'],
        message: 'intervalDays is required for CUSTOM frequency',
      });
    }
    if (body.frequency !== 'CUSTOM' && body.intervalDays !== undefined) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['intervalDays'],
        message: 'intervalDays is only allowed for CUSTOM frequency',
      });
    }
  });

export const updateRecurringExpenseBodySchema = z
  .object({
    label: labelSchema.optional(),
    amount: amountSchema.optional(),
    categoryId: z.string().min(1).optional(),
    frequency: frequencySchema.optional(),
    intervalDays: intervalDaysSchema.nullable().optional(),
    anchorDate: anchorDateSchema.optional(),
    isActive: z.boolean().optional(),
  })
  .refine((body) => Object.keys(body).length > 0, {
    message: 'At least one field is required',
  });

export const recurringExpenseIdParamsSchema = z.object({
  id: z.string().min(1),
});

export const upcomingBillsQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(20).default(3),
});

export type CreateRecurringExpenseBody = z.infer<typeof createRecurringExpenseBodySchema>;
export type UpdateRecurringExpenseBody = z.infer<typeof updateRecurringExpenseBodySchema>;
