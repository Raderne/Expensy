import { z } from 'zod';

// =============================================================================
// POST /transactions — body (Phase 04)
//
// Client always sends a positive amount; the service negates it before storing
// (this screen creates expenses only — income arrives via future import flow).
// =============================================================================
export const createTransactionBodySchema = z.object({
  categoryId: z.string().cuid(),
  amount: z.number().positive().max(1_000_000),
  note: z.string().trim().max(140).optional(),
  occurredAt: z.string().datetime().optional(),
});

// =============================================================================
// GET /transactions — query (Phase 05)
//
// `cursor` is the opaque token returned by the previous page: "<isoDate>|<id>".
// Page size is fixed server-side at 30; the client only sees `nextCursor`.
// =============================================================================
const monthRegex = /^\d{4}-(0[1-9]|1[0-2])$/;

export const listTransactionsQuerySchema = z.object({
  month: z.string().regex(monthRegex, 'month must be YYYY-MM').optional(),
  categoryId: z.string().cuid().optional(),
  type: z.enum(['income', 'expense']).optional(),
  cursor: z
    .string()
    .regex(/^[^|]+\|[^|]+$/, 'cursor must be "<isoDate>|<id>"')
    .optional(),
});

export const transactionIdParamsSchema = z.object({
  id: z.string().cuid(),
});

export type CreateTransactionBody = z.infer<typeof createTransactionBodySchema>;
export type ListTransactionsQuery = z.infer<typeof listTransactionsQuerySchema>;
