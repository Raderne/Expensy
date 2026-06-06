import { Router } from 'express';
import { categoryController } from '../controllers/categoryController.js';
import { asyncHandler } from '../lib/asyncHandler.js';
import { requireAuth } from '../middleware/requireAuth.js';

export const categoriesRouter = Router();
categoriesRouter.get('/categories', requireAuth, asyncHandler(categoryController.list));
categoriesRouter.post('/categories', requireAuth, asyncHandler(categoryController.create));
categoriesRouter.patch('/categories/:id', requireAuth, asyncHandler(categoryController.update));
categoriesRouter.delete('/categories/:id', requireAuth, asyncHandler(categoryController.remove));
