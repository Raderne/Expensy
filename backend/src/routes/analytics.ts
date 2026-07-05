import { Router } from 'express';
import { analyticsController } from '../controllers/analyticsController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const analyticsRouter = Router();

analyticsRouter.get(
  '/analytics',
  requireAuth,
  asyncHandler(analyticsController.breakdown),
);

analyticsRouter.get(
  '/analytics/insights',
  requireAuth,
  asyncHandler(analyticsController.insights),
);
