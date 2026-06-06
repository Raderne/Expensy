import { Router } from 'express';
import { incomeController } from '../controllers/incomeController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { idempotencyMiddleware } from '../middleware/idempotency.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const incomeRouter = Router();

incomeRouter.get(
  '/me/income/recurring',
  requireAuth,
  asyncHandler(incomeController.listRecurring),
);
incomeRouter.post(
  '/me/income/recurring',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(incomeController.createRecurring),
);
incomeRouter.put(
  '/me/income/recurring/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(incomeController.updateRecurring),
);
incomeRouter.delete(
  '/me/income/recurring/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(incomeController.deleteRecurring),
);
incomeRouter.post(
  '/me/income',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(incomeController.createSideIncome),
);
