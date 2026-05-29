import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import { analyticsQuerySchema } from '../schemas/analytics.js';
import { analyticsService } from '../services/analyticsService.js';

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

export const analyticsController = {
  async breakdown(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { month } = analyticsQuerySchema.parse(req.query);
    const data = await analyticsService.getBreakdown(userId, month);
    res.json(data);
  },
};
