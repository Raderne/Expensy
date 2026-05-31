# Expensy — Going-Live Resource Pack

You're shipping Expensy for personal use and maybe a few friends on Android. This folder is a curated set of guides for every step that was deferred during Phase 07, organized so you can read them in order or skip to the one you need right now.

## Recommended reading order

| # | File | Read when |
|---|---|---|
| 01 | `01-backend-free-hosting.md` | You want to put the backend somewhere reachable from a phone on cellular data. |
| 02 | `02-android-apk-sideload.md` | You want a `.apk` you can install on your phone or share with a friend. |
| 03 | `03-app-signing-keystore.md` | Before you build a release APK. Required by Android; can't skip. |
| 04 | `04-sentry-crash-reporting.md` | You want to know when the app crashes in the wild. |
| 05 | `05-flavors-dart-define.md` | You want separate `dev` / `staging` / `prod` builds with different app names and base URLs. |
| 06 | `06-ci-cd-github-actions.md` | You want lint + tests to gate every commit. |
| 07 | `07-integration-tests-testcontainers.md` | You want the backend tested against real Postgres in CI. |
| 08 | `08-play-store-release.md` | You ever decide to put it on the Play Store instead of sideloading. |

## TL;DR: the minimum path to "installed on my phone, talking to a real backend"

1. Sign up for **Neon** (free Postgres) and **Fly.io** (free-ish VM). [01]
2. Create a release keystore once. [03]
3. `flutter build apk --release --dart-define=API_BASE_URL=https://<your-fly-app>.fly.dev`. [02]
4. Transfer the APK to your phone, enable "install from unknown sources" for your file manager, tap it. [02]

That's the whole loop. Everything else in this folder is polish.

## Cost expectation (personal use, ≤ 10 users)

| Component | Provider | Monthly cost |
|---|---|---|
| Postgres database | Neon free tier (0.5 GB, no auto-sleep) | $0 |
| Backend API VM | Fly.io free allowance (3 shared-cpu-1x machines) | $0 |
| Domain (optional) | Cloudflare / Namecheap | $0–$12 / year |
| Crash reporting | Sentry free tier (5k errors / month) | $0 |
| CI minutes | GitHub Actions free tier (2,000 min / month for private repos) | $0 |
| Play Store account (optional) | Google | $25 one-time |

Realistic total for the sideload route: **$0**. With Play Store and a domain: **~$37** the first year, **$12** every year after.

## Repeated constraints (from `CLAUDE.md`, do not forget)

- `.env` is never committed. Provide a `.env.example` with placeholders instead.
- `API_BASE_URL` is passed via `--dart-define`, never hard-coded.
- Don't regenerate the Prisma client or run migrations against a shared DB without coordination — for hosted Postgres that means **always** running `prisma migrate deploy` (never `migrate dev`) from CI or your laptop, and never two of you at once.
- This is a Windows machine. Shell snippets here use PowerShell; if a snippet shows `bash` it's because it runs in CI on Linux.
- Commits stay scoped: `backend:`, `frontend:`, `plans:`, `resources:`.
