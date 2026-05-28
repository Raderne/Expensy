import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  createTransactionBodySchema,
  listTransactionsQuerySchema,
} from '../schemas/transactions.js';
import { transactionService } from '../services/transactionService.js';

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

export const transactionController = {
  async create(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const body = createTransactionBodySchema.parse(req.body);
    const transaction = await transactionService.create(userId, body);
    res.status(201).json({ transaction });
  },

  async list(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const query = listTransactionsQuerySchema.parse(req.query);
    const result = await transactionService.list(userId, query);
    res.json(result);
  },

  async months(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const months = await transactionService.listMonths(userId);
    res.json({ months });
  },
};
