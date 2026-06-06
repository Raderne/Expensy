import type { RequestHandler } from 'express';
import { AppError } from '../lib/errors.js';
import { idempotencyStore } from '../lib/idempotencyStore.js';

// Idempotency-Key handling for unsafe write endpoints. Must run AFTER
// `requireAuth` so we can scope the cache per user.
//
// Behavior:
// - No header → pass through unchanged.
// - Header present but malformed → 400.
// - Key already has a cached 2xx response → replay it with
//   `Idempotent-Replayed: true` (protects sequential retries).
// - Key is already in flight (a concurrent request reserved it) → 409. This is
//   the case that stops a slow request from being double-submitted: the second
//   identical request is rejected instead of inserting a duplicate row.
// - Otherwise reserve the key, run the handler, and on a 2xx response cache it
//   (so a later retry replays). 4xx/5xx release the reservation so the client
//   can re-submit with corrected input under the same key.

const KEY_REGEX = /^[A-Za-z0-9_\-:.]{8,128}$/;

export const idempotencyMiddleware: RequestHandler = (req, res, next) => {
  const raw = req.headers['idempotency-key'];
  if (raw == null) return next();

  const key = Array.isArray(raw) ? raw[0] : raw;
  if (typeof key !== 'string' || !KEY_REGEX.test(key)) {
    return next(
      new AppError({
        status: 400,
        code: 'INVALID_IDEMPOTENCY_KEY',
        message: 'Idempotency-Key must be 8-128 chars of [A-Za-z0-9_\\-:.]',
      }),
    );
  }

  // Auth-gated endpoints will have `userId` set by `requireAuth`. If somehow
  // missing, fall through and let the next handler reject the request — never
  // cache an unauthenticated response.
  const userId = req.userId;
  if (!userId) return next();

  const outcome = idempotencyStore.begin(userId, key);

  if (outcome.state === 'done') {
    res.setHeader('Idempotent-Replayed', 'true');
    res.status(outcome.status).json(outcome.body);
    return;
  }

  if (outcome.state === 'pending') {
    return next(
      new AppError({
        status: 409,
        code: 'IDEMPOTENCY_IN_PROGRESS',
        message: 'A request with this Idempotency-Key is already being processed.',
      }),
    );
  }

  // outcome.state === 'new': we hold the reservation. Cache the first
  // successful JSON response, and release the reservation if the request ends
  // without producing one (error / non-2xx) so the client can retry.
  let settled = false;
  const originalJson = res.json.bind(res);
  res.json = ((body: unknown) => {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      idempotencyStore.complete(userId, key, res.statusCode, body);
      settled = true;
    }
    return originalJson(body);
  }) as typeof res.json;

  res.on('finish', () => {
    if (!settled) idempotencyStore.release(userId, key);
  });

  next();
};
