import { z } from 'zod';

// The estimate's output shape lives in ai/tasks/goalEstimate/schema.json and is
// validated dynamically by the AI service. This file only covers the HTTP query.
export const estimateQuerySchema = z.object({
  refresh: z
    .enum(['true', 'false'])
    .optional()
    .transform((v) => v === 'true'),
});

export type EstimateQuery = z.infer<typeof estimateQuerySchema>;
