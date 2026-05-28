import { Router } from 'express';
import { authController } from '../controllers/authController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const meRouter = Router();
meRouter.get('/me', requireAuth, asyncHandler(authController.me));
