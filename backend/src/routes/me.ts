import { Router } from 'express';
import { authController } from '../controllers/authController.js';
import { dashboardController } from '../controllers/dashboardController.js';
import { transactionController } from '../controllers/transactionController.js';
import { userController } from '../controllers/userController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { idempotencyMiddleware } from '../middleware/idempotency.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const meRouter = Router();
meRouter.get('/me', requireAuth, asyncHandler(authController.me));
meRouter.put('/me', requireAuth, idempotencyMiddleware, asyncHandler(userController.updateProfile));
meRouter.patch(
  '/me/password',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(userController.changePassword),
);
meRouter.get('/me/summary', requireAuth, asyncHandler(dashboardController.summary));
meRouter.put(
  '/me/budget',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(dashboardController.upsertBudget),
);
meRouter.get(
  '/me/transaction-months',
  requireAuth,
  asyncHandler(transactionController.months),
);
