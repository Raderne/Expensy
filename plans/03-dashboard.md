# Phase 03 — Dashboard

Build Screen 01 end-to-end. Requires Phases 01–02. Categories table is created here (used by every later phase).

## Design references

`design/Expensy.html` lines 178–240 (`DashboardScreen`). Components:
- Blue hero gradient header with greeting + avatar pill + glass balance card (Total Balance / Income / Expenses).
- Monthly Budget card with a blue→orange gradient progress bar and "X% used".
- "Recent Transactions" header with "See all →".
- 4 transaction rows via `TxRow`.
- Bottom nav, `home` active.

## Backend

### Schema additions

```prisma
model Category {
  id     String  @id @default(cuid())
  key    String  @unique           // food, travel, shop, health, fun, home
  label  String                    // "Food", "Travel", ...
  abbr   String                    // "FD", "TR", ...
  color  String                    // "#F56B1E"
  bgTint String                    // "#FEF0E8"
  sort   Int
  isSystem Boolean @default(true)
}

model Transaction {
  id          String   @id @default(cuid())
  userId      String
  categoryId  String
  // positive = income, negative = expense (keeps the design's mental model)
  amount      Decimal  @db.Decimal(12, 2)
  note        String?
  occurredAt  DateTime
  createdAt   DateTime @default(now())
  user        User     @relation(fields: [userId], references: [id])
  category    Category @relation(fields: [categoryId], references: [id])
  @@index([userId, occurredAt])
}

model Budget {
  id     String   @id @default(cuid())
  userId String   @unique           // v1: one rolling monthly budget per user
  amount Decimal  @db.Decimal(12, 2)
  user   User     @relation(fields: [userId], references: [id])
}
```

### Seed

Seed the six categories from the design (`design/Expensy.html` lines 64–71) on every `prisma migrate deploy`.

### Endpoints

- `GET /categories` → all seeded categories.
- `GET /me/summary?month=YYYY-MM` → `{ balance, income, expenses, budget: { amount, spent, pct } }`. Defaults to current month.
- `GET /transactions/recent?limit=4` → newest 4 transactions for the user, joined with category.
- `PUT /me/budget` → `{ amount }` (used later in settings; expose now so the field exists).

`balance` for v1 is the lifetime sum of all transactions. Income/expenses are filtered by `month` and split on `amount` sign.

## Frontend

1. `features/dashboard/data/dashboard_repository.dart` — calls the three GET endpoints in parallel.
2. `features/dashboard/application/dashboard_controller.dart` — `AsyncNotifier<DashboardState>`. Refresh on pull-to-refresh and on bottom-nav re-tap.
3. `features/dashboard/presentation/dashboard_screen.dart` — port HTML 1:1:
   - `HeroGradient` (built in Phase 01) wraps StatusBar, greeting, avatar pill, and the glass `BalanceCard`.
   - `BudgetCard` widget with custom-painted gradient progress (use `LinearGradient` inside a clipped `Container`, not `LinearProgressIndicator` — the gradient is blue→orange).
   - `RecentTransactionsList` reuses `TxRow`.
4. Skeleton loader while `AsyncValue.loading`. Empty state for new users: "Add your first expense" CTA jumps to `/add`.
5. Currency formatting via `intl` `NumberFormat.simpleCurrency(locale: 'en_US')`.

## Exit criteria

- Logged-in user with one seeded transaction sees real numbers in the hero, real budget pct, and the row in the list.
- Pixel diff vs `design/Expensy.html` Dashboard artboard at 390 logical width passes a visual review.
- Tapping "See all →" navigates to the (still empty) Transactions tab.
