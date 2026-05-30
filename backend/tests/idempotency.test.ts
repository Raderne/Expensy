import express from 'express';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { idempotencyMiddleware } from '../src/middleware/idempotency.js';
import { idempotencyStore } from '../src/lib/idempotencyStore.js';
import { errorHandler } from '../src/middleware/errorHandler.js';

// Build a minimal app that stubs `req.userId` (skipping the real JWT path),
// applies the idempotency middleware, and returns a counter so we can assert
// the handler runs exactly once across replays.
const makeApp = (userId: string | null = 'u1') => {
  const app = express();
  app.use(express.json());
  app.use((req, _res, next) => {
    if (userId) req.userId = userId;
    next();
  });

  let calls = 0;
  app.post('/transactions', idempotencyMiddleware, (_req, res) => {
    calls += 1;
    res.status(201).json({ id: `tx_${calls}`, calls });
  });

  // Surface validation errors as JSON.
  app.use(errorHandler);

  return { app, getCalls: () => calls };
};

beforeEach(() => {
  idempotencyStore._reset();
});

afterEach(() => {
  idempotencyStore._reset();
});

describe('idempotencyMiddleware', () => {
  it('passes through when no Idempotency-Key header is sent', async () => {
    const { app, getCalls } = makeApp();
    const a = await request(app).post('/transactions').send({});
    const b = await request(app).post('/transactions').send({});
    expect(a.status).toBe(201);
    expect(b.status).toBe(201);
    expect(getCalls()).toBe(2);
  });

  it('replays the cached response on a repeated key', async () => {
    const { app, getCalls } = makeApp();
    const key = 'client-key-abc12345';
    const first = await request(app)
      .post('/transactions')
      .set('Idempotency-Key', key)
      .send({});
    const second = await request(app)
      .post('/transactions')
      .set('Idempotency-Key', key)
      .send({});

    expect(first.status).toBe(201);
    expect(first.body).toEqual({ id: 'tx_1', calls: 1 });
    expect(first.headers['idempotent-replayed']).toBeUndefined();

    expect(second.status).toBe(201);
    expect(second.body).toEqual({ id: 'tx_1', calls: 1 });
    expect(second.headers['idempotent-replayed']).toBe('true');

    expect(getCalls()).toBe(1);
  });

  it('scopes the cache per user — same key on a different user runs anew', async () => {
    const keyShared = 'shared-key-12345678';
    const a = makeApp('u1');
    const b = makeApp('u2');

    await request(a.app).post('/transactions').set('Idempotency-Key', keyShared).send({});
    const second = await request(b.app)
      .post('/transactions')
      .set('Idempotency-Key', keyShared)
      .send({});

    expect(second.body.id).toBe('tx_1');
    expect(second.headers['idempotent-replayed']).toBeUndefined();
    expect(a.getCalls()).toBe(1);
    expect(b.getCalls()).toBe(1);
  });

  it('rejects too-short keys with 400', async () => {
    const { app, getCalls } = makeApp();
    const res = await request(app)
      .post('/transactions')
      .set('Idempotency-Key', 'short')
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('INVALID_IDEMPOTENCY_KEY');
    expect(getCalls()).toBe(0);
  });

  it('rejects keys with disallowed characters with 400', async () => {
    const { app, getCalls } = makeApp();
    const res = await request(app)
      .post('/transactions')
      .set('Idempotency-Key', 'key with spaces!')
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.code).toBe('INVALID_IDEMPOTENCY_KEY');
    expect(getCalls()).toBe(0);
  });
});

describe('idempotencyStore', () => {
  it('returns null for unknown keys', () => {
    expect(idempotencyStore.get('u1', 'nope')).toBeNull();
  });

  it('round-trips a stored response', () => {
    idempotencyStore.set('u1', 'k', 201, { ok: true });
    const got = idempotencyStore.get('u1', 'k');
    expect(got).not.toBeNull();
    expect(got?.status).toBe(201);
    expect(got?.body).toEqual({ ok: true });
  });

  it('isolates entries per user', () => {
    idempotencyStore.set('u1', 'k', 201, { who: 'u1' });
    expect(idempotencyStore.get('u2', 'k')).toBeNull();
  });
});
