import 'dotenv/config';
import { z } from 'zod';

const EnvSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  DATABASE_URL: z.string().url(),
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_TTL: z.string().default('15m'),
  JWT_REFRESH_TTL: z.string().default('30d'),
  CORS_ORIGINS: z
    .string()
    .default('')
    .transform((s) => s.split(',').map((o) => o.trim()).filter(Boolean)),

  // Password reset (OTP). Code lifetime in minutes.
  RESET_CODE_TTL_MIN: z.coerce.number().int().positive().default(15),

  // SMTP — optional. When SMTP_HOST is unset, the mailer logs the message
  // (including the OTP) via Pino instead of sending, so local dev needs no
  // mail provider.
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().int().positive().optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASSWORD: z.string().optional(),
  SMTP_FROM: z.string().optional(),

  // Google Gemini — powers the goal time-to-reach estimate. Optional: when
  // GEMINI_API_KEY is unset the estimate endpoint responds 503 AI_UNAVAILABLE
  // and the rest of the app is unaffected. The free fast model is the default.
  GEMINI_API_KEY: z.string().optional(),
  GEMINI_MODEL: z.string().default('gemini-2.0-flash'),
  // How long a persisted goal estimate is served before a fresh Gemini call.
  GOAL_ESTIMATE_TTL_HOURS: z.coerce.number().int().positive().default(24),
});

const parsed = EnvSchema.safeParse(process.env);
if (!parsed.success) {
  console.error('Invalid environment configuration:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
export type Env = typeof env;
