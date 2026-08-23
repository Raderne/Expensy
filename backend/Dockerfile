# syntax=docker/dockerfile:1.7

FROM node:20-bookworm-slim AS deps
WORKDIR /app
# Must match the runtime stage. Prisma picks the engine build from the libssl it
# detects, and with no openssl here it falls back to `openssl-1.1.x` -- baking an
# engine the (openssl-3.0.x) runtime rejects, which sends it back to downloading
# one at deploy time. That is the failure this stage exists to prevent.
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
COPY prisma ./prisma
# `--ignore-scripts` skips @prisma/engines' postinstall, which is what downloads
# the query-engine and schema-engine binaries. `prisma generate` only needs the
# former, so the build would still pass -- but `prisma migrate status|deploy`
# (the deploy gate in scripts/deploy.sh) needs schema-engine and would try to
# download it at deploy time, inside a container that can't write to
# /app/node_modules. Fetch the engines here instead, where we are root.
RUN npm ci --omit=dev --ignore-scripts \
 && npm rebuild @prisma/engines \
 && npx prisma generate

FROM node:20-bookworm-slim AS build
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --ignore-scripts && npx prisma generate
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:20-bookworm-slim AS runtime
WORKDIR /app
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production
ENV PORT=3000
COPY --from=deps   /app/node_modules ./node_modules
COPY --from=deps   /app/prisma       ./prisma
COPY --from=build  /app/dist         ./dist
COPY package.json ./
EXPOSE 3000

# /health returns 200 only when the DB is reachable. 60s (not Docker's 30s
# default) is plenty: nothing auto-restarts on this status today, it only
# feeds the STATUS column in `docker compose ps`. Keep the interval here so
# it ships with the image -- do not redefine it in the prod compose file,
# which would silently override this.
HEALTHCHECK --interval=60s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/health').then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["sh", "-c", "node dist/index.js"]
