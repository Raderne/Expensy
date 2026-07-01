import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  allocateBodySchema,
  rolloverMonthParamsSchema,
} from '../schemas/budgetRollover.js';
import { budgetRolloverService } from '../services/budgetRolloverService.js';

const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError({
      status: 401,
      code: 'MISSING_TOKEN',
      message: 'Authenticated user required',
    });
  }
  return req.userId;
};

export const budgetRolloverController = {
  async list(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const rollovers = await budgetRolloverService.listAllocatable(userId);
    res.json({ rollovers });
  },

  async allocate(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { month } = rolloverMonthParamsSchema.parse(req.params);
    const body = allocateBodySchema.parse(req.body);
    const rollover = await budgetRolloverService.allocate(userId, month, body);
    res.json({ rollover });
  },
};
