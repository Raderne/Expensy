// Provide deterministic env for tests BEFORE src/config/env.ts is evaluated.
process.env.NODE_ENV = 'test';
process.env.PORT = process.env.PORT ?? '3001';
process.env.LOG_LEVEL = 'fatal';
process.env.DATABASE_URL =
  process.env.DATABASE_URL ?? 'postgresql://expensy:expensy@localhost:5432/expensy_test';
process.env.JWT_ACCESS_SECRET =
  process.env.JWT_ACCESS_SECRET ?? 'test-access-secret-test-access-secret-32+chars';
process.env.JWT_REFRESH_SECRET =
  process.env.JWT_REFRESH_SECRET ?? 'test-refresh-secret-test-refresh-secret-32+chars';
process.env.JWT_ACCESS_TTL = '15m';
process.env.JWT_REFRESH_TTL = '30d';
process.env.CORS_ORIGINS = '';
