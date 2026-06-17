import { z } from 'zod';

const nameSchema = z.string().trim().min(1).max(40);
// Optional avatar tint as a hex color (#RGB or #RRGGBB), chosen client-side.
const colorSchema = z
  .string()
  .regex(/^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/, 'color must be a hex value like #1B45D0');

export const createContactBodySchema = z.object({
  name: nameSchema,
  color: colorSchema.optional(),
});

export const updateContactBodySchema = z
  .object({
    name: nameSchema.optional(),
    color: colorSchema.nullable().optional(),
  })
  .refine((body) => Object.keys(body).length > 0, {
    message: 'At least one field is required',
  });

export const contactIdParamsSchema = z.object({
  id: z.string().cuid(),
});

export type CreateContactBody = z.infer<typeof createContactBodySchema>;
export type UpdateContactBody = z.infer<typeof updateContactBodySchema>;
