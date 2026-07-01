import { Prisma } from '../lib/prismaTypes.js';
import { prisma } from '../lib/prisma.js';
import { logger } from '../lib/logger.js';
import { budgetRepository } from '../repositories/budgetRepository.js';
import { monthlyBudgetRepository } from '../repositories/monthlyBudgetRepository.js';
import { transactionRepository } from '../repositories/transactionRepository.js';

const monthString = (d: Date): string =>
  `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;

const monthBounds = (month: string): { from: Date; to: Date } => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  return { from: new Date(Date.UTC(year, m - 1, 1)), to: new Date(Date.UTC(year, m, 1)) };
};

const prevMonth = (month: string): string => {
  const sep = month.indexOf('-');
  const year = parseInt(month.slice(0, sep), 10);
  const m = parseInt(month.slice(sep + 1), 10);
  const d = new Date(Date.UTC(year, m - 2, 1)); // m-1 is this month; m-2 is previous
  return monthString(d);
};

/**
 * Closes the just-ended month for every user and opens the new one:
 *  1. Snapshots the previous month's recorded budget and its computed spend,
 *     marking it `closed` so any remainder becomes allocatable to goals.
 *  2. Carries the recurring template amount forward into the new current month
 *     (only if that month has no row yet, so a user-set amount isn't clobbered).
 *
 * Every write is idempotent, so re-runs and the SQL backfill can coexist.
 * [now] is injectable for manual runs/tests.
 */
export async function runBudgetRollover(now: Date = new Date()): Promise<void> {
  const current = monthString(now);
  const closing = prevMonth(current);
  const users = await prisma.user.findMany({ select: { id: true } });

  let closed = 0;
  for (const { id: userId } of users) {
    try {
      const [existing, template] = await Promise.all([
        monthlyBudgetRepository.findByUserMonth(userId, closing),
        budgetRepository.findByUser(userId),
      ]);
      const amount = existing?.amount ?? template?.amount ?? new Prisma.Decimal(0);

      const { from, to } = monthBounds(closing);
      const totals = await transactionRepository.summarize(userId, from, to);
      await monthlyBudgetRepository.upsertClose(
        userId,
        closing,
        amount,
        new Prisma.Decimal(totals.expenses),
      );

      if (template) {
        const currentRow = await monthlyBudgetRepository.findByUserMonth(userId, current);
        if (!currentRow) {
          await monthlyBudgetRepository.upsertAmount(userId, current, template.amount);
        }
      }
      closed += 1;
    } catch (err) {
      logger.error({ err, userId, closing }, 'budget rollover failed for user');
    }
  }

  logger.info({ closing, current, users: users.length, closed }, 'budget rollover complete');
}
