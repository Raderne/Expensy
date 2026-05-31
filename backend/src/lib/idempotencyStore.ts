// In-memory replay cache for Idempotency-Key. Bounds memory with a hard entry
// cap (oldest evicted FIFO) and a periodic sweep of TTL'd rows. Single-process
// only — swap for Redis if/when the API runs on >1 node.

interface CachedResponse {
  status: number;
  body: unknown;
  expiresAt: number;
}

const TTL_MS = 24 * 60 * 60 * 1000;
const MAX_ENTRIES = 10_000;
const SWEEP_INTERVAL_MS = 60 * 60 * 1000;

const store = new Map<string, CachedResponse>();

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

export const idempotencyStore = {
  get(userId: string, key: string): CachedResponse | null {
    const k = cacheKey(userId, key);
    const v = store.get(k);
    if (!v) return null;
    if (v.expiresAt <= Date.now()) {
      store.delete(k);
      return null;
    }
    return v;
  },

  set(userId: string, key: string, status: number, body: unknown): void {
    if (store.size >= MAX_ENTRIES) {
      // Map preserves insertion order — drop the oldest entry to make room.
      const oldest = store.keys().next().value;
      if (oldest !== undefined) store.delete(oldest);
    }
    store.set(cacheKey(userId, key), { status, body, expiresAt: Date.now() + TTL_MS });
  },

  // Visible for tests.
  _reset(): void {
    store.clear();
  },
};
