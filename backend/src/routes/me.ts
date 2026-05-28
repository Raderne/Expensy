import { Router } from 'express';
import { authController } from '../controllers/authController.js';
import { dashboardController } from '../controllers/dashboardController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const meRouter = Router();
meRouter.get('/me', requireAuth, asyncHandler(authController.me));
meRouter.get('/me/summary', requireAuth, asyncHandler(dashboardController.summary));
meRouter.put('/me/budget', requireAuth, asyncHandler(dashboardController.upsertBudget));
