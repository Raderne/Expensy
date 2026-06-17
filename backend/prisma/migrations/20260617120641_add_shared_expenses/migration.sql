-- CreateEnum
CREATE TYPE "SplitStatus" AS ENUM ('OWED', 'PARTIAL', 'SETTLED');

-- CreateEnum
CREATE TYPE "ShareType" AS ENUM ('AMOUNT', 'PERCENT');

-- AlterTable
ALTER TABLE "Transaction" ADD COLUMN     "isReimbursement" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "sharedOwedTotal" DECIMAL(12,2) NOT NULL DEFAULT 0;

-- CreateTable
CREATE TABLE "Contact" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT,
    "updatedById" TEXT,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Contact_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TransactionSplit" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "transactionId" TEXT NOT NULL,
    "contactId" TEXT NOT NULL,
    "owedAmount" DECIMAL(12,2) NOT NULL,
    "settledAmount" DECIMAL(12,2) NOT NULL DEFAULT 0,
    "status" "SplitStatus" NOT NULL DEFAULT 'OWED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT,
    "updatedById" TEXT,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "TransactionSplit_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RecurringExpenseShare" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "recurringExpenseId" TEXT NOT NULL,
    "contactId" TEXT NOT NULL,
    "shareType" "ShareType" NOT NULL,
    "shareValue" DECIMAL(12,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT,
    "updatedById" TEXT,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "RecurringExpenseShare_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Reimbursement" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "splitId" TEXT NOT NULL,
    "contactId" TEXT NOT NULL,
    "amount" DECIMAL(12,2) NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL,
    "transactionId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "createdById" TEXT,
    "updatedById" TEXT,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Reimbursement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Contact_userId_idx" ON "Contact"("userId");

-- CreateIndex
CREATE INDEX "Contact_deletedAt_idx" ON "Contact"("deletedAt");

-- CreateIndex
CREATE INDEX "TransactionSplit_userId_contactId_status_idx" ON "TransactionSplit"("userId", "contactId", "status");

-- CreateIndex
CREATE INDEX "TransactionSplit_transactionId_idx" ON "TransactionSplit"("transactionId");

-- CreateIndex
CREATE INDEX "TransactionSplit_deletedAt_idx" ON "TransactionSplit"("deletedAt");

-- CreateIndex
CREATE INDEX "RecurringExpenseShare_recurringExpenseId_idx" ON "RecurringExpenseShare"("recurringExpenseId");

-- CreateIndex
CREATE INDEX "RecurringExpenseShare_userId_idx" ON "RecurringExpenseShare"("userId");

-- CreateIndex
CREATE INDEX "RecurringExpenseShare_deletedAt_idx" ON "RecurringExpenseShare"("deletedAt");

-- CreateIndex
CREATE UNIQUE INDEX "Reimbursement_transactionId_key" ON "Reimbursement"("transactionId");

-- CreateIndex
CREATE INDEX "Reimbursement_userId_idx" ON "Reimbursement"("userId");

-- CreateIndex
CREATE INDEX "Reimbursement_splitId_idx" ON "Reimbursement"("splitId");

-- CreateIndex
CREATE INDEX "Reimbursement_deletedAt_idx" ON "Reimbursement"("deletedAt");

-- CreateIndex
CREATE INDEX "Transaction_userId_isReimbursement_idx" ON "Transaction"("userId", "isReimbursement");

-- AddForeignKey
ALTER TABLE "Contact" ADD CONSTRAINT "Contact_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TransactionSplit" ADD CONSTRAINT "TransactionSplit_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TransactionSplit" ADD CONSTRAINT "TransactionSplit_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "Transaction"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TransactionSplit" ADD CONSTRAINT "TransactionSplit_contactId_fkey" FOREIGN KEY ("contactId") REFERENCES "Contact"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringExpenseShare" ADD CONSTRAINT "RecurringExpenseShare_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringExpenseShare" ADD CONSTRAINT "RecurringExpenseShare_recurringExpenseId_fkey" FOREIGN KEY ("recurringExpenseId") REFERENCES "RecurringExpense"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RecurringExpenseShare" ADD CONSTRAINT "RecurringExpenseShare_contactId_fkey" FOREIGN KEY ("contactId") REFERENCES "Contact"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reimbursement" ADD CONSTRAINT "Reimbursement_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reimbursement" ADD CONSTRAINT "Reimbursement_splitId_fkey" FOREIGN KEY ("splitId") REFERENCES "TransactionSplit"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reimbursement" ADD CONSTRAINT "Reimbursement_contactId_fkey" FOREIGN KEY ("contactId") REFERENCES "Contact"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Reimbursement" ADD CONSTRAINT "Reimbursement_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "Transaction"("id") ON DELETE SET NULL ON UPDATE CASCADE;
