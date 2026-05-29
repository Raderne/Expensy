-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "recurringIncomeId" TEXT;

-- CreateTable
CREATE TABLE "RecurringIncome" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "dayOfMonth" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT,
    "updatedById" TEXT,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "RecurringIncome_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "RecurringIncome_userId_idx" ON "RecurringIncome"("userId");

-- CreateIndex
CREATE INDEX "RecurringIncome_deletedAt_idx" ON "RecurringIncome"("deletedAt");

-- CreateIndex
CREATE INDEX "Transaction_recurringIncomeId_occurredAt_idx" ON "Transaction"("recurringIncomeId", "occurredAt");

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_recurringIncomeId_fkey" FOREIGN KEY ("recurringIncomeId") REFERENCES "RecurringIncome"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringIncome" ADD CONSTRAINT "RecurringIncome_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
