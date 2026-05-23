# Phase 07 — Polish & Release

Make it shippable. No new screens.

## Frontend polish

1. **Offline cache.** Cache `GET /me/summary`, `GET /transactions`, `GET /analytics` in Hive (or Isar) keyed by URL + query. On launch, hydrate from cache before the network call so the Dashboard never shows a blank hero. Stale-while-revalidate, not cache-or-network.
2. **Error states.** Every screen handles `AsyncValue.error` with a centered error tile + retry button. Distinguish network errors (offline icon, "You're offline") from server errors ("Something went wrong").
3. **Empty states.** First-run user sees onboarding card on Dashboard ("Tap + to add your first expense"). Transactions / Analytics empty months show the muted illustration described in their phases.
4. **Accessibility.**
   - Semantic labels on every icon-only button (back, filter, nav).
   - Min tap target 44×44.
   - Dynamic type up to 130% — test the Dashboard hero amount doesn't truncate.
   - Color contrast: re-check `inkLight` on `bg` (currently `#96A5BE` on `#EEF3FF` ≈ 3.0:1 — bump to `#7A8AAA` if AA matters for body text; keep `inkLight` only for ALL-CAPS labels which are exempt).
5. **Haptics.** Already in Phase 04; extend to nav switches and pull-to-refresh completion.
6. **Status bar.** Dark icons on light screens; light icons on Dashboard hero (already via the `light` flag in design).

## Backend polish

1. **Pagination headers.** Add `X-Total-Count` where reasonable, but keep cursor-based pagination on `/transactions`.
2. **Request IDs.** `pino-http` reqId echoed back as `X-Request-Id` for client-side error reports.
3. **Idempotency.** `POST /transactions` accepts `Idempotency-Key` header; cache `(userId, key) → response` for 24h. Stops double-saves on network retry.
4. **Backups.** Document `pg_dump` cron in `backend/README.md` for self-hosted setups.

## Quality gates

- **Tests.**
  - Backend: integration tests on auth, transactions CRUD, summary, analytics aggregation. Hit a real Postgres via testcontainers — no Prisma mocks.
  - Frontend: widget tests on `Numpad`, `DonutChart`, `BudgetCard`. One integration test covering the Add Expense → Dashboard refresh flow with `mock_dio`.
- **CI.** Block merge on lint + typecheck + tests for both folders.
- **Performance budget.** Cold start to interactive Dashboard ≤ 1.5 s on a Pixel 6.

## Release

1. **Store assets.** Generate iOS + Android icons and splash from a single source SVG (use `flutter_launcher_icons`, `flutter_native_splash`).
2. **Signing.** Android: keystore in 1Password, ref'd from `key.properties` (gitignored). iOS: manual signing via Apple Developer.
3. **Flavors.** `dev` / `staging` / `prod` with distinct `API_BASE_URL` and bundle IDs (`com.expensy.dev`, etc.).
4. **Crash reporting.** Sentry SDK on both platforms; symbolicate Dart stack traces via the Sentry CLI in CI.
5. **App Store / Play Store metadata.** Title, subtitle, screenshots (use the 4 design artboards as the basis), privacy policy URL.

## Exit criteria

- TestFlight + internal Play track builds installable from CI.
- Killing the app while offline and reopening → Dashboard renders from cache; reconnecting refreshes silently.
- Sentry receives a deliberately-thrown error from each platform.
