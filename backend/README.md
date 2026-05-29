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
