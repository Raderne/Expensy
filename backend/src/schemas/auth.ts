import { z } from 'zod';

export const signupSchema = z.object({
  email: z.string().trim().toLowerCase().email().max(254),
  password: z.string().min(8).max(128),
  name: z.string().trim().min(1).max(80),
});

export const loginSchema = z.object({
  email: z.string().trim().toLowerCase().email().max(254),
  password: z.string().min(1).max(128),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});

export const forgotPasswordSchema = z.object({
  email: z.string().trim().toLowerCase().email().max(254),
});

export const resetPasswordSchema = z.object({
  email: z.string().trim().toLowerCase().email().max(254),
  code: z.string().trim().regex(/^\d{6}$/, 'Code must be 6 digits'),
  newPassword: z.string().min(8).max(128),
});

export type SignupInput = z.infer<typeof signupSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type RefreshInput = z.infer<typeof refreshSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
