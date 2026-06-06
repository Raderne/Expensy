-- CreateEnum
CREATE TYPE "OccurrenceStatus" AS ENUM ('PENDING', 'CONFIRMED', 'POSTPONED');

-- CreateTable
CREATE TABLE "RecurringOccurrence" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "recurringIncomeId" TEXT,
    "recurringExpenseId" TEXT,
    "scheduledFor" TIMESTAMP(3) NOT NULL,
    "dueAt" TIMESTAMP(3) NOT NULL,
    "status" "OccurrenceStatus" NOT NULL DEFAULT 'PENDING',
    "amount" DECIMAL(12,2) NOT NULL,
    "label" TEXT NOT NULL,
    "transactionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT,
    "updatedById" TEXT,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "RecurringOccurrence_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "RecurringOccurrence_transactionId_key" ON "RecurringOccurrence"("transactionId");

-- CreateIndex
CREATE UNIQUE INDEX "RecurringOccurrence_recurringIncomeId_scheduledFor_key" ON "RecurringOccurrence"("recurringIncomeId", "scheduledFor");

-- CreateIndex
CREATE UNIQUE INDEX "RecurringOccurrence_recurringExpenseId_scheduledFor_key" ON "RecurringOccurrence"("recurringExpenseId", "scheduledFor");

-- CreateIndex
CREATE INDEX "RecurringOccurrence_userId_status_dueAt_idx" ON "RecurringOccurrence"("userId", "status", "dueAt");

-- CreateIndex
CREATE INDEX "RecurringOccurrence_deletedAt_idx" ON "RecurringOccurrence"("deletedAt");

-- AddForeignKey
ALTER TABLE "RecurringOccurrence" ADD CONSTRAINT "RecurringOccurrence_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringOccurrence" ADD CONSTRAINT "RecurringOccurrence_recurringIncomeId_fkey" FOREIGN KEY ("recurringIncomeId") REFERENCES "RecurringIncome"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringOccurrence" ADD CONSTRAINT "RecurringOccurrence_recurringExpenseId_fkey" FOREIGN KEY ("recurringExpenseId") REFERENCES "RecurringExpense"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringOccurrence" ADD CONSTRAINT "RecurringOccurrence_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "Transaction"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- =============================================================================
-- Data backfill
--
-- Every Transaction that was auto-materialized from a recurring rule (i.e. has
-- a non-null recurringIncomeId/recurringExpenseId) predates the confirm/postpone
-- flow and is, by definition, already "confirmed money". Create a CONFIRMED
-- occurrence for each so users are never re-prompted for historical charges.
--
-- amount is the positive rule snapshot (transactions store expenses as negative),
-- hence ABS(). scheduledFor = dueAt = occurredAt (its original schedule day).
-- =============================================================================
INSERT INTO "RecurringOccurrence" (
    "id", "userId", "recurringIncomeId", "recurringExpenseId",
    "scheduledFor", "dueAt", "status", "amount", "label", "transactionId",
    "createdAt", "updatedAt"
)
SELECT
    gen_random_uuid()::text,
    t."userId",
    t."recurringIncomeId",
    t."recurringExpenseId",
    t."occurredAt",
    t."occurredAt",
    'CONFIRMED'::"OccurrenceStatus",
    ABS(t."amount"),
    COALESCE(t."note", ''),
    t."id",
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
FROM "Transaction" t
WHERE t."deletedAt" IS NULL
  AND (t."recurringIncomeId" IS NOT NULL OR t."recurringExpenseId" IS NOT NULL);
