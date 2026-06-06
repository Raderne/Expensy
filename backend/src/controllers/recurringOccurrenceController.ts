import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  occurrenceIdParamsSchema,
  postponeOccurrenceBodySchema,
} from '../schemas/recurringOccurrences.js';
import { recurringOccurrenceService } from '../services/recurringOccurrenceService.js';

const requireUserId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError({ status: 401, code: 'MISSING_TOKEN', message: 'Authenticated user required' });
  }
  return req.userId;
};

export const recurringOccurrenceController = {
  async listPending(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const pending = await recurringOccurrenceService.listDue(userId);
    res.setHeader('X-Total-Count', pending.length);
    res.json({ pending });
  },

  async confirm(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = occurrenceIdParamsSchema.parse(req.params);
    const transaction = await recurringOccurrenceService.confirm(userId, id);
    res.status(201).json({ transaction });
  },

  async postpone(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = occurrenceIdParamsSchema.parse(req.params);
    const { postponeTo } = postponeOccurrenceBodySchema.parse(req.body);
    await recurringOccurrenceService.postpone(userId, id, postponeTo);
    res.status(204).send();
  },
};
