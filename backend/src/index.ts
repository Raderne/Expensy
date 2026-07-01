import { createApp } from './app.js';
import { env } from './config/env.js';
import { startScheduler } from './jobs/scheduler.js';
import { logger } from './lib/logger.js';

const app = createApp();

const host = process.env.HOST ?? '0.0.0.0';

const server = app.listen(env.PORT, host, () => {
  logger.info({ port: env.PORT, host, env: env.NODE_ENV }, 'expensy-backend listening');
  startScheduler();
});

const shutdown = (signal: string): void => {
  logger.info({ signal }, 'shutting down');
  server.close(() => process.exit(0));
};
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
