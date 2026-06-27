import { Router } from 'express';
import { goalController } from '../controllers/goalController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { idempotencyMiddleware } from '../middleware/idempotency.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const goalsRouter = Router();

goalsRouter.get('/me/goals', requireAuth, asyncHandler(goalController.list));
goalsRouter.get(
  '/me/goals/:id/estimate',
  requireAuth,
  asyncHandler(goalController.estimate),
);
goalsRouter.post(
  '/me/goals',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(goalController.create),
);
goalsRouter.put(
  '/me/goals/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(goalController.update),
);
goalsRouter.post(
  '/me/goals/:id/add-funds',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(goalController.addFunds),
);
goalsRouter.delete(
  '/me/goals/:id',
  requireAuth,
  idempotencyMiddleware,
  asyncHandler(goalController.remove),
);
