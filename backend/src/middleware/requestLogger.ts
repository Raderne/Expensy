import type { Request } from 'express';
import { pinoHttp } from 'pino-http';
import stdSerializers from 'pino-std-serializers';
import { env } from '../config/env.js';
import { logger } from '../lib/logger.js';

const MUTATING_METHODS = new Set(['POST', 'PUT', 'PATCH']);

const SENSITIVE_BODY_KEYS = new Set([
  'password',
  'refreshToken',
  'accessToken',
  'token',
  'currentPassword',
  'newPassword',
  'code',
]);

const SENSITIVE_HEADER_KEYS = new Set(['authorization', 'cookie']);

const redactBody = (body: unknown): unknown => {
  if (body === null || body === undefined) return body;
  if (typeof body !== 'object' || Array.isArray(body)) return body;
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(body as Record<string, unknown>)) {
    out[key] = SENSITIVE_BODY_KEYS.has(key) ? '[Redacted]' : value;
  }
  return out;
};

const redactHeaders = (headers: Record<string, string>): Record<string, string> => {
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(headers)) {
    out[key] = SENSITIVE_HEADER_KEYS.has(key.toLowerCase()) ? '[Redacted]' : value;
  }
  return out;
};

/** Adds parsed JSON body to the `req` log object in development (POST/PUT/PATCH). */
const devReqSerializer = (req: Parameters<typeof stdSerializers.req>[0]) => {
  const serialized = stdSerializers.req(req);
  const expressReq = serialized.raw as Request;

  const withHeaders = {
    ...serialized,
    headers: redactHeaders(serialized.headers),
  };

  if (
    !MUTATING_METHODS.has(serialized.method) ||
    expressReq.body === undefined ||
    expressReq.body === null ||
    (typeof expressReq.body === 'object' &&
      !Array.isArray(expressReq.body) &&
      Object.keys(expressReq.body as object).length === 0)
  ) {
    return withHeaders;
  }

  return { ...withHeaders, body: redactBody(expressReq.body) };
};

/**
 * The container healthcheck probes `GET /health` on loopback every minute, and
 * `deploy.sh`/`status.sh` hit it too. A full request/response line per probe
 * buries real traffic in `docker compose logs`, so successful probes stay
 * silent. A failing one still logs: `/health` is 503 only when the DB is
 * unreachable, which is exactly the line worth keeping.
 */
const isHealthProbe = (url: string | undefined): boolean =>
  url === '/health' || (url?.startsWith('/health?') ?? false);

export const requestLogger = pinoHttp({
  logger,
  // 'info' is pino-http's own default level for every request, so this only
  // ever subtracts the successful health probes.
  customLogLevel: (req, res, err) =>
    !err && res.statusCode < 400 && isHealthProbe(req.url) ? 'silent' : 'info',
  // Always inherit the request id placed on the headers by
  // `requestContextMiddleware`, so logs and the `X-Request-Id` response header
  // share the same value.
  genReqId: (req) => {
    const id = req.headers['x-request-id'];
    return typeof id === 'string' ? id : '';
  },
  ...(env.NODE_ENV === 'development'
    ? {
        serializers: {
          req: devReqSerializer,
          res: stdSerializers.res,
          err: stdSerializers.err,
        },
      }
    : {}),
});
