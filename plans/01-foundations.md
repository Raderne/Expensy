# Phase 01 — Foundations

Bootstrap both apps and lock the design tokens. End of phase: backend serves `/health`, Flutter app boots into an empty themed shell with the bottom nav.

## Backend (`backend/`)

1. `npm init -y`, add TypeScript strict, ESLint, Prettier, Vitest, tsx.
2. Express (or Fastify — pick now, document choice in `backend/README.md`). Add helmet, cors, pino-http.
3. `src/config/env.ts` — Zod-validated env loader. Required vars listed in root `CLAUDE.md`. Provide `.env.example`.
4. `src/index.ts` boots the server, registers `/health` (returns `{status, db}`), and a central error handler that maps `ZodError`, `PrismaClientKnownRequestError`, and `AppError` to RFC7807 problem responses.
5. Prisma init against PostgreSQL. Empty schema except for a placeholder `HealthCheck` model used by the health endpoint, or use `prisma.$queryRaw\`SELECT 1\``.
6. `docker-compose.yml` at repo root with a `postgres:16` service.
7. GitHub Actions: lint + typecheck + test on push.

## Frontend (`frontend/`)

1. `flutter create .` (org id `com.expensy`). Remove sample counter app.
2. Add deps: `flutter_riverpod`, `go_router`, `dio`, `flutter_secure_storage`, `freezed`/`json_serializable`, `google_fonts` (DM Sans), `flutter_svg`.
3. `lib/core/theme/` — translate the design palette into `AppColors` and `AppTextStyles`. Token mapping:
   - `primary` `#1B45D0`, `primaryDark` `#0C228E`, `primaryLight` `#E8EFFE`
   - `accent` `#F56B1E`, `accentLight` `#FEF0E8`
   - `success` `#16A34A`, `danger` `#DC2626`
   - `background` `#EEF3FF`, `surface` `#FFFFFF`, `border` `#DDE6FF`
   - `ink` `#0C1530`, `inkMid` `#4A5675`, `inkLight` `#96A5BE`, `inkFaint` `#D5DDF0`
   - Category palette: orange, blue, purple, green, pink, teal + matching `*Light` tints.
4. `lib/core/widgets/` — port the four reused HTML components: `StatusBar`, `TxRow`, `BottomNav`, `HeroGradient`. Build them now even though screens are empty; later phases consume them.
5. `lib/app/router.dart` — `go_router` with 4 routes: `/`, `/add`, `/transactions`, `/analytics`. Each renders an empty `Scaffold` with `BottomNav` highlighted correctly.
6. `lib/core/network/dio.dart` — Dio instance reading `API_BASE_URL` from `--dart-define`. Empty auth interceptor stub (filled in Phase 02).

## Exit criteria

- `docker compose up -d` then `npm run dev` in `backend/` → `curl localhost:3000/health` returns `200`.
- `flutter run` in `frontend/` opens the empty shell, bottom nav switches between four blank screens, colors and DM Sans match the design.
- CI green on a PR that touches both folders.
