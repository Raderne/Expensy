# Expensy Backend

Node.js + TypeScript REST API.

## Stack decision: Express (not Fastify)

Picked at Phase 01. Reasons:
- Larger ecosystem of typed middleware (helmet, cors, pino-http) ready out of the box.
- Simpler mental model for newcomers to the codebase.
- The endpoint count for v1 is small (~12 routes); Fastify's per-request perf edge does not pay back the migration cost.

Re-evaluate at Phase 07 if request volume warrants it.

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
