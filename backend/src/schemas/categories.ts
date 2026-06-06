import { z } from 'zod';

export const CATEGORY_PALETTE = [
  '#F56B1E', '#FBBF24', '#16A34A', '#0891B2',
  '#1B45D0', '#6366F1', '#7C3AED', '#8B5CF6',
  '#DB2777', '#E11D48', '#DC2626', '#64748B',
  '#0F766E', '#B45309',
] as const;

export const createCategoryBodySchema = z.object({
  label: z.string().trim().min(1).max(40),
  abbr: z.string().trim().min(1).max(3).optional(),
  color: z.enum(CATEGORY_PALETTE),
});

export const updateCategoryBodySchema = z
  .object({
    label: z.string().trim().min(1).max(40).optional(),
    abbr: z.string().trim().min(1).max(3).optional(),
    color: z.enum(CATEGORY_PALETTE).optional(),
  })
  .refine((b) => Object.keys(b).length > 0, {
    message: 'At least one field is required',
  });

export const categoryIdParamsSchema = z.object({
  id: z.string().min(1),
});

export type CreateCategoryBody = z.infer<typeof createCategoryBodySchema>;
export type UpdateCategoryBody = z.infer<typeof updateCategoryBodySchema>;
