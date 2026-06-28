-- AlterTable
ALTER TABLE "Goal" ADD COLUMN     "aiEstimate" JSONB,
ADD COLUMN     "aiEstimatedAt" TIMESTAMP(3);
