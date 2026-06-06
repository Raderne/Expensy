import { z } from 'zod';

export const occurrenceIdParamsSchema = z.object({
  id: z.string().min(1),
});

export const postponeOccurrenceBodySchema = z.object({
  postponeTo: z
    .string()
    .refine((s) => !Number.isNaN(Date.parse(s)), {
      message: 'postponeTo must be an ISO date or datetime',
    }),
});

export type PostponeOccurrenceBody = z.infer<typeof postponeOccurrenceBodySchema>;
