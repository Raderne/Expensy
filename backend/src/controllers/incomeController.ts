import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  createRecurringIncomeBodySchema,
  createSideIncomeBodySchema,
  recurringIncomeIdParamsSchema,
  updateRecurringIncomeBodySchema,
} from '../schemas/income.js';
import { incomeService } from '../services/incomeService.js';

const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError({ status: 401, code: 'MISSING_TOKEN', message: 'Authenticated user required' });
  }
  return req.userId;
};

export const incomeController = {
  async listRecurring(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const recurring = await incomeService.listRecurring(userId);
    res.json({ recurring });
  },

  async createRecurring(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const body = createRecurringIncomeBodySchema.parse(req.body);
    const recurring = await incomeService.createRecurring(userId, body);
    res.status(201).json({ recurring });
  },

  async updateRecurring(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = recurringIncomeIdParamsSchema.parse(req.params);
    const body = updateRecurringIncomeBodySchema.parse(req.body);
    const recurring = await incomeService.updateRecurring(userId, id, body);
    res.json({ recurring });
  },

  async deleteRecurring(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = recurringIncomeIdParamsSchema.parse(req.params);
    await incomeService.deleteRecurring(userId, id);
    res.status(204).send();
  },

  async createSideIncome(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const body = createSideIncomeBodySchema.parse(req.body);
    const income = await incomeService.createSideIncome(userId, body);
    res.status(201).json({ income });
  },
};
