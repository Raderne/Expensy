import { Router } from 'express';
import { dashboardController } from '../controllers/dashboardController.js';
import { transactionController } from '../controllers/transactionController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const transactionsRouter = Router();

transactionsRouter.get(
  '/transactions/recent',
  requireAuth,
  asyncHandler(dashboardController.recentTransactions),
);

transactionsRouter.get(
  '/transactions',
  requireAuth,
  asyncHandler(transactionController.list),
);

transactionsRouter.post(
  '/transactions',
  requireAuth,
  asyncHandler(transactionController.create),
);

transactionsRouter.delete(
  '/transactions/:id',
  requireAuth,
  asyncHandler(transactionController.delete),
);
