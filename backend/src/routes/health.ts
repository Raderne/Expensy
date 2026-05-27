import { Router } from 'express';
import { prisma } from '../lib/prisma.js';

export const healthRouter = Router();

healthRouter.get('/health', async (_req, res) => {
  let db: 'up' | 'down' = 'down';
  try {
    await prisma.$queryRaw`SELECT 1`;
    db = 'up';
  } catch {
    db = 'down';
  }

  const status = db === 'up' ? 200 : 503;
  res.status(status).json({ status: db === 'up' ? 'ok' : 'degraded', db });
});
