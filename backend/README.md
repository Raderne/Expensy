# Expensy Backend

Node.js + TypeScript REST API.

## Stack decision: Express (not Fastify)

Picked at Phase 01. Reasons:
- Larger ecosystem of typed middleware (helmet, cors, pino-http) ready out of the box.
- Simpler mental model for newcomers to the codebase.
- The endpoint count for v1 is small (~12 routes); Fastify's per-request perf edge does not pay back the migration cost.

Re-evaluate at Phase 07 if request volume warrants it.

## Dependencies & lockfile (Windows + Linux CI)

Vitest pulls in optional Linux/WASM packages (`@emnapi/*`). Recent npm versions only lock
optional deps for your **current OS**, so a lockfile edited on Windows can break `npm ci` on
GitHub Actions (`Missing: @emnapi/core@1.10.0`).

This repo pins those packages in `devDependencies` so they stay in `package-lock.json` on
every machine (npm 10+ otherwise drops Linux-only optional deps when you install on Windows).

After changing dependencies:

```bash
npm install
npm run lockfile:check   # same as CI: npm ci --ignore-scripts
git add package.json package-lock.json
```

If `lockfile:check` still fails locally, regenerate on Linux (Docker):

```bash
docker run --rm -v "%cd%:/app" -w /app node:20-bookworm-slim npm install
```

Then commit the updated `package-lock.json`.

## Quick start

```bash
# 1. Install deps
npm install

# 2. Start Postgres (from repo root)
docker compose up -d

# 3. Configure env
cp .env.example .env

# 4. Generate Prisma client + apply migrations
npx prisma generate
npx prisma migrate dev --name init

# 5. Run
npm run dev
# → http://localhost:3000/health
```

## Scripts

| Script | Purpose |
| --- | --- |
| `npm run dev` | tsx watch mode |
| `npm run build` | `tsc` → `dist/` |
| `npm run start` | run compiled `dist/index.js` |
| `npm run lint` | ESLint |
| `npm run format` | Prettier |
| `npm test` | Vitest |

## Layout

See root `CLAUDE.md` for the layering rules (routes → controllers → services → repositories).

## Operations

### Request tracing

Every response carries an `X-Request-Id` header. Clients are expected to
forward it when they file bug reports; the same id appears on every log
line emitted by the request handler. Inbound clients may set the header
themselves (max 128 chars, falls back to a UUID otherwise).

### Idempotency

`POST /transactions` accepts an `Idempotency-Key` header. The first
successful response is cached per-`(userId, key)` for **24 hours**; any
retry within that window replays the cached body with
`Idempotent-Replayed: true`. The cache is in-memory (single-process); if
the API ever scales beyond one node, swap `src/lib/idempotencyStore.ts`
for a Redis-backed implementation that exposes the same surface.

The key must match `^[A-Za-z0-9_\-:.]{8,128}$`. A `UUID v4` is the
recommended default; the client SDK should mint one per logical save
attempt (not per HTTP retry) so a network failure mid-flight can be
retried safely.

### Backups (self-hosted)

The dataset is small (one row per transaction, per user) so a nightly
`pg_dump` is plenty for v1. Run it on the database host, *not* the API
host:

```bash
# /etc/cron.d/expensy-backup
SHELL=/bin/bash
PATH=/usr/bin:/bin

# Nightly at 03:15 UTC. Adjust path + retention to taste.
15 3 * * * postgres /usr/bin/pg_dump --format=custom --no-owner \
  --file=/var/backups/expensy/expensy-$(date -u +\%Y\%m\%d).dump expensy \
  && find /var/backups/expensy -type f -name 'expensy-*.dump' -mtime +14 -delete
```

Restore with:

```bash
pg_restore --clean --if-exists --no-owner -d expensy expensy-YYYYMMDD.dump
```

Push the dumps off-host (S3, rsync to a second machine, whatever) on the
same cadence — a backup that lives only on the source host is not a
backup. Test the restore quarterly: pick a recent dump, restore into a
throwaway DB, and run `npm run test` against it.
