import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import {
  changePasswordSchema,
  updateOpeningBalanceSchema,
  updateProfileSchema,
} from '../schemas/user.js';
import { userService } from '../services/userService.js';

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

export const userController = {
  async updateProfile(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const input = updateProfileSchema.parse(req.body);
    const user = await userService.updateProfile(userId, input);
    res.json({ user });
  },

  async changePassword(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const input = changePasswordSchema.parse(req.body);
    await userService.changePassword(userId, input);
    res.status(204).send();
  },

  async updateOpeningBalance(req: Request, res: Response): Promise<void> {
    const userId = requireUserId(req);
    const { amount } = updateOpeningBalanceSchema.parse(req.body);
    const result = await userService.updateOpeningBalance(userId, amount);
    res.json(result);
  },
};
