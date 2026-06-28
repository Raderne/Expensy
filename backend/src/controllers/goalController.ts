import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  addFundsBodySchema,
  createGoalBodySchema,
  goalIdParamsSchema,
  updateGoalBodySchema,
} from '../schemas/goals.js';
import { estimateQuerySchema } from '../schemas/goalEstimate.js';
import { goalService } from '../services/goalService.js';

const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError({ status: 401, code: 'MISSING_TOKEN', message: 'Authenticated user required' });
  }
  return req.userId;
};

export const goalController = {
  async list(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const goals = await goalService.list(userId);
    res.setHeader('X-Total-Count', goals.length);
    res.json({ goals });
  },

  async create(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const body = createGoalBodySchema.parse(req.body);
    const goal = await goalService.create(userId, body);
    res.status(201).json({ goal });
  },

  async update(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = goalIdParamsSchema.parse(req.params);
    const body = updateGoalBodySchema.parse(req.body);
    const goal = await goalService.update(userId, id, body);
    res.json({ goal });
  },

  async addFunds(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = goalIdParamsSchema.parse(req.params);
    const body = addFundsBodySchema.parse(req.body);
    const goal = await goalService.addFunds(userId, id, body);
    res.json({ goal });
  },

  async remove(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = goalIdParamsSchema.parse(req.params);
    await goalService.delete(userId, id);
    res.status(204).send();
  },

  async estimate(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = goalIdParamsSchema.parse(req.params);
    const { refresh } = estimateQuerySchema.parse(req.query);
    const estimate = await goalService.estimate(userId, id, { refresh });
    res.json({ estimate });
  },
};
