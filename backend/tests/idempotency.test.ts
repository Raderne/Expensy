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

// Like makeApp, but the handler blocks on a gate so a request can be held
// "in flight" while a second, concurrent request with the same key arrives.
const makeBlockingApp = () => {
  const app = express();
  app.use(express.json());
  app.use((req, _res, next) => {
    req.userId = 'u1';
    next();
  });

  let calls = 0;
  let openGate!: () => void;
  const gate = new Promise<void>((resolve) => {
    openGate = resolve;
  });
  let markEntered!: () => void;
  const entered = new Promise<void>((resolve) => {
    markEntered = resolve;
  });

  app.post('/transactions', idempotencyMiddleware, async (_req, res) => {
    calls += 1;
    markEntered();
    await gate;
    res.status(201).json({ id: `tx_${calls}`, calls });
  });
  app.use(errorHandler);

  return { app, getCalls: () => calls, release: () => openGate(), entered };
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

  it('rejects a concurrent in-flight duplicate with 409 and runs the handler once', async () => {
    const { app, getCalls, release, entered } = makeBlockingApp();
    const key = 'concurrent-key-12345678';

    // Fire the first request but don't await it — it blocks inside the handler.
    // supertest dispatches lazily, so attach `.then` to actually send it now.
    const firstPromise = new Promise<request.Response>((resolve, reject) => {
      request(app)
        .post('/transactions')
        .set('Idempotency-Key', key)
        .send({})
        .then(resolve, reject);
    });

    // Wait until the first request has reserved the key and is parked.
    await entered;

    const second = await request(app)
      .post('/transactions')
      .set('Idempotency-Key', key)
      .send({});
    expect(second.status).toBe(409);
    expect(second.body.code).toBe('IDEMPOTENCY_IN_PROGRESS');

    // Let the first request finish.
    release();
    const first = await firstPromise;
    expect(first.status).toBe(201);
    expect(first.body).toEqual({ id: 'tx_1', calls: 1 });

    // The blocked handler ran once; the concurrent duplicate never did.
    expect(getCalls()).toBe(1);
  });

  it('releases the reservation when the first attempt errors, letting a retry proceed', async () => {
    const app = express();
    app.use(express.json());
    app.use((req, _res, next) => {
      req.userId = 'u1';
      next();
    });

    let calls = 0;
    app.post('/transactions', idempotencyMiddleware, (_req, res) => {
      calls += 1;
      if (calls === 1) {
        res.status(500).json({ code: 'BOOM' });
        return;
      }
      res.status(201).json({ id: `tx_${calls}`, calls });
    });
    app.use(errorHandler);

    const key = 'retry-after-error-12345678';
    const first = await request(app)
      .post('/transactions')
      .set('Idempotency-Key', key)
      .send({});
    const second = await request(app)
      .post('/transactions')
      .set('Idempotency-Key', key)
      .send({});

    // The errored response is NOT cached — the retry under the same key runs.
    expect(first.status).toBe(500);
    expect(second.status).toBe(201);
    expect(second.headers['idempotent-replayed']).toBeUndefined();
    expect(calls).toBe(2);
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
  it('reserves a new key and reports it pending to a concurrent caller', () => {
    expect(idempotencyStore.begin('u1', 'k')).toEqual({ state: 'new' });
    expect(idempotencyStore.begin('u1', 'k')).toEqual({ state: 'pending' });
  });

  it('replays a completed response', () => {
    idempotencyStore.begin('u1', 'k');
    idempotencyStore.complete('u1', 'k', 201, { ok: true });
    expect(idempotencyStore.begin('u1', 'k')).toEqual({
      state: 'done',
      status: 201,
      body: { ok: true },
    });
  });

  it('releases a reservation so the key can be retried', () => {
    idempotencyStore.begin('u1', 'k');
    idempotencyStore.release('u1', 'k');
    expect(idempotencyStore.begin('u1', 'k')).toEqual({ state: 'new' });
  });

  it('does not release an already-completed entry', () => {
    idempotencyStore.begin('u1', 'k');
    idempotencyStore.complete('u1', 'k', 201, { ok: true });
    idempotencyStore.release('u1', 'k');
    expect(idempotencyStore.begin('u1', 'k')).toEqual({
      state: 'done',
      status: 201,
      body: { ok: true },
    });
  });

  it('isolates entries per user', () => {
    idempotencyStore.begin('u1', 'k');
    expect(idempotencyStore.begin('u2', 'k')).toEqual({ state: 'new' });
  });
});
