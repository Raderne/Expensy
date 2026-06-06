import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { authController } from '../controllers/authController.js';
import { passwordResetController } from '../controllers/passwordResetController.js';
import { asyncHandler } from '../lib/asyncHandler.js';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    type: 'about:blank',
    title: 'Too many login attempts',
    status: 429,
    code: 'RATE_LIMITED',
  },
});

const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    type: 'about:blank',
    title: 'Too many password reset requests',
    status: 429,
    code: 'RATE_LIMITED',
  },
});

export const authRouter = Router();
authRouter.post('/auth/signup', asyncHandler(authController.signup));
authRouter.post('/auth/login', loginLimiter, asyncHandler(authController.login));
authRouter.post('/auth/refresh', asyncHandler(authController.refresh));
authRouter.post(
  '/auth/forgot-password',
  forgotPasswordLimiter,
  asyncHandler(passwordResetController.forgotPassword),
);
authRouter.post('/auth/reset-password', asyncHandler(passwordResetController.resetPassword));
