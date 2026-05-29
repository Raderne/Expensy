import { Router } from 'express';
import { incomeController } from '../controllers/incomeController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
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
  asyncHandler(incomeController.createRecurring),
);
incomeRouter.put(
  '/me/income/recurring/:id',
  requireAuth,
  asyncHandler(incomeController.updateRecurring),
);
incomeRouter.delete(
  '/me/income/recurring/:id',
  requireAuth,
  asyncHandler(incomeController.deleteRecurring),
);
incomeRouter.post('/me/income', requireAuth, asyncHandler(incomeController.createSideIncome));
