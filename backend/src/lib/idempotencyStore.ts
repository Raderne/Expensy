// In-memory idempotency store for Idempotency-Key. Tracks two states per key:
//   - `pending`: a request with this key is currently in flight. Reserved
//     synchronously the moment a key is first seen so concurrent duplicates can
//     be rejected (Node is single-threaded — `begin` runs to completion with no
//     `await`, so the check-and-reserve is atomic across requests).
//   - `done`: the in-flight request finished with a 2xx; its response is cached
//     so a later *sequential* retry within the TTL replays instead of re-posting.
//
// Bounds memory with a hard entry cap (oldest evicted FIFO) and a periodic sweep
// of expired rows. Single-process only — swap for Redis (SET NX) if/when the API
// runs on >1 node.

interface PendingEntry {
  kind: 'pending';
  expiresAt: number;
}

interface DoneEntry {
  kind: 'done';
  status: number;
  body: unknown;
  expiresAt: number;
}

type Entry = PendingEntry | DoneEntry;

// A completed response is replayable for 24h. A reservation only needs to live
// as long as a request reasonably takes; the safety TTL stops a crashed/hung
// request from locking a key forever (`res` finish normally settles it first).
const DONE_TTL_MS = 24 * 60 * 60 * 1000;
const PENDING_TTL_MS = 60 * 1000;
const MAX_ENTRIES = 10_000;
const SWEEP_INTERVAL_MS = 60 * 60 * 1000;

const store = new Map<string, Entry>();

const cacheKey = (userId: string, key: string): string => `${userId}:${key}`;

const sweep = (): void => {
  const now = Date.now();
  for (const [k, v] of store) {
    if (v.expiresAt <= now) store.delete(k);
  }
};

// Periodic expiry sweep. `.unref()` so a pending timer doesn't keep the
// process alive during graceful shutdown / tests.
const sweeper = setInterval(sweep, SWEEP_INTERVAL_MS);
sweeper.unref();

const evictIfFull = (): void => {
  if (store.size >= MAX_ENTRIES) {
    // Map preserves insertion order — drop the oldest entry to make room.
    const oldest = store.keys().next().value;
    if (oldest !== undefined) store.delete(oldest);
  }
};

const live = (k: string): Entry | null => {
  const v = store.get(k);
  if (!v) return null;
  if (v.expiresAt <= Date.now()) {
    store.delete(k);
    return null;
  }
  return v;
};

export type BeginOutcome =
  | { state: 'new' }
  | { state: 'pending' }
  | { state: 'done'; status: number; body: unknown };

export const idempotencyStore = {
  // Atomically (within the single-threaded event loop) inspect the key and, if
  // it is free, reserve it as `pending`. The caller MUST eventually call
  // `complete` or `release` for a `new` outcome.
  begin(userId: string, key: string): BeginOutcome {
    const k = cacheKey(userId, key);
    const existing = live(k);
    if (existing) {
      if (existing.kind === 'done') {
        return { state: 'done', status: existing.status, body: existing.body };
      }
      return { state: 'pending' };
    }
    evictIfFull();
    store.set(k, { kind: 'pending', expiresAt: Date.now() + PENDING_TTL_MS });
    return { state: 'new' };
  },

  // Promote a reservation to a cached 2xx response.
  complete(userId: string, key: string, status: number, body: unknown): void {
    store.set(cacheKey(userId, key), {
      kind: 'done',
      status,
      body,
      expiresAt: Date.now() + DONE_TTL_MS,
    });
  },

  // Drop a reservation that did not produce a cacheable response (error /
  // non-2xx) so the client can retry under the same key.
  release(userId: string, key: string): void {
    const k = cacheKey(userId, key);
    const v = store.get(k);
    if (v && v.kind === 'pending') store.delete(k);
  },

  // Visible for tests.
  _reset(): void {
    store.clear();
  },
};
