import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import { budgetBodySchema, recentQuerySchema, summaryQuerySchema } from '../schemas/dashboard.js';
import { dashboardService } from '../services/dashboardService.js';

const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError({ status: 401, code: 'MISSING_TOKEN', message: 'Authenticated user required' });
  }
  return req.userId;
};

export const dashboardController = {
  async categories(_req: Request, res: Response): Promise<void> {
    const categories = await dashboardService.getCategories();
    res.json({ categories });
  },

  async summary(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { month } = summaryQuerySchema.parse(req.query);
    const summary = await dashboardService.getSummary(userId, month);
    res.json(summary);
  },

  async recentTransactions(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { limit } = recentQuerySchema.parse(req.query);
    const transactions = await dashboardService.getRecentTransactions(userId, limit);
    res.json({ transactions });
  },

  async upsertBudget(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { amount } = budgetBodySchema.parse(req.body);
    const budget = await dashboardService.upsertBudget(userId, amount);
    res.json({ budget });
  },
};
