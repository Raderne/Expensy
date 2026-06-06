import express, { type Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { env } from './config/env.js';
import { errorHandler } from './middleware/errorHandler.js';
import { requestLogger } from './middleware/requestLogger.js';
import { requestContextMiddleware } from './middleware/requestContext.js';
import { analyticsRouter } from './routes/analytics.js';
import { authRouter } from './routes/auth.js';
import { categoriesRouter } from './routes/categories.js';
import { healthRouter } from './routes/health.js';
import { meRouter } from './routes/me.js';
import { incomeRouter } from './routes/income.js';
import { recurringExpensesRouter } from './routes/recurringExpenses.js';
import { recurringOccurrencesRouter } from './routes/recurringOccurrences.js';
import { transactionsRouter } from './routes/transactions.js';

export const createApp = (): Express => {
  const app = express();

  // Trust the first proxy hop so express-rate-limit gets the real client IP.
  app.set('trust proxy', 1);

  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGINS.length === 0 ? true : env.CORS_ORIGINS,
      credentials: true,
      exposedHeaders: ['X-Request-Id', 'X-Total-Count'],
    }),
  );
  app.use(express.json({ limit: '256kb' }));
  // Context first so the request id is set before pino-http reads it.
  app.use(requestContextMiddleware);
  app.use(requestLogger);

  app.use(healthRouter);
  app.use(authRouter);
  app.use(meRouter);
  app.use(incomeRouter);
  app.use(recurringExpensesRouter);
  app.use(recurringOccurrencesRouter);
  app.use(categoriesRouter);
  app.use(transactionsRouter);
  app.use(analyticsRouter);

  app.use(errorHandler);

  return app;
};
