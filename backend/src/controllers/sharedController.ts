import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  createReimbursementBodySchema,
  reimbursementIdParamsSchema,
  splitIdParamsSchema,
} from '../schemas/shared.js';
import { sharedService } from '../services/sharedService.js';

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

export const sharedController = {
  async owed(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const overview = await sharedService.owed(userId);
    res.json(overview);
  },

  async createReimbursement(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = splitIdParamsSchema.parse(req.params);
    const body = createReimbursementBodySchema.parse(req.body);
    const result = await sharedService.createReimbursement(userId, id, body);
    res.status(201).json(result);
  },

  async deleteReimbursement(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = reimbursementIdParamsSchema.parse(req.params);
    await sharedService.deleteReimbursement(userId, id);
    res.status(204).send();
  },
};
