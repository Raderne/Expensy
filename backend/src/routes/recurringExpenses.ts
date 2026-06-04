import { Router } from 'express';
import { recurringExpenseController } from '../controllers/recurringExpenseController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { idempotencyMiddleware } from '../middleware/idempotency.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const recurringExpensesRouter = Router();

recurringExpensesRouter.get(
  '/me/expenses/recurring',
  requireAuth,
  asyncHandler(recurringExpenseController.list),
);
recurringExpensesRouter.post(
  '/me/expenses/recurring',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(recurringExpenseController.create),
);
recurringExpensesRouter.put(
  '/me/expenses/recurring/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(recurringExpenseController.update),
);
recurringExpensesRouter.delete(
  '/me/expenses/recurring/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(recurringExpenseController.remove),
);
recurringExpensesRouter.get(
  '/me/expenses/upcoming',
  requireAuth,
  asyncHandler(recurringExpenseController.upcoming),
);
