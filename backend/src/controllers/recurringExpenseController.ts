import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  createRecurringExpenseBodySchema,
  recurringExpenseIdParamsSchema,
  updateRecurringExpenseBodySchema,
  upcomingBillsQuerySchema,
} from '../schemas/recurringExpenses.js';
import { recurringExpenseService } from '../services/recurringExpenseService.js';

const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError({ status: 401, code: 'MISSING_TOKEN', message: 'Authenticated user required' });
  }
  return req.userId;
};

export const recurringExpenseController = {
  async list(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const recurring = await recurringExpenseService.list(userId);
    res.setHeader('X-Total-Count', recurring.length);
    res.json({ recurring });
  },

  async create(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const body = createRecurringExpenseBodySchema.parse(req.body);
    const recurring = await recurringExpenseService.create(userId, body);
    res.status(201).json({ recurring });
  },

  async update(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = recurringExpenseIdParamsSchema.parse(req.params);
    const body = updateRecurringExpenseBodySchema.parse(req.body);
    const recurring = await recurringExpenseService.update(userId, id, body);
    res.json({ recurring });
  },

  async remove(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = recurringExpenseIdParamsSchema.parse(req.params);
    await recurringExpenseService.delete(userId, id);
    res.status(204).send();
  },

  async upcoming(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { limit } = upcomingBillsQuerySchema.parse(req.query);
    const upcoming = await recurringExpenseService.listUpcoming(userId, limit);
    res.setHeader('X-Total-Count', upcoming.length);
    res.json({ upcoming });
  },
};
