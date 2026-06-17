import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  contactIdParamsSchema,
  createContactBodySchema,
  updateContactBodySchema,
} from '../schemas/contacts.js';
import { contactService } from '../services/contactService.js';

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

export const contactController = {
  async list(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const contacts = await contactService.list(userId);
    res.setHeader('X-Total-Count', contacts.length);
    res.json({ contacts });
  },

  async create(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const body = createContactBodySchema.parse(req.body);
    const contact = await contactService.create(userId, body);
    res.status(201).json({ contact });
  },

  async update(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = contactIdParamsSchema.parse(req.params);
    const body = updateContactBodySchema.parse(req.body);
    const contact = await contactService.update(userId, id, body);
    res.json({ contact });
  },

  async remove(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { id } = contactIdParamsSchema.parse(req.params);
    await contactService.delete(userId, id);
    res.status(204).send();
  },
};
