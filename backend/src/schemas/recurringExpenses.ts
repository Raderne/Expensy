import { z } from 'zod';

const amountSchema = z.number().positive().max(1_000_000);
const labelSchema = z.string().trim().min(1).max(40);
const frequencySchema = z.enum(['WEEKLY', 'BIWEEKLY', 'MONTHLY', 'CUSTOM']);
const intervalDaysSchema = z.number().int().min(1).max(365);
const anchorDateSchema = z
  .string()
  .refine((s) => !Number.isNaN(Date.parse(s)), { message: 'anchorDate must be ISO date or datetime' });

// Split template applied to each generated occurrence. PERCENT values are 0..100
// of the occurrence amount; AMOUNT values are fixed. The amount-relative ceiling
// (shares must total less than the bill) is enforced in the service, where the
// rule amount is known on both create and update.
const shareSchema = z
  .object({
    contactId: z.string().cuid(),
    shareType: z.enum(['AMOUNT', 'PERCENT']),
    shareValue: z.number().positive(),
  })
  .superRefine((share, ctx) => {
    if (share.shareType === 'PERCENT' && share.shareValue > 100) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['shareValue'],
        message: 'percentage share cannot exceed 100',
      });
    }
  });

const sharesSchema = z.array(shareSchema).max(20).superRefine((shares, ctx) => {
  const ids = shares.map((s) => s.contactId);
  if (new Set(ids).size !== ids.length) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: [],
      message: 'each contact can only appear once in shares',
    });
  }
});

export const createRecurringExpenseBodySchema = z
  .object({
    label: labelSchema,
    amount: amountSchema,
    categoryId: z.string().min(1).optional(),
    frequency: frequencySchema,
    intervalDays: intervalDaysSchema.optional(),
    anchorDate: anchorDateSchema,
    shares: sharesSchema.optional(),
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
    // Replaces the rule's full set of shares when provided ([] clears them).
    shares: sharesSchema.optional(),
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
