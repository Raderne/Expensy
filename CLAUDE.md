# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Expensy** is a personal expense tracking application built as a mobile-first product.

The repository is split into four top-level folders. Each owns a distinct concern; do not mix code across boundaries.

| Folder      | Purpose                                                                                  |
| ----------- | ---------------------------------------------------------------------------------------- |
| `backend/`  | Node.js REST API (Express/Fastify + Prisma + PostgreSQL). Source of truth for data.      |
| `frontend/` | Flutter mobile app (iOS + Android). Consumes `backend/` over HTTPS.                      |
| `design/`   | Static design artifacts (HTML mockups, README, screen inventory). Read-only reference.   |
| `plans/`    | Phased implementation plans (markdown). Update as scope evolves.                         |

## Tech Stack

### Backend (`backend/`)
- **Runtime**: Node.js 20 LTS
- **Language**: TypeScript (strict mode)
- **Framework**: Express (or Fastify — decide in plans/phase-01)
- **ORM**: Prisma
- **Database**: PostgreSQL 16
- **Auth**: JWT (access + refresh), bcrypt for password hashing
- **Validation**: Zod
- **Logging**: Pino (structured JSON)
- **Testing**: Vitest + Supertest
- **Lint/format**: ESLint + Prettier

### Frontend (`frontend/`)
- **Framework**: Flutter 3.x (stable channel), Dart 3.x
- **State management**: Riverpod
- **Routing**: go_router
- **HTTP**: dio with interceptors for auth + retry
- **Local storage**: flutter_secure_storage (tokens), Hive or Isar (offline cache)
- **Forms**: reactive_forms or flutter_form_builder
- **Testing**: flutter_test + integration_test + mocktail

## Commands

### Backend

Run from `backend/`:

```bash
npm install
npm run dev               # nodemon/tsx watch — http://localhost:3000
npm run build             # tsc → dist/
npm run start             # node dist/index.js
npm run lint              # eslint . --ext .ts
npm run test              # vitest run
npm run test:watch        # vitest

# Prisma
npx prisma migrate dev --name <migration_name>
npx prisma migrate deploy
npx prisma generate
npx prisma studio
```

### Frontend

Run from `frontend/`:

```bash
flutter pub get
flutter run                              # device/emulator
flutter run -d chrome                    # web preview (if enabled)
flutter build apk --release
flutter build ios --release
flutter test
flutter analyze
dart format .
```

## Configuration

### Backend env (`backend/.env`)

```
DATABASE_URL=postgresql://user:pass@localhost:5432/expensy
JWT_ACCESS_SECRET=<32+ chars>
JWT_REFRESH_SECRET=<32+ chars>
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=30d
PORT=3000
LOG_LEVEL=info
CORS_ORIGINS=http://localhost:5173
```

Never commit `.env`. Provide `.env.example` with placeholder values.

### Frontend env (`frontend/lib/config/`)

Use `--dart-define` for `API_BASE_URL` and environment flavor (`dev`, `staging`, `prod`). Never hard-code base URLs.

## Architecture Conventions

### Backend layering

```
src/
  routes/            HTTP routes — thin, delegate to controllers
  controllers/       Request/response shaping, call services
  services/          Business logic, orchestration
  repositories/      Prisma queries, no HTTP concerns
  domain/            Pure types, value objects, enums
  middleware/        auth, error handler, request logger
  schemas/           Zod request/response schemas
  lib/               JWT, hashing, mailer, etc.
  config/            env parsing (zod-validated)
prisma/
  schema.prisma
  migrations/
tests/
```

- Controllers never touch Prisma. Services never touch `req`/`res`.
- Every route validates input with a Zod schema before reaching the controller.
- All errors flow through one error-handler middleware; never return raw Prisma errors.

### Frontend layering

```
lib/
  app/               app entry, theme, router
  features/<name>/   feature folder: presentation/, application/, data/, domain/
  core/              shared widgets, utils, extensions
  config/            env, constants
  l10n/              localization
test/
integration_test/
```

- Follow feature-first organization. Shared widgets live in `core/`; never reach across features.
- One Riverpod provider file per use case. Avoid global mutable state.
- API client lives in `core/network/`; features depend on repository interfaces, not on `dio` directly.

## Domain Model (initial)

Core entities: `User`, `Wallet`, `Category`, `Transaction`, `Budget`, `BudgetAlert`, `SavingsGoal`, `Milestone`, `Subscription`, `Notification`.

Refine in `plans/` once the design is reviewed; reflect the final shape in `backend/prisma/schema.prisma`.

## Platform

This project runs on **Windows**. When suggesting or running shell commands:
- Use PowerShell syntax (`$env:VAR`, backtick for line continuation, `;` to chain commands)
- Do not use bash-only syntax (`export`, `&&` chains, `2>/dev/null`, etc.)
- Use Windows path separators (`\`) in file paths when relevant
- Prefer the PowerShell tool over the Bash tool for all terminal operations

## Working in this repo

- Keep `plans/` in sync with what's actually being built. When a phase changes scope, edit the plan file rather than letting it drift.
- The `design/` folder is the visual source of truth — match Flutter screens to it. If the design and code disagree, raise it before changing either.
- Commits should be small and scoped to one folder when possible (`backend:` / `frontend:` / `plans:` / `design:` prefix).
- Do not regenerate the Prisma client or run migrations against a shared DB without coordination.
