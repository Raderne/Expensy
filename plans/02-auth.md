# Phase 02 — Authentication

The design shows a personalized "Good morning, Alex Chen" greeting on the Dashboard; that profile must come from a real authenticated session. This phase delivers signup/login (no OAuth, no email verification in v1) and the Flutter login flow.

> The design has no login screens explicitly. Build minimal, on-brand screens that reuse Phase 01 tokens — split into `LoginScreen` and `SignupScreen`, single-column, hero gradient header, white card form. Match button styles to the Save Expense CTA (orange, radius 16, 700 weight).

## Backend

### Schema (Prisma)

```prisma
model User {
  id           String   @id @default(cuid())
  email        String   @unique
  passwordHash String
  name         String
  createdAt    DateTime @default(now())
  transactions Transaction[]
  budgets      Budget[]
}
```

### Endpoints

- `POST /auth/signup` — `{email, password, name}` → `{accessToken, refreshToken, user}`. Zod-validated; password ≥ 8 chars.
- `POST /auth/login` — `{email, password}` → tokens + user.
- `POST /auth/refresh` — `{refreshToken}` → new access token.
- `GET /me` — returns the current user (requires bearer).

### Implementation

1. `bcrypt` for hashing (cost 12).
2. `jsonwebtoken` — access TTL 15m, refresh TTL 30d. Sign with separate secrets from env.
3. `requireAuth` middleware validates access tokens and attaches `req.user`.
4. Rate-limit `/auth/login` (5 attempts / 15 min / IP) using `express-rate-limit`.

## Frontend

1. `features/auth/data/auth_repository.dart` — wraps the four endpoints.
2. `features/auth/application/auth_controller.dart` — Riverpod `AsyncNotifier<AuthState>`; persists tokens via `flutter_secure_storage` under keys `auth.access` / `auth.refresh`.
3. Dio interceptor (filled from Phase 01 stub):
   - Adds `Authorization: Bearer <access>` to every request when token present.
   - On 401, calls `/auth/refresh` once. On refresh failure, clears storage and redirects to `/login`.
4. `features/auth/presentation/login_screen.dart` and `signup_screen.dart`. Email + password inputs use `OutlineInputBorder` with `border` color and 12 radius (match the Note field in Add Expense).
5. `app/router.dart` — gate authed routes. Unauthenticated users land on `/login`; on success, `go('/')`.
6. Store `user.name` in auth state so the Dashboard greeting works in Phase 03 without an extra request.

## Exit criteria

- New user can sign up, gets navigated to the empty Dashboard shell, sees their name in the greeting placeholder.
- Killing the app and reopening keeps the user signed in.
- Tampering with `auth.access` triggers refresh; tampering with `auth.refresh` bounces to login.
