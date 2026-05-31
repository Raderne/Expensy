import type { RequestHandler } from 'express';
import { AppError } from '../lib/errors.js';
import { idempotencyStore } from '../lib/idempotencyStore.js';

// Idempotency-Key handling for unsafe POST endpoints. Must run AFTER
// `requireAuth` so we can scope the cache per user.
//
// Behavior:
// - No header → pass through unchanged.
// - Header present but malformed → 400.
// - Header present + previously-cached 2xx response → replay the cached
//   status + body with `Idempotent-Replayed: true`.
// - Header present + new request → run the handler, then cache its 2xx
//   response so a retry within 24h replays instead of double-posting.
//
// The middleware only caches successful responses. 4xx/5xx pass through so
// the client can re-submit with corrected input under the same key.

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

  const cached = idempotencyStore.get(userId, key);
  if (cached) {
    res.setHeader('Idempotent-Replayed', 'true');
    res.status(cached.status).json(cached.body);
    return;
  }

  // Intercept the first successful JSON response so we can cache it. We patch
  // `res.json` (not `res.send`) because every controller in this app emits
  // JSON via `res.json`. Errors bypass this path (they flow through the
  // error handler) and are intentionally NOT cached.
  const originalJson = res.json.bind(res);
  res.json = ((body: unknown) => {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      idempotencyStore.set(userId, key, res.statusCode, body);
    }
    return originalJson(body);
  }) as typeof res.json;

  next();
};
