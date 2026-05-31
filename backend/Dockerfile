# syntax=docker/dockerfile:1.7

FROM node:20-bookworm-slim AS deps
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --omit=dev --ignore-scripts && npx prisma generate

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

CMD ["sh", "-c", "node dist/index.js"]
