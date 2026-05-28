import express, { type Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import { env } from './config/env.js';
import { logger } from './lib/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { requestContextMiddleware } from './middleware/requestContext.js';
import { authRouter } from './routes/auth.js';
import { categoriesRouter } from './routes/categories.js';
import { healthRouter } from './routes/health.js';
import { meRouter } from './routes/me.js';
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
    }),
  );
  app.use(express.json({ limit: '256kb' }));
  app.use(pinoHttp({ logger }));
  app.use(requestContextMiddleware);

  app.use(healthRouter);
  app.use(authRouter);
  app.use(meRouter);
  app.use(categoriesRouter);
  app.use(transactionsRouter);

  app.use(errorHandler);

  return app;
};
