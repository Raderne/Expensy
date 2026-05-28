import type { Request, Response } from 'express';
import { AppError } from '../lib/errors.js';
import { loginSchema, refreshSchema, signupSchema } from '../schemas/auth.js';
import { authService } from '../services/authService.js';

export const authController = {
  async signup(req: Request, res: Response): Promise<void> {
    const input = signupSchema.parse(req.body);
    const result = await authService.signup(input);
    res.status(201).json(result);
  },

  async login(req: Request, res: Response): Promise<void> {
    const input = loginSchema.parse(req.body);
    const result = await authService.login(input);
    res.json(result);
  },

  async refresh(req: Request, res: Response): Promise<void> {
    const input = refreshSchema.parse(req.body);
    const result = await authService.refresh(input.refreshToken);
    res.json(result);
  },

  async me(req: Request, res: Response): Promise<void> {
    if (!req.userId) {
      throw new AppError({
        status: 401,
        code: 'MISSING_TOKEN',
        message: 'Authenticated user required',
      });
    }
    const user = await authService.me(req.userId);
    res.json({ user });
  },
};
