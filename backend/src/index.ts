import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';
import { env } from './config/env.js';
import { logger } from './lib/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { healthRouter } from './routes/health.js';

const app = express();

app.use(helmet());
app.use(
  cors({
    origin: env.CORS_ORIGINS.length === 0 ? true : env.CORS_ORIGINS,
    credentials: true,
  }),
);
app.use(express.json({ limit: '256kb' }));
app.use(pinoHttp({ logger }));

app.use(healthRouter);

app.use(errorHandler);

const server = app.listen(env.PORT, () => {
  logger.info({ port: env.PORT, env: env.NODE_ENV }, 'expensy-backend listening');
});

const shutdown = (signal: string) => {
  logger.info({ signal }, 'shutting down');
  server.close(() => process.exit(0));
};
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
