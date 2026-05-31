# 01 — Deploying the Backend for Free

## What we're hosting

The backend is a stateless Node 20 + Express + Prisma server that needs:
- A persistent **PostgreSQL 16** database.
- One always-on (or quickly-waking) **HTTP service** that the phone hits over HTTPS.
- Long-lived secrets in environment variables (`DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`).

Anything that runs a Dockerfile, Node script, or a Procfile can host this. The constraint is whether the free tier can keep it warm enough to feel snappy from a phone.

## The recommendation

**Postgres on Neon + API on Fly.io.** This is what I'd actually pick.

Why:
- Neon's free tier is generous (0.5 GB storage, no time-bombed trial), supports branching, and gives you a pooled connection string that Prisma understands.
- Fly.io's `auto_stop_machines = "suspend"` keeps a VM hot for free; cold-starts are ~1 second when it does sleep. Their free allowance covers up to three `shared-cpu-1x@256mb` VMs.
- The two providers are in different jurisdictions / orgs, so a billing change at one doesn't kill both. That matters more than people realize.

## Alternative providers

| Provider | Free tier | Watch out for |
|---|---|---|
| **Render** | Web Service free tier (sleeps after 15 min idle, 750 hr/mo). Free Postgres expires after **90 days**. | The 90-day Postgres clock is brutal; pair with Neon if you go Render-for-API. |
| **Railway** | $5 of usage credit per month. Easy DX. | If you exceed the credit it bills you; set a hard cap. |
| **Koyeb** | One free `nano` web service, one Postgres (256 MB). | Smaller and quieter ecosystem; fewer docs when something breaks. |
| **Supabase** | 500 MB Postgres + auth + storage. | Postgres pauses after 7 days of inactivity. You'd only use the DB here, not their auth (you already have your own). |
| **PlanetScale** | Was free, now paid. Don't bother. | — |
| **Vercel / Netlify Functions** | Generous compute. | Bad fit: Prisma + long-lived TCP connections to Postgres don't suit serverless without an extra connection pooler. |

Stick with the recommendation unless you have a specific reason.

---

## Step-by-step: Neon (database)

1. **Sign up** at `https://neon.tech` (free, GitHub auth is fine).
2. Create a new project. Name it `expensy-prod`. Pick a region close to where you live (Frankfurt / Paris if you're in Europe, IAD/SFO in the US).
3. The dashboard shows you two connection strings. You want the **pooled** one (look for "Pooled connection" or a host name containing `-pooler`). Copy it — it looks like:
   ```
   postgresql://expensy_owner:<password>@ep-foo-bar-pooler.eu-central-1.aws.neon.tech/expensy?sslmode=require
   ```
4. Save this as `DATABASE_URL` somewhere safe (you'll paste it into Fly's secrets later, NOT into a `.env` file in the repo).

### One-time migration to Neon

From your laptop, with `DATABASE_URL` in your shell:

```powershell
$env:DATABASE_URL = "postgresql://...pooler..."
cd C:\Dev\projects\Expensy\backend
npx prisma migrate deploy
npx prisma db seed
```

`migrate deploy` is the production-safe variant — it applies pending migrations without prompting and without trying to generate new ones. **Never** run `migrate dev` against Neon; it can drop and recreate the schema if it thinks the local state has drifted.

Verify with:
```powershell
npx prisma studio
```
The studio will open in your browser pointed at Neon. You should see the seeded categories.

---

## Step-by-step: Fly.io (API)

### Prereqs

1. Install flyctl:
   ```powershell
   iwr https://fly.io/install.ps1 -useb | iex
   ```
2. Sign up / log in:
   ```powershell
   fly auth signup    # or: fly auth login
   ```
   Fly asks for a credit card during signup but the free allowance covers our usage; you won't be billed unless you exceed it.

### Add a Dockerfile to the backend

Fly can deploy a Node app without a Dockerfile, but a hand-rolled one is more predictable. Create `backend/Dockerfile`:

```dockerfile
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
ENV NODE_ENV=production
ENV PORT=3000
COPY --from=deps   /app/node_modules ./node_modules
COPY --from=deps   /app/prisma       ./prisma
COPY --from=build  /app/dist         ./dist
COPY package.json ./
EXPOSE 3000
# `migrate deploy` runs every boot; it's a no-op when there's nothing pending.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/index.js"]
```

And `backend/.dockerignore`:

```
node_modules
dist
.env
.env.*
*.log
.git
tests
```

### Create the Fly app

From `backend/`:

```powershell
cd C:\Dev\projects\Expensy\backend
fly launch --no-deploy
```

Answers when prompted:
- App name: `expensy-api` (or whatever; must be globally unique on Fly).
- Region: closest to you.
- Postgres? **No** — you're using Neon.
- Redis? **No**.
- Deploy now? **No**.

This writes a `fly.toml`. Edit it so it matches:

```toml
app = "expensy-api"
primary_region = "fra"   # change to your region

[build]

[env]
  PORT = "3000"
  LOG_LEVEL = "info"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = "suspend"
  auto_start_machines = true
  min_machines_running = 0

  [http_service.concurrency]
    type = "requests"
    soft_limit = 50
    hard_limit = 200

[[vm]]
  memory = "256mb"
  cpu_kind = "shared"
  cpus = 1
```

`suspend` is the new lightweight pause — when the API is idle it's frozen in RAM, not torn down, so first-request wake is ~200 ms instead of ~3 s.

### Set secrets

```powershell
fly secrets set `
  DATABASE_URL="postgresql://...pooler..." `
  JWT_ACCESS_SECRET="$([Convert]::ToBase64String((New-Object byte[] 32 | %{ [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($_); $_ })))" `
  JWT_REFRESH_SECRET="$([Convert]::ToBase64String((New-Object byte[] 32 | %{ [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($_); $_ })))" `
  JWT_ACCESS_TTL="15m" `
  JWT_REFRESH_TTL="30d" `
  CORS_ORIGINS="https://expensy.app"
```

Notes:
- Secrets are encrypted at rest on Fly. They never appear in the Dockerfile, the repo, or `fly.toml`.
- The base64-of-32-random-bytes trick gives you a JWT secret that comfortably exceeds the "32+ chars" guideline from `CLAUDE.md`. Generate each one **separately** (don't reuse).
- `CORS_ORIGINS` is irrelevant for a mobile-only client (Flutter doesn't enforce CORS) but harmless to set.

### Deploy

```powershell
fly deploy
```

When it's done:
```powershell
fly status
fly logs
```

Your API is at `https://expensy-api.fly.dev`. Test it:
```powershell
Invoke-RestMethod https://expensy-api.fly.dev/health
```

If `/health` doesn't exist yet, add it. Fly's healthcheck doesn't require it but you'll be glad to have it when something hangs.

### Aftermath

- Logs: `fly logs` for the live tail, `fly logs --no-tail` for a one-shot dump.
- Shell into the running container: `fly ssh console`. Useful for `npx prisma studio` etc.
- Scale down to zero overnight: not needed; `auto_stop_machines = "suspend"` already does that.
- Scale up for real load: `fly scale memory 512` or `fly scale count 2`.

---

## Pointing the Flutter app at the deployed API

`frontend/lib/config/env.dart` already reads `API_BASE_URL` via `--dart-define`. So when you build the release APK:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://expensy-api.fly.dev
```

See `02-android-apk-sideload.md` for the full build.

For day-to-day development you keep using `http://10.0.2.2:3000` (emulator) or your LAN IP (physical device) — the default in `env.dart` covers the emulator case so you typically don't need `--dart-define` while developing.

---

## Custom domain (optional)

If you want `api.expensy.app` instead of `expensy-api.fly.dev`:

1. Buy a domain (Cloudflare Registrar is at-cost — ~$10/yr for `.app`).
2. On Cloudflare DNS, add a `CNAME` for `api` pointing to `expensy-api.fly.dev`, proxied **off** (Fly handles TLS itself).
3. On Fly:
   ```powershell
   fly certs create api.expensy.app
   ```
4. Wait ~30 s, verify:
   ```powershell
   fly certs show api.expensy.app
   ```
   Status should become `Issued`.

Now your `API_BASE_URL` is `https://api.expensy.app` — much nicer in the keystore-baked release APK if you ever change hosting providers (you just repoint DNS, the APK keeps working).

---

## When Neon's free tier isn't enough

You'll hit a limit when:
- The DB grows past **0.5 GB** (a lot of transactions; Expensy is text-heavy, so realistically thousands of users worth).
- You want **point-in-time restore** older than 24 h.

When that happens the next step is Neon Launch at $19/mo, or self-host Postgres on a $6/mo Hetzner box.

## Pitfalls people hit

- **Prisma + connection pooling.** You MUST use Neon's pooled URL with Prisma; the direct URL caps you at ~10 connections and Fly machines burn through that fast on cold-start. The pooler URL has `-pooler` in the hostname.
- **Long-running migrations on a free VM.** If a migration takes more than 60 s, Fly's deploy healthcheck will kill the container. Run heavy migrations from your laptop (`prisma migrate deploy` with the Neon URL exported) before deploying the new code.
- **CORS surprises.** If you ever build a web client, you must add its origin to `CORS_ORIGINS`. The mobile client is unaffected.
- **Secrets in logs.** Pino is fine, but make sure no controller `console.log`s the JWT or full request bodies. `pino-http` redacts auth headers; custom logs need explicit `redact: ['password', 'token']`.
