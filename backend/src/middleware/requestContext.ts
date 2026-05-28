import type { RequestHandler } from 'express';
import { randomUUID } from 'node:crypto';
import { requestContext } from '../lib/requestContext.js';

export const requestContextMiddleware: RequestHandler = (req, _res, next) => {
  const headerId = req.headers['x-request-id'];
  const requestId = typeof headerId === 'string' && headerId.length > 0 ? headerId : randomUUID();
  requestContext.run({ requestId }, () => next());
};
