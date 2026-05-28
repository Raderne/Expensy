import type { RequestHandler } from 'express';
import { AppError } from '../lib/errors.js';
import { verifyAccessToken } from '../lib/jwt.js';
import { requestContext } from '../lib/requestContext.js';

declare module 'express-serve-static-core' {
  interface Request {
    userId?: string;
  }
}

export const requireAuth: RequestHandler = (req, _res, next) => {
  const header = req.header('authorization');
  if (!header || !header.toLowerCase().startsWith('bearer ')) {
    return next(
      new AppError({ status: 401, code: 'MISSING_TOKEN', message: 'Missing bearer token' }),
    );
  }
  const token = header.slice(7).trim();
  try {
    const payload = verifyAccessToken(token);
    req.userId = payload.sub;
    requestContext.setActor(payload.sub);
    return next();
  } catch {
    return next(
      new AppError({ status: 401, code: 'INVALID_TOKEN', message: 'Invalid or expired token' }),
    );
  }
};
