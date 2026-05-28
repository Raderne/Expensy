import { Router } from 'express';
import { dashboardController } from '../controllers/dashboardController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const categoriesRouter = Router();
categoriesRouter.get('/categories', requireAuth, asyncHandler(dashboardController.categories));
