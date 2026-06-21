import { z } from 'zod';
import { CATEGORY_PALETTE } from './categories.js';

const nameSchema = z.string().trim().min(1).max(40);
const iconSchema = z.string().trim().min(1).max(32);
const colorSchema = z.enum(CATEGORY_PALETTE);
const targetAmountSchema = z.number().positive().max(1_000_000);
const savedAmountSchema = z.number().min(0).max(1_000_000);
// Accept either a full ISO datetime or a plain YYYY-MM-DD date (date-only goal).
const targetDateSchema = z
  .string()
  .datetime()
  .or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/));

export const createGoalBodySchema = z.object({
  name: nameSchema,
  icon: iconSchema,
  color: colorSchema,
  targetAmount: targetAmountSchema,
  savedAmount: savedAmountSchema.optional().default(0),
  targetDate: targetDateSchema.nullable().optional(),
});

export const updateGoalBodySchema = z
  .object({
    name: nameSchema.optional(),
    icon: iconSchema.optional(),
    color: colorSchema.optional(),
    targetAmount: targetAmountSchema.optional(),
    savedAmount: savedAmountSchema.optional(),
    // null clears the target date.
    targetDate: targetDateSchema.nullable().optional(),
  })
  .refine((body) => Object.keys(body).length > 0, {
    message: 'At least one field is required',
  });

export const addFundsBodySchema = z.object({
  amount: z.number().positive().max(1_000_000),
});

export const goalIdParamsSchema = z.object({
  id: z.string().min(1),
});

export type CreateGoalBody = z.infer<typeof createGoalBodySchema>;
export type UpdateGoalBody = z.infer<typeof updateGoalBodySchema>;
export type AddFundsBody = z.infer<typeof addFundsBodySchema>;
