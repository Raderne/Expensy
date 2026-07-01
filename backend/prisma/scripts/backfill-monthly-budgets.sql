-- Backfill MonthlyBudget rows for historical data.
--
-- Purpose: before per-month budget recording existed, only a single mutable
-- Budget.amount was kept per user. This script creates one MonthlyBudget row
-- for every (user, month) that has transactions, so past months carry a real
-- record of what was budgeted vs. spent and no longer show a mismatch.
--
--   * amount     -> the user's current Budget.amount (best available proxy for a
--                   month whose budget was never recorded), 0 if none.
--   * spent      -> that month's expenses, user's share only, matching
--                   transactionRepository.summarize:
--                   -SUM(amount + sharedOwedTotal) where amount < 0.
--   * closed     -> true for months before the current calendar month (UTC).
--   * allocated  -> 0 (nothing moved into goals yet).
--
-- Idempotent: ON CONFLICT DO NOTHING means existing rows (e.g. the current
-- month created lazily, or by the rollover job) are left untouched, so this can
-- be run repeatedly and alongside the cron.
--
-- Run once, coordinated (this writes to the shared DB). Options:
--   npx prisma db execute --file prisma/scripts/backfill-monthly-budgets.sql --schema prisma/schema.prisma
--   -- or --
--   psql "$DATABASE_URL" -f prisma/scripts/backfill-monthly-budgets.sql

INSERT INTO "MonthlyBudget"
  ("id", "userId", "month", "amount", "spent", "allocated", "closed", "createdAt", "updatedAt")
SELECT
  gen_random_uuid()::text                                            AS "id",
  m."userId"                                                         AS "userId",
  m."month"                                                          AS "month",
  COALESCE(b."amount", 0)                                            AS "amount",
  m."spent"                                                          AS "spent",
  0                                                                  AS "allocated",
  m."month" < to_char(date_trunc('month', now() AT TIME ZONE 'UTC'), 'YYYY-MM') AS "closed",
  now()                                                              AS "createdAt",
  now()                                                              AS "updatedAt"
FROM (
  SELECT
    t."userId"                                                       AS "userId",
    to_char(date_trunc('month', t."occurredAt"), 'YYYY-MM')         AS "month",
    COALESCE(-SUM(t."amount" + t."sharedOwedTotal")
               FILTER (WHERE t."amount" < 0), 0)                      AS "spent"
  FROM "Transaction" t
  WHERE t."deletedAt" IS NULL
  GROUP BY 1, 2
) m
LEFT JOIN "Budget" b
  ON b."userId" = m."userId" AND b."deletedAt" IS NULL
ON CONFLICT ("userId", "month") DO NOTHING;
