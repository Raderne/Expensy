import type { Request, Response } from 'express';
import { forgotPasswordSchema, resetPasswordSchema } from '../schemas/auth.js';
import { passwordResetService } from '../services/passwordResetService.js';

export const passwordResetController = {
  async forgotPassword(req: Request, res: Response): Promise<void> {
    const input = forgotPasswordSchema.parse(req.body);
    await passwordResetService.requestReset(input);
    // Always generic — never reveal whether the email is registered.
    res.json({ ok: true });
  },

  async resetPassword(req: Request, res: Response): Promise<void> {
    const input = resetPasswordSchema.parse(req.body);
    await passwordResetService.resetPassword(input);
    res.json({ ok: true });
  },
};
