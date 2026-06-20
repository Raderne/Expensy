import { z } from 'zod';

export const occurrenceIdParamsSchema = z.object({
  id: z.string().min(1),
});

export const confirmOccurrenceBodySchema = z.object({
  // Optional override for the recorded amount. Subscription/bill amounts can
  // drift month to month (e.g. a foreign-currency charge), so the user can
  // correct it at confirm time. Always positive; the sign is applied by type.
  amount: z.number().positive().optional(),
});

export type ConfirmOccurrenceBody = z.infer<typeof confirmOccurrenceBodySchema>;

export const postponeOccurrenceBodySchema = z.object({
  postponeTo: z
    .string()
    .refine((s) => !Number.isNaN(Date.parse(s)), {
      message: 'postponeTo must be an ISO date or datetime',
    }),
});

export type PostponeOccurrenceBody = z.infer<typeof postponeOccurrenceBodySchema>;
