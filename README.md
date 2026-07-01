# Expensy

A personal expense tracking mobile app. Flutter frontend (iOS + Android) backed by a Node.js REST API.

**Current version:** 1.6.3

---

## Repository layout

```
Expensy/
├── backend/      Node.js 20 + Express + Prisma + PostgreSQL
└── frontend/     Flutter 3.x (iOS + Android)
```

---

## Tech stack

| Layer              | Tech                                              |
| ------------------ | ------------------------------------------------- |
| API framework      | Express 4 + TypeScript (strict)                   |
| ORM                | Prisma 6 + PostgreSQL 16                          |
| Auth               | JWT (access + refresh) + bcrypt                   |
| Validation         | Zod                                               |
| Logging            | Pino (structured JSON)                            |
| Testing (backend)  | Vitest + Supertest                                |
| Mobile framework   | Flutter 3 / Dart 3                                |
| State management   | Riverpod                                          |
| Routing            | go_router                                         |
| HTTP client        | Dio (auth + retry interceptors)                   |
| Local storage      | flutter_secure_storage (tokens) + Hive CE (cache) |
| Testing (frontend) | flutter_test + integration_test + mocktail        |

---

## Prerequisites

- Node.js 20 LTS
- npm 10+
- Flutter stable channel (3.x) + Dart 3.x
- PostgreSQL 16 (or run `docker compose up -d` from the repo root)
- A connected device or emulator for the Flutter app

---

## Getting started

### 1 — Start the database

```bash
docker compose up -d
```

This starts a PostgreSQL 16 container on port 5432 with the credentials expected by `.env.example`.

### 2 — Backend

```bash
cd backend
npm install
cp .env.example .env        # fill in secrets
npx prisma migrate dev      # create schema + seed categories
npm run dev                 # http://localhost:3000
```

Verify: `GET http://localhost:3000/health` returns `{ "status": "ok" }`.

### 3 — Frontend

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000  # Android emulator
# or
flutter run --dart-define=API_BASE_URL=http://localhost:3000  # iOS simulator
```

Use `10.0.2.2` to reach the host machine from an Android emulator; use `localhost` for iOS.

---

## Environment variables

Copy `backend/.env.example` to `backend/.env` and fill in the values below. Never commit `.env`.

| Variable                   | Description                                                         |
| -------------------------- | ------------------------------------------------------------------- |
| `DATABASE_URL`             | PostgreSQL connection string                                        |
| `JWT_ACCESS_SECRET`        | ≥ 32 random chars                                                   |
| `JWT_REFRESH_SECRET`       | ≥ 32 random chars (different from access)                           |
| `JWT_ACCESS_TTL`           | e.g. `15m`                                                          |
| `JWT_REFRESH_TTL`          | e.g. `30d`                                                          |
| `PORT`                     | API port (default `3000`)                                           |
| `LOG_LEVEL`                | `info` / `debug`                                                    |
| `CORS_ORIGINS`             | Comma-separated allowed origins                                     |
| `RESET_CODE_TTL_MIN`       | Password-reset OTP lifetime in minutes (default `15`)              |
| `SMTP_HOST` / `SMTP_PORT`  | Mail server for reset codes — when unset, codes are logged instead |
| `SMTP_USER` / `SMTP_PASSWORD` / `SMTP_FROM` | SMTP credentials + sender address                 |
| `GEMINI_API_KEY`           | Google Gemini key — powers the AI goal estimate (optional; feature returns 503 when unset) |
| `GEMINI_MODEL`             | Gemini model id (default `gemini-2.0-flash`; use `gemini-2.5-flash`) |
| `GEMINI_MAX_INPUT_TOKENS`  | Prompt-size guard (default `8000`)                                  |
| `GEMINI_MAX_OUTPUT_TOKENS` | Response length cap (default `1024`)                                |
| `GEMINI_THINKING_BUDGET`   | Thinking-token budget for 2.5+ models; `0` disables reasoning       |
| `GOAL_ESTIMATE_TTL_HOURS`  | How long a goal estimate is cached before recompute (default `24`) |

The Flutter app receives its API URL via `--dart-define=API_BASE_URL=<url>`. No hard-coded URLs.

---

## Common commands

### Backend (`cd backend`)

```bash
npm run dev              # watch mode (tsx)
npm run build            # compile TypeScript → dist/
npm run start            # run compiled build
npm run lint             # ESLint
npm run test             # Vitest (single run)
npm run test:watch       # Vitest (watch)
npx prisma migrate dev --name <name>   # create migration
npx prisma migrate deploy              # apply migrations (prod)
npx prisma studio                      # visual DB browser
```

### Frontend (`cd frontend`)

```bash
flutter pub get
flutter run                   # connected device
flutter build apk --release   # Android APK
flutter build ios --release   # iOS archive (macOS required)
flutter test                  # unit + widget tests
flutter analyze               # static analysis
dart format .                 # format code
```

---

## Architecture

### Backend layers

```
src/
  routes/          Thin HTTP handlers — delegate immediately to controllers
  controllers/     Shape req/res — call services only
  services/        Business logic and orchestration
  repositories/    Prisma queries — no HTTP concerns
  middleware/       requireAuth, errorHandler, requestLogger, idempotency
  schemas/         Zod request/response shapes
  lib/             jwt, password, logger, mailer, errors, prisma client
  config/          Zod-validated env loader
```

- Controllers never import Prisma. Services never touch `req`/`res`.
- All errors bubble up to a single `errorHandler` middleware.
- Idempotency is enforced via an in-memory store (Redis-replaceable) keyed on `Idempotency-Key` headers.

### Frontend layers (feature-first)

```
lib/
  app/                 Root widget, router
  config/              Constants, env
  core/                Shared widgets, theme, network client, cache
  features/<name>/
    data/              Repository implementations, DTOs
    application/       Riverpod providers, controllers
    domain/            Entities, value objects
    presentation/      Screens and feature-specific widgets
```

Shared widgets live in `core/`. Features must not reach into each other's folders.

---

## Domain model

| Entity                | Purpose                                                            |
| --------------------- | ------------------------------------------------------------------ |
| `User`                | Account — email + hashed password                                  |
| `Category`            | Spending category (system-seeded + user-created)                   |
| `Transaction`         | Single income or expense entry                                     |
| `Budget`              | Monthly spending cap per user                                      |
| `RecurringIncome`     | Scheduled income source (day-of-month)                             |
| `RecurringExpense`    | Scheduled expense (weekly / bi-weekly / monthly / custom)          |
| `RecurringOccurrence` | One instance of a recurring item (PENDING / CONFIRMED / POSTPONED) |
| `Goal`                | Savings goal — target/saved amount, optional AI time-to-reach estimate |
| `Contact`             | A person you split expenses or share recurring costs with          |
| `TransactionSplit`    | One person's share of a split transaction                          |
| `RecurringExpenseShare` | A contact's share of a shared recurring expense                  |
| `Reimbursement`       | A repayment recorded against what a contact owes                   |
| `PasswordResetToken`  | Short-lived 6-digit reset codes                                    |

All entities use cuid IDs, `createdAt`/`updatedAt` audit timestamps, and soft-delete via `deletedAt`.

---

## Features

- **Auth** — Sign up, log in, JWT refresh, password reset via email
- **Dashboard** — Hero balance, budget progress bar, recent transactions
- **Add Expense** — Custom numpad, 6 built-in categories + custom categories, note input
- **Transactions** — Month navigator, grouped list (Today / Yesterday / date), income & expense summary
- **Analytics** — Donut chart + horizontal spending bars by category
- **Savings Goals** — Track progress toward goals, add funds, and an **AI time-to-reach estimate** (Google Gemini) with tips, shown in a draggable/expandable bottom sheet
- **Shared Expenses** — Split bills with contacts, share recurring costs, track who owes what, and record reimbursements
- **Recurring Income** — Manage monthly income sources
- **Recurring Expenses** — Manage weekly/bi-weekly/monthly expenses, confirm or postpone occurrences
- **Settings** — Appearance (light/dark theme), home-widget configuration
- **In-app OTA updates** — Checks GitHub Releases on cold start / app resume (throttled to once per 7 days)
- **Home screen widget** — Android quick-add widget

---

## CI/CD

GitHub Actions runs on every pull request to `develop`.

| Job          | Steps                                              |
| ------------ | -------------------------------------------------- |
| **backend**  | `npm ci` → `prisma generate` → lint → build → test |
| **frontend** | `flutter pub get` → analyze → test                 |

Concurrent runs for the same PR are automatically cancelled.

Releases are published by a separate workflow (`publish.yml`) triggered by pushing to the
`PUBLISH_V` branch: it deploys the backend to Render (when `backend/**` changed, after Prisma
migrations) and builds a signed APK attached to a GitHub Release, with the version/tag read from
`frontend/pubspec.yaml` (skipped if the tag already exists).

---

## Project phases

| Phase                 | Scope                                             | Status      |
| --------------------- | ------------------------------------------------- | ----------- |
| 01 — Foundations      | API bootstrap, Flutter shell, CI                  | Done        |
| 02 — Auth             | JWT auth, login/signup screens                    | Done        |
| 03 — Dashboard        | Summary API, hero balance, budget bar             | Done        |
| 04 — Add Expense      | `POST /transactions`, numpad UI                   | Done        |
| 05 — Transactions     | Month nav, grouped list, pagination               | Done        |
| 06 — Analytics        | Category breakdown API, donut chart               | Done        |
| 07 — Polish & release | Offline cache, error states, OTA updates, signing | Done        |
| 08 — Shared expenses  | Contacts, split bills, shares, reimbursements     | Done        |
| 09 — Savings goals    | Goals, add funds, AI time-to-reach estimate       | Done        |

Full plan details live in `plans/`.

---
