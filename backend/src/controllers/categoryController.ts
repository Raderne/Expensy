import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  categoryIdParamsSchema,
  createCategoryBodySchema,
  updateCategoryBodySchema,
} from '../schemas/categories.js';
import { categoryService } from '../services/categoryService.js';

const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError({ status: 401, code: 'MISSING_TOKEN', message: 'Authenticated user required' });
  }
  return req.userId;
};

export const categoryController = {
  async list(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const categories = await categoryService.getAll(userId);
    res.setHeader('X-Total-Count', categories.length);
    res.json({ categories });
  },

  async create(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const body = createCategoryBodySchema.parse(req.body);
    const category = await categoryService.create(userId, body);
    res.status(201).json({ category });
  },

  async update(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = categoryIdParamsSchema.parse(req.params);
    const body = updateCategoryBodySchema.parse(req.body);
    const category = await categoryService.update(userId, id, body);
    res.json({ category });
  },

  async remove(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = categoryIdParamsSchema.parse(req.params);
    await categoryService.delete(userId, id);
    res.status(204).send();
  },
};
