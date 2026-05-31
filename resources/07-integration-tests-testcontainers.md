# 07 — Integration Tests with Testcontainers

Right now the backend's Vitest suite mocks every repository. That's fast and reliable but it means we never exercise the actual Prisma query, the actual SQL, or the actual schema. The thing that bit you in the past was exactly that gap: `dashboardService.getSummary` started calling `recurringExpenseService.ensureMaterialized`, and the `income.service.test.ts` mock didn't cover the newly-used repo. Mock divergence is the cost of mock-everywhere.

Testcontainers fixes this by spinning up a real Postgres in a Docker container per test run. Real schema, real SQL, real Prisma — but disposable. Combined with the unit tests already in place, you get the best of both: fast feedback on logic, true confidence on integration.

## Prereqs

- Docker Desktop installed and running on your laptop (already required if you're going the Fly route — Fly uses Docker too).
- CI: GitHub Actions' `ubuntu-latest` runners have Docker preinstalled.

## Install

```powershell
cd C:\Dev\projects\Expensy\backend
npm install --save-dev @testcontainers/postgresql
```

## A shared fixture

`backend/tests/helpers/database.ts`:

```ts
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import { PrismaClient } from '@prisma/client';
import { execSync } from 'node:child_process';

let container: StartedPostgreSqlContainer | null = null;
let prisma: PrismaClient | null = null;

export async function startTestDb(): Promise<PrismaClient> {
  if (prisma) return prisma;

  container = await new PostgreSqlContainer('postgres:16-alpine')
    .withDatabase('expensy_test')
    .withUsername('expensy')
    .withPassword('expensy')
    .start();

  const url = container.getConnectionUri();
  process.env.DATABASE_URL = url;

  // Apply schema. `migrate deploy` is idempotent on a fresh DB.
  execSync('npx prisma migrate deploy', {
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'inherit',
  });
  // Seed the system categories the app expects.
  execSync('npx prisma db seed', {
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'inherit',
  });

  prisma = new PrismaClient({ datasources: { db: { url } } });
  return prisma;
}

export async function stopTestDb(): Promise<void> {
  await prisma?.$disconnect();
  await container?.stop();
  prisma = null;
  container = null;
}

/**
 * Truncate every table except `_prisma_migrations`. Cheaper than restarting
 * the container; gives every test a clean slate.
 */
export async function resetDb(client: PrismaClient): Promise<void> {
  const tables: { tablename: string }[] = await client.$queryRaw`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'
  `;
  if (tables.length === 0) return;
  const quoted = tables.map(t => `"${t.tablename}"`).join(', ');
  await client.$executeRawUnsafe(`TRUNCATE ${quoted} RESTART IDENTITY CASCADE`);
}
```

## A global setup file

Vitest has `globalSetup` / `globalTeardown` to start the container once for the whole run.

`backend/tests/global-setup.ts`:

```ts
import { startTestDb, stopTestDb } from './helpers/database';

export async function setup() {
  await startTestDb();
}
export async function teardown() {
  await stopTestDb();
}
```

`backend/vitest.config.ts` — add the file alongside whatever else is configured:

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: false,
    environment: 'node',
    globalSetup: ['./tests/global-setup.ts'],
    testTimeout: 30_000,   // container start can take ~10s
    hookTimeout: 30_000,
  },
});
```

## Writing an integration test

`backend/tests/integration/recurring-expense.integration.test.ts`:

```ts
import { describe, it, expect, beforeAll, beforeEach } from 'vitest';
import { startTestDb, resetDb } from '../helpers/database';
import { recurringExpenseService } from '../../src/services/recurringExpenseService.js';
import { transactionRepository } from '../../src/repositories/transactionRepository.js';
import { PrismaClient } from '@prisma/client';

let prisma: PrismaClient;

beforeAll(async () => {
  prisma = await startTestDb();
});

beforeEach(async () => {
  await resetDb(prisma);
});

describe('recurring expense materialization', () => {
  it('creates one transaction per occurrence between anchor and today', async () => {
    const user = await prisma.user.create({
      data: { email: 't@e.st', name: 'Tester', passwordHash: 'x' },
    });
    const category = await prisma.category.findFirstOrThrow({
      where: { key: 'subscriptions' },
    });

    const anchor = new Date();
    anchor.setDate(anchor.getDate() - 21);   // 3 weeks ago

    await recurringExpenseService.create(user.id, {
      label: 'Claude Pro',
      amount: 20,
      frequency: 'WEEKLY',
      anchorDate: anchor,
      categoryId: category.id,
    });

    await recurringExpenseService.ensureMaterialized(user.id);

    const tx = await prisma.transaction.findMany({
      where: { userId: user.id, categoryId: category.id },
    });
    expect(tx).toHaveLength(4); // weeks 0, 1, 2, 3
    expect(tx.every(t => Number(t.amount) === -20)).toBe(true);
  });

  it('is idempotent — re-materializing does not duplicate', async () => {
    // ... setup same as above, then call ensureMaterialized twice, assert count unchanged.
  });
});
```

The conventions:
- **Folder name**: `tests/integration/` so you can run only integration tests with `vitest tests/integration` when iterating, and skip them in pre-commit hooks if they're slow.
- **No mocks** in integration files. The whole point is to exercise the real stack.
- **`beforeEach(resetDb)`** instead of `afterEach`. Same effect, but if a test errors before its cleanup runs, the next test still starts clean.
- **`findFirstOrThrow`** for seeded data — if the seed didn't run, you want to fail loudly.

## Running

```powershell
cd C:\Dev\projects\Expensy\backend

# all tests (unit + integration)
npm test

# only integration
npx vitest run tests/integration

# only unit
npx vitest run --exclude tests/integration
```

The first integration run is slow (~15 s while Docker pulls `postgres:16-alpine` if you don't already have it). Subsequent runs are ~2 s for startup + the test time.

## In CI

The workflow from `06-ci-cd-github-actions.md` already exposes Docker. Testcontainers will use it automatically. The Postgres `services:` block in that workflow becomes redundant once you've switched fully to testcontainers — you can remove it. Or leave it for tests that want a long-lived DB across many specs.

Optionally split unit vs integration into separate matrix jobs so a flaky integration test doesn't block a hotfix:

```yaml
strategy:
  matrix:
    suite: [unit, integration]
steps:
  - run: |
      if [ "${{ matrix.suite }}" = "unit" ]; then
        npx vitest run --exclude tests/integration
      else
        npx vitest run tests/integration
      fi
```

## When NOT to use testcontainers

- **For controllers you've already covered with route-level Supertest+mocks.** Don't double up.
- **For pure cadence math** (`backend/src/lib/recurrence.ts`). It's a function. Unit-test it with no container.
- **In a pre-commit hook.** Too slow. Pre-commit runs unit tests; CI runs both.

## Sketch: a smaller alternative if Docker is a deal-breaker

If you don't want a Docker dependency on contributors' laptops, `pg-mem` is an in-memory Postgres that runs in plain Node. It supports a useful subset of Postgres — enough for simple Prisma queries, not enough for advanced features like `pg_trgm` or window functions. Migration files have to be replayed manually because `pg-mem` doesn't understand `prisma migrate`. Use it only if Docker is genuinely impractical; for everything else, real Postgres in a container is closer to production and worth the 10-second cold start.

## Pitfalls

- **Schema drift between local migrations and Neon.** If you write a migration locally, run `migrate dev` against your laptop's Postgres, then ship to Neon via `migrate deploy` — fine. But if you also ran `migrate dev` against Neon at some point (because you forgot which terminal you were in), Prisma's shadow database can diverge. Testcontainers replays from `prisma/migrations/` so it always matches what's checked in, not what's in some random remote DB.
- **`prisma db seed` exits non-zero on a re-run** if the seed isn't upsert-based. Make sure `prisma/seed.ts` is idempotent.
- **Container leaks** on test interruption (`Ctrl+C`). Testcontainers tries to clean up but if you kill the process hard, you can end up with orphan containers. `docker ps -a | grep testcontainers` and `docker rm -f <id>` is the fix.
- **Windows + Docker Desktop slowness** for the initial container start. Once the image is cached locally it's fast, but the first pull can take a minute.
