import type { RequestHandler } from 'express';
import { randomUUID } from 'node:crypto';
import { requestContext } from '../lib/requestContext.js';

// Generates (or accepts) a request id, stores it in AsyncLocalStorage for
// loggers/services, and echoes it back as `X-Request-Id` so the client can
// quote it in bug reports. Caps an inbound id at 128 chars to avoid header
// abuse; falls back to a UUID if the value is empty, too long, or non-string.
const MAX_ID_LENGTH = 128;

export const requestContextMiddleware: RequestHandler = (req, res, next) => {
  const headerId = req.headers['x-request-id'];
  const inbound =
    typeof headerId === 'string' && headerId.length > 0 && headerId.length <= MAX_ID_LENGTH
      ? headerId
      : null;
  const requestId = inbound ?? randomUUID();
  // Normalize the inbound header so downstream consumers (pino-http, services)
  // always see the same id we echo back.
  req.headers['x-request-id'] = requestId;
  res.setHeader('X-Request-Id', requestId);
  requestContext.run({ requestId }, () => next());
};
