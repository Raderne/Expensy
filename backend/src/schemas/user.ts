import { z } from 'zod';

export const updateProfileSchema = z.object({
  name: z.string().trim().min(1).max(80),
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1).max(128),
  newPassword: z.string().min(8).max(128),
});

// Opening balance is a flat offset; negative (overdraft) and zero (cleared) are valid.
export const updateOpeningBalanceSchema = z.object({
  amount: z.number().finite().min(-1_000_000_000).max(1_000_000_000),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
export type UpdateOpeningBalanceInput = z.infer<typeof updateOpeningBalanceSchema>;
